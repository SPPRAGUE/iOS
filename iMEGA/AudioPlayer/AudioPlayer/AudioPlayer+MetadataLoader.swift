@preconcurrency import AVFoundation
import Foundation

enum MetadataLoadError: Error {
    case cancelled
}

// MARK: - Audio Player Metadata Functions
extension AudioPlayer {

    func preloadNextTracksMetadata() {
        let itemsToBePreloaded = tracks.filter { !$0.loadedMetadata }
        let completion: @MainActor @Sendable (AudioPlayerItem) -> Void = { [weak self] item in
            self?.notifyMetadataLoaded(for: item)
        }
        
        preloadMetadataTask?.cancel()
        preloadMetadataTask = Task {
            await itemsToBePreloaded.taskGroup(maxConcurrentTasks: 3) {
                do {
                    try await $0.loadMetadata()
                    await completion($0)
                } catch {
                    MEGALogError("[AudioPlayer] Metadata Loader error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func notifyMetadataLoaded(for item: AudioPlayerItem) {
        if queuePlayer?.currentItem == item {
            notify([aboutCurrentItem, aboutCurrentThumbnail, aboutToReloadCurrentItem])
        }
        notifyAboutToReload(item: item)
    }
    
    func loadACurrentItemArtworkIfNeeded() async {
        guard let currentItem = currentItem(), currentItem.artwork == nil else { return }
        let asset = currentItem.asset
        
        guard let metadata = try? await asset.load(.commonMetadata) else { return }
        let artworkMetadata = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierArtwork)
        
        guard
            let firstArtwork = artworkMetadata.first,
            let imageData = try? await firstArtwork.load(.dataValue),
            let image = UIImage(data: imageData) else {
            return
        }
        
        self.currentItem()?.artwork = image
    }
}
