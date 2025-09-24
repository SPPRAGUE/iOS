import Foundation
import MEGADomain
import MEGASdk

final class MEGAUpdateHandler: NSObject, Sendable {
    typealias NodesUpdateHandler = @Sendable ([NodeEntity]) -> Void
    typealias UsersUpdateHandler = @Sendable ([UserEntity]) -> Void
    typealias UserAlertsUpdateHandler = @Sendable ([UserAlertEntity]) -> Void
    typealias ContactRequestsUpdateHandler = @Sendable ([ContactRequestEntity]) -> Void
    typealias EventHandler = @Sendable (EventEntity) -> Void
    typealias AccountUpdateHandler = @Sendable () -> Void
    typealias SetsUpdateHandler = @Sendable ([SetEntity]) -> Void
    typealias SetElementsUpdateHandler = @Sendable ([SetElementEntity]) -> Void

    typealias RequestStartHandler = @Sendable (RequestEntity) -> Void
    typealias RequestUpdateHandler = @Sendable (RequestEntity) -> Void
    typealias RequestTemporaryErrorHandler = @Sendable (RequestResponseEntity) -> Void
    typealias RequestFinishHandler = @Sendable (RequestResponseEntity) -> Void
    
    typealias TransferStartHandler = @Sendable (TransferEntity) -> Void
    typealias TransferUpdateHandler = @Sendable (TransferEntity) -> Void
    typealias TransferTemporaryErrorHandler = @Sendable (TransferResponseEntity) -> Void
    typealias TransferFinishHandler = @Sendable (TransferResponseEntity) -> Void
    
    let onNodesUpdate: NodesUpdateHandler?
    let onUsersUpdate: UsersUpdateHandler?
    let onUserAlertsUpdate: UserAlertsUpdateHandler?
    let onContactRequestsUpdate: ContactRequestsUpdateHandler?
    let onEvent: EventHandler?
    let onAccountUpdate: AccountUpdateHandler?
    let onSetsUpdate: SetsUpdateHandler?
    let onSetElementsUpdate: SetElementsUpdateHandler?
    
    let onRequestStart: RequestStartHandler?
    let onRequestUpdate: RequestUpdateHandler?
    let onRequestTemporaryError: RequestTemporaryErrorHandler?
    let onRequestFinish: RequestFinishHandler?
    
    let onTransferStart: TransferStartHandler?
    let onTransferUpdate: TransferUpdateHandler?
    let onTransferTemporaryError: TransferTemporaryErrorHandler?
    let onTransferFinish: TransferFinishHandler?
    
    init(
        onNodesUpdate: NodesUpdateHandler? = nil,
        onUsersUpdate: UsersUpdateHandler? = nil,
        onUserAlertsUpdate: UserAlertsUpdateHandler? = nil,
        onContactRequestsUpdate: ContactRequestsUpdateHandler? = nil,
        onEvent: EventHandler? = nil,
        onAccountUpdate: AccountUpdateHandler? = nil,
        onSetsUpdate: SetsUpdateHandler? = nil,
        onSetElementsUpdate: SetElementsUpdateHandler? = nil,
        onRequestStart: RequestStartHandler? = nil,
        onRequestUpdate: RequestUpdateHandler? = nil,
        onRequestTemporaryError: RequestTemporaryErrorHandler? = nil,
        onRequestFinish: RequestFinishHandler? = nil,
        onTransferStart: TransferStartHandler? = nil,
        onTransferUpdate: TransferUpdateHandler? = nil,
        onTransferTemporaryError: TransferTemporaryErrorHandler? = nil,
        onTransferFinish: TransferFinishHandler? = nil
    ) {
        self.onNodesUpdate = onNodesUpdate
        self.onUsersUpdate = onUsersUpdate
        self.onUserAlertsUpdate = onUserAlertsUpdate
        self.onContactRequestsUpdate = onContactRequestsUpdate
        self.onEvent = onEvent
        self.onAccountUpdate = onAccountUpdate
        self.onSetsUpdate = onSetsUpdate
        self.onSetElementsUpdate = onSetElementsUpdate
        self.onRequestStart = onRequestStart
        self.onRequestUpdate = onRequestUpdate
        self.onRequestTemporaryError = onRequestTemporaryError
        self.onRequestFinish = onRequestFinish
        self.onTransferStart = onTransferStart
        self.onTransferUpdate = onTransferUpdate
        self.onTransferTemporaryError = onTransferTemporaryError
        self.onTransferFinish = onTransferFinish
    }
}
