import MEGADomain
import MEGASdk

public struct TransferInventoryRepository: TransferInventoryRepositoryProtocol {
    public static var newRepo: TransferInventoryRepository {
        TransferInventoryRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    private let queue = DispatchQueue(label: "nz.mega.MEGASDKRepo.TransferInventoryRepository")
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    public func transfers() -> [TransferEntity] {
        sdk.transfers.toTransferEntities()
    }
    
    public func transfers() async -> [TransferEntity] {
        await withCheckedContinuation { continuation in
            getTransfers { continuation.resume(returning: $0) }
        }
    }

    public func downloadTransfers() -> [TransferEntity] {
        sdk.downloadTransfers.toTransferEntities()
    }

    public func uploadTransfers() -> [TransferEntity] {
        sdk.uploadTransfers.toTransferEntities()
    }

    public func completedTransfers() -> [TransferEntity] {
        guard let completedTransfers = sdk.completedTransfers as? [MEGATransfer] else {
            return []
        }
        return completedTransfers.map { $0.toTransferEntity() }
    }

    public func isExportFileTransfer(_ transfer: TransferEntity) -> Bool {
        transfer.appData?.contains(TransferMetaDataEntity.exportFile.rawValue) ?? false
    }

    public func isSaveToPhotosAppTransfer(_ transfer: TransferEntity) -> Bool {
        transfer.appData?.contains(TransferMetaDataEntity.saveInPhotos.rawValue) ?? false
    }
    
    public func areThereAnyTransferWithAppData(matching filter: @escaping (String) -> Bool) -> Bool {
        sdk.areThereAnyTransferWithAppData(matching: filter)
    }
    
    private func getTransfers(completion: @Sendable @escaping ([TransferEntity]) -> Void) {
        queue.async {
            completion(sdk.transfers.toTransferEntities())
        }
    }
}
