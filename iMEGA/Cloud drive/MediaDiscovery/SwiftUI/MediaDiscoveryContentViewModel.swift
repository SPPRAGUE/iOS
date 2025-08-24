import Combine
import ContentLibraries
import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAFoundation
import MEGAPreference
import SwiftUI

protocol MediaDiscoveryContentDelegate: AnyObject {
    
    /// This delegate function will be triggered when a change to the currently selected media nodes for this media discovery list  occurs.
    /// When a selection change occurs, this delegate will return the current selected node entities and the a list of all the node entities.
    /// - Parameters:
    ///   - selected: returns currently selected [NodeEntities]
    ///   - allPhotos: returns list of all nodes loaded in this feature
    func selectedPhotos(selected: [NodeEntity], allPhotos: [NodeEntity])
    
    /// This delegate function will get triggered when the ability to enter edit mode/ to be able to select nodes in Media Discovery changes.
    ///  Follow this trigger, to determine the availability to enter multi-select/edit mode.
    ///  This event should be triggered if either zoomLevelChange affects its ability to select or selectedMode has changed.
    /// - Parameter isHidden: Bool value to determine if selection action should be hidden
    func isMediaDiscoverySelection(isHidden: Bool)
    
    /// This delegate function triggered only when in the Empty State of the view. And when a menu action has been triggered.
    /// This is called immediately on tapping of menu action
    /// - Parameter menuAction: The tapped menu action
    func mediaDiscoverEmptyTapped(menuAction: EmptyMediaDiscoveryContentMenuAction)
}

enum MediaDiscoveryContentViewState {
    case normal
    case empty
}

@MainActor
final class MediaDiscoveryContentViewModel: ObservableObject {
    @Published var showAutoMediaDiscoveryBanner = false
    @Published private(set) var viewState: MediaDiscoveryContentViewState = .normal
    let photoLibraryContentViewModel: PhotoLibraryContentViewModel
    let photoLibraryContentViewRouter: PhotoLibraryContentViewRouter
    
    var editMode: EditMode {
        get { photoLibraryContentViewModel.selection.editMode }
        set { photoLibraryContentViewModel.selection.editMode = newValue }
    }
    
    @PreferenceWrapper(key: PreferenceKeyEntity.autoMediaDiscoveryBannerDismissed, defaultValue: false)
    var autoMediaDiscoveryBannerDismissed: Bool

    private(set) var sortOrder: SortOrderType

    private let parentNodeProvider: () -> NodeEntity?
    private let analyticsUseCase: any MediaDiscoveryAnalyticsUseCaseProtocol
    private let mediaDiscoveryUseCase: any MediaDiscoveryUseCaseProtocol
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    private lazy var pageStayTimeTracker = PageStayTimeTracker()
    private var subscriptions = Set<AnyCancellable>()
    private weak var delegate: (any MediaDiscoveryContentDelegate)?
    @PreferenceWrapper(key: PreferenceKeyEntity.mediaDiscoveryShouldIncludeSubfolderMedia, defaultValue: true)
    private var shouldIncludeSubfolderMedia: Bool
    private var monitorNodeUpdatesTask: Task<Void, Never>?
    
    init(contentMode: PhotoLibraryContentMode,
         parentNodeProvider: @escaping () -> NodeEntity?,
         sortOrder: SortOrderType,
         isAutomaticallyShown: Bool,
         delegate: (some MediaDiscoveryContentDelegate)?,
         analyticsUseCase: some MediaDiscoveryAnalyticsUseCaseProtocol,
         mediaDiscoveryUseCase: some MediaDiscoveryUseCaseProtocol,
         sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
         preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default) {
        
        photoLibraryContentViewModel = PhotoLibraryContentViewModel(library: PhotoLibrary(), contentMode: contentMode)
        photoLibraryContentViewRouter = PhotoLibraryContentViewRouter(contentMode: contentMode)
        
        self.parentNodeProvider = parentNodeProvider
        self.delegate = delegate
        self.analyticsUseCase = analyticsUseCase
        self.mediaDiscoveryUseCase = mediaDiscoveryUseCase
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.sortOrder = sortOrder
        $shouldIncludeSubfolderMedia.useCase = preferenceUseCase
        $autoMediaDiscoveryBannerDismissed.useCase = preferenceUseCase
        
        if isAutomaticallyShown {
            showAutoMediaDiscoveryBanner = !autoMediaDiscoveryBannerDismissed
        }
    }
    
    func loadPhotos() async {
        guard let parentNode = parentNodeProvider() else {
            viewState = .empty
            return
        }
        do {
            viewState = .normal
            try Task.checkCancellation()
            let shouldExcludeSensitiveItems = await shouldExcludeSensitiveItems()
            MEGALogDebug("[Search] load photos and videos in parent: \(parentNode.base64Handle), recursive: \(shouldIncludeSubfolderMedia), exclude sensitive \(shouldExcludeSensitiveItems)")
            let nodes = try await mediaDiscoveryUseCase.nodes(
                forParent: parentNode,
                recursive: shouldIncludeSubfolderMedia,
                excludeSensitive: shouldExcludeSensitiveItems)
            try Task.checkCancellation()
            MEGALogDebug("[Search] nodes loaded \(nodes.count)")
            photoLibraryContentViewModel.library = await sortIntoPhotoLibrary(nodes: nodes, sortOrder: sortOrder)
            try Task.checkCancellation()
            viewState = nodes.isEmpty ? .empty : .normal
        } catch {
            MEGALogError("[Search] Error loading nodes: \(error.localizedDescription)")
        }
    }
        
    func update(sortOrder updatedSortOrder: SortOrderType) async {
        guard updatedSortOrder != sortOrder else {
            return
        }
        
        self.sortOrder = updatedSortOrder
        let nodes = photoLibraryContentViewModel.library.allPhotos
        photoLibraryContentViewModel.library = await sortIntoPhotoLibrary(nodes: nodes, sortOrder: sortOrder)
    }
    
    func onViewAppear() {
        subscribeToSelectionChanges()
        startMonitoringNodeUpdates()
        startTracking()
        analyticsUseCase.sendPageVisitedStats()
    }
    
    func onViewDisappear() {
        // AnyCancellable are cancelled on dealloc so need to do it here
        subscriptions.removeAll()
        stopMonitoringNodeUpdates()
        endTracking()
        sendPageStayStats()
    }
    
    func toggleAllSelected() {
        photoLibraryContentViewModel.toggleSelectAllPhotos()
    }
    
    func tapped(menuAction: EmptyMediaDiscoveryContentMenuAction) {
        delegate?.mediaDiscoverEmptyTapped(menuAction: menuAction)
    }
    
    private func sortIntoPhotoLibrary(nodes: [NodeEntity], sortOrder: SortOrderType) async -> PhotoLibrary {
        nodes.toPhotoLibrary(withSortType: sortOrder.toSortOrderEntity())
    }
    
    private func startTracking() {
        pageStayTimeTracker.start()
    }
    
    private func endTracking() {
        pageStayTimeTracker.end()
    }
    
    private func sendPageStayStats() {
        let duration = Int(pageStayTimeTracker.duration)
        analyticsUseCase.sendPageStayStats(with: duration)
    }
    
    private func subscribeToSelectionChanges() {
        
        photoLibraryContentViewModel
            .$library
            .map(\.allPhotos)
            .combineLatest(photoLibraryContentViewModel.selection.$photos)
            .receive(on: DispatchQueue.main)
            .sink { [weak delegate] allPhotos, selectedPhotos in
                delegate?.selectedPhotos(selected: selectedPhotos.map(\.value), allPhotos: allPhotos)
            }
            .store(in: &subscriptions)
        
        photoLibraryContentViewModel.$selectedMode
            .combineLatest(photoLibraryContentViewModel.selection.$isHidden)
            .map { selectedMode, selectionIsHidden -> Bool in
                selectedMode != .all || selectionIsHidden
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak delegate] in delegate?.isMediaDiscoverySelection(isHidden: $0) }
            .store(in: &subscriptions)
    }
    
    private func startMonitoringNodeUpdates() {
        monitorNodeUpdatesTask = Task { [weak self, mediaDiscoveryUseCase] in
            for await nodes in mediaDiscoveryUseCase.nodeUpdates.debounce(for: .seconds(0.35)) {
                guard !Task.isCancelled else { break }
                await self?.handleNodeChanges(nodes)
            }
        }
    }
    
    private func stopMonitoringNodeUpdates() {
        monitorNodeUpdatesTask?.cancel()
    }
    
    func handleNodeChanges(_ updatedNodes: [NodeEntity]) async {
        let nodes = photoLibraryContentViewModel.library.allPhotos
        
        guard
            let parentNode = parentNodeProvider(),
            mediaDiscoveryUseCase.shouldReload(
                parentNode: parentNode,
                loadedNodes: nodes,
                updatedNodes: updatedNodes
            )
        else {
            return
        }
        
        await self.loadPhotos()
    }
    
    private func shouldExcludeSensitiveItems() async -> Bool {
        if [.mediaDiscovery, .mediaDiscoverySharedItems]
            .contains(photoLibraryContentViewModel.contentMode) {
            await sensitiveDisplayPreferenceUseCase.excludeSensitives()
        } else {
            false
        }
    }
}
