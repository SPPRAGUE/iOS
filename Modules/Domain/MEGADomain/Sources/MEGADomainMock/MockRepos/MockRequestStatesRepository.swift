import MEGADomain
import MEGASwift

public final class MockRequestStatesRepository: RequestStatesRepositoryProtocol {
    public static var newRepo: MockRequestStatesRepository {
        MockRequestStatesRepository()
    }

    public let requestStartUpdates: AnyAsyncSequence<RequestEntity>
    public let requestUpdates: AnyAsyncSequence<RequestEntity>
    public let requestTemporaryErrorUpdates: AnyAsyncSequence<RequestResponseEntity>
    public let requestFinishUpdates: AnyAsyncSequence<RequestResponseEntity>
    public let folderLinkRequestStartUpdates: AnyAsyncSequence<RequestEntity>
    public let folderLinkRequestFinishUpdates: AnyAsyncSequence<RequestResponseEntity>
    
    public init(
        requestStartUpdates: AnyAsyncSequence<RequestEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        requestUpdates: AnyAsyncSequence<RequestEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        requestTemporaryErrorUpdates: AnyAsyncSequence<RequestResponseEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        requestFinishUpdates: AnyAsyncSequence<RequestResponseEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        folderLinkRequestStartUpdates: AnyAsyncSequence<RequestEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        folderLinkRequestFinishUpdates: AnyAsyncSequence<RequestResponseEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.requestStartUpdates = requestStartUpdates
        self.requestUpdates = requestUpdates
        self.requestTemporaryErrorUpdates = requestTemporaryErrorUpdates
        self.requestFinishUpdates = requestFinishUpdates
        self.folderLinkRequestStartUpdates = folderLinkRequestStartUpdates
        self.folderLinkRequestFinishUpdates = folderLinkRequestFinishUpdates
    }
}
