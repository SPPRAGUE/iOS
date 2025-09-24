import MEGADomain
import MEGASdk
import MEGASwift

final class MEGAUpdateHandlerManager: NSObject, MEGADelegate, @unchecked Sendable {
    @Atomic
    private var handlers: [MEGAUpdateHandler] = []
    private let sdk: MEGASdk
    private let sdkDelegateQueue = DispatchQueue(label: "nz.mega.MEGASDKRepo.MEGAUpdateHandlerManager.delegateQueue")
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
        super.init()
        sdkDelegateQueue.async {
            sdk.add(self)
        }
    }
    
    deinit {
        sdk.remove(self)
    }
    
    static let shared = MEGAUpdateHandlerManager(sdk: .sharedSdk)
    static let sharedFolderLink = MEGAUpdateHandlerManager(sdk: .sharedFolderLinkSdk)
    
    // MARK: - Global events
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard let nodeEntities = nodeList?.toNodeEntities() else { return }

        handlers.forEach { $0.onNodesUpdate?(nodeEntities) }
    }
    
    func onUsersUpdate(_ api: MEGASdk, userList: MEGAUserList?) {
        guard let users = userList?.toUserEntities() else { return }

        handlers.forEach { $0.onUsersUpdate?(users) }
    }
    
    func onUserAlertsUpdate(_ api: MEGASdk, userAlertList: MEGAUserAlertList?) {
        guard let userAlerts = userAlertList?.toUserAlertEntities() else { return }
        handlers.forEach { $0.onUserAlertsUpdate?(userAlerts) }
    }
    
    func onContactRequestsUpdate(_ api: MEGASdk, contactRequestList: MEGAContactRequestList?) {
        guard let contactRequests = contactRequestList?.toContactRequestEntities() else { return }
        handlers.forEach { $0.onContactRequestsUpdate?(contactRequests) }
    }
    
    func onEvent(_ api: MEGASdk, event: MEGAEvent) {
        handlers.forEach { $0.onEvent?(event.toEventEntity()) }
    }
    
    func onAccountUpdate(_ api: MEGASdk) {
        handlers.forEach { $0.onAccountUpdate?() }
    }
    
    func onSetsUpdate(_ api: MEGASdk, sets: [MEGASet]?) {
        guard let sets = sets?.toSetEntities() else { return }
        handlers.forEach { $0.onSetsUpdate?(sets) }
    }
    
    func onSetElementsUpdate(_ api: MEGASdk, setElements: [MEGASetElement]?) {
        guard let setElements = setElements?.toSetElementsEntities() else { return }
        handlers.forEach { $0.onSetElementsUpdate?(setElements) }
    }
    
    // MARK: - Request events
    func onRequestStart(_ api: MEGASdk, request: MEGARequest) {
        handlers.forEach { $0.onRequestStart?(request.toRequestEntity()) }
    }
    
    func onRequestUpdate(_ api: MEGASdk, request: MEGARequest) {
        handlers.forEach { $0.onRequestUpdate?(request.toRequestEntity()) }
    }
    
    func onRequestTemporaryError(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        handlers.forEach { $0.onRequestTemporaryError?(RequestResponseEntity(requestEntity: request.toRequestEntity(), error: error.toErrorEntity())) }
    }
    
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        handlers.forEach { $0.onRequestFinish?(RequestResponseEntity(requestEntity: request.toRequestEntity(), error: error.toErrorEntity())) }
    }
    
    // MARK: - Transfer events
    func onTransferStart(_ api: MEGASdk, transfer: MEGATransfer) {
        handlers.forEach { $0.onTransferStart?(transfer.toTransferEntity()) }
    }
    
    func onTransferUpdate(_ api: MEGASdk, transfer: MEGATransfer) {
        handlers.forEach { $0.onTransferUpdate?(transfer.toTransferEntity()) }
    }
    
    func onTransferTemporaryError(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        handlers.forEach { $0.onTransferTemporaryError?(TransferResponseEntity(transferEntity: transfer.toTransferEntity(), error: error.toErrorEntity())) }
    }
    
    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        handlers.forEach { $0.onTransferFinish?(TransferResponseEntity(transferEntity: transfer.toTransferEntity(), error: error.toErrorEntity())) }
    }
    
    // MARK: - Handler management
    func add(handler: MEGAUpdateHandler) {
        $handlers.mutate { $0.append(handler) }
    }
    
    func remove(handler: MEGAUpdateHandler) {
        $handlers.mutate { $0.remove(object: handler) }
    }
}
