import MEGADomain
import MEGASdk
import MEGASwift

extension MEGAUpdateHandlerManager {
    // MARK: - Global updates
    
    var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onNodesUpdate: { continuation.yield($0) })
            
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }
        .eraseToAnyAsyncSequence()
    }
    
    var userUpdates: AnyAsyncSequence<[UserEntity]> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onUsersUpdate: { continuation.yield($0) })
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }.eraseToAnyAsyncSequence()
    }
    
    var userAlertUpdates: AnyAsyncSequence<[UserAlertEntity]> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onUserAlertsUpdate: { continuation.yield($0) })
            
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }.eraseToAnyAsyncSequence()
    }
    
    var contactRequestUpdates: AnyAsyncSequence<[ContactRequestEntity]> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onContactRequestsUpdate: { continuation.yield($0) })
            
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }.eraseToAnyAsyncSequence()
    }
    
    var eventUpdates: AnyAsyncSequence<EventEntity> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onEvent: { continuation.yield($0) })
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }.eraseToAnyAsyncSequence()
    }
    
    var accountUpdates: AnyAsyncSequence<Void> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onAccountUpdate: { continuation.yield() })
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }.eraseToAnyAsyncSequence()
    }
    
    var setsUpdates: AnyAsyncSequence<[SetEntity]> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onSetsUpdate: { continuation.yield($0) })
            add(handler: handler)

            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }.eraseToAnyAsyncSequence()
    }
    
    var setElementsUpdates: AnyAsyncSequence<[SetElementEntity]> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onSetElementsUpdate: { continuation.yield($0) })
            add(handler: handler)

            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }.eraseToAnyAsyncSequence()
    }

    // MARK: - Request updates
    
    var requestStartUpdates: AnyAsyncSequence<RequestEntity> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onRequestStart: { continuation.yield($0) })
            
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }
        .eraseToAnyAsyncSequence()
    }
    
    var requestUpdates: AnyAsyncSequence<RequestEntity> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onRequestUpdate: { continuation.yield($0) })
            
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }
        .eraseToAnyAsyncSequence()
    }
    
    var requestTemporaryErrorUpdates: AnyAsyncSequence<RequestResponseEntity> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onRequestTemporaryError: { continuation.yield($0) })
            
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }
        .eraseToAnyAsyncSequence()
    }
    
    var requestFinishUpdates: AnyAsyncSequence<RequestResponseEntity> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onRequestFinish: { continuation.yield($0) })
            
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }
        .eraseToAnyAsyncSequence()
    }
    
    // MARK: - Transfer updates
    
    var transferStarUpdates: AnyAsyncSequence<TransferEntity> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onTransferStart: { continuation.yield($0) })
            
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }
        .eraseToAnyAsyncSequence()
    }
    
    var transferUpdates: AnyAsyncSequence<TransferEntity> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onTransferUpdate: { continuation.yield($0) })
            
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }
        .eraseToAnyAsyncSequence()
    }
    
    var transferTemporaryErrorUpdates: AnyAsyncSequence<TransferResponseEntity> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onTransferTemporaryError: { continuation.yield($0) })
            
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }
        .eraseToAnyAsyncSequence()
    }
    
    var transferFinishUpdates: AnyAsyncSequence<TransferResponseEntity> {
        AsyncStream { continuation in
            let handler = MEGAUpdateHandler(onTransferFinish: { continuation.yield($0) })
            
            add(handler: handler)
            
            continuation.onTermination = { [weak self] _ in self?.remove(handler: handler) }
        }
        .eraseToAnyAsyncSequence()
    }
}
