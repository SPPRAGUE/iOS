import AsyncAlgorithms
import Combine
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGASdk
import MEGASwift
import Search

/// Dedicated actor to isolate loadMore function to prevent data race where multiple cells can trigger loadMore at the same time
@globalActor private actor LoadMoreActor {
    static var shared = LoadMoreActor()
}

/// abstraction into a search results
final class HomeSearchResultsProvider: SearchResultsProviding, @unchecked Sendable {
    private let filesSearchUseCase: any FilesSearchUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let mediaUseCase: any MediaUseCaseProtocol
    private let downloadedNodesListener: any DownloadedNodesListening
    private let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
    private let sdk: MEGASdk

    // We only initially fetch the node list when the user triggers search
    // Concrete nodes are then loaded one by one in the pagination
    @Atomic private var nodeList: NodeListEntity?
    
    /// Keeps track of how many SearchResult were returned to client's through search queries.
    /// This value plays an important role in pagination and node updates logic: When user query "loadMore" or there are node updates, we use this value incombination with `nodeList` to perform the needed computation.
    @Atomic private var filledItemsCount = 0
    @Atomic private var pageSize = 100
    @Atomic private var loadMorePagesOffset = 20
    @Atomic private var subscriptions = Set<AnyCancellable>()

    private let hiddenNodesFeatureEnabled: Bool
    private let isFromSharedItem: Bool

    // The node from which we want start searching from,
    // root node can be nil in case when we start app in offline
    private let parentNodeProvider: () -> NodeEntity?
    private let mapper: SearchResultMapper
    private let availableChips: [SearchChipEntity]

    init(
        parentNodeProvider: @escaping () -> NodeEntity?,
        filesSearchUseCase: some FilesSearchUseCaseProtocol,
        nodeDetailUseCase: some NodeDetailUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        mediaUseCase: some MediaUseCaseProtocol,
        downloadedNodesListener: some DownloadedNodesListening,
        nodeIconUsecase: some NodeIconUsecaseProtocol,
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
        allChips: [SearchChipEntity],
        sdk: MEGASdk,
        nodeActions: NodeActions,
        hiddenNodesFeatureEnabled: Bool,
        isFromSharedItem: Bool
    ) {
        self.parentNodeProvider = parentNodeProvider
        self.filesSearchUseCase = filesSearchUseCase
        self.nodeUseCase = nodeUseCase
        self.mediaUseCase = mediaUseCase
        self.downloadedNodesListener = downloadedNodesListener
        self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
        self.availableChips = allChips
        self.sdk = sdk
        self.hiddenNodesFeatureEnabled = hiddenNodesFeatureEnabled
        self.isFromSharedItem = isFromSharedItem

        mapper = SearchResultMapper(
            sdk: sdk,
            nodeIconUsecase: nodeIconUsecase,
            nodeDetailUseCase: nodeDetailUseCase,
            nodeUseCase: nodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            mediaUseCase: mediaUseCase,
            nodeActions: nodeActions,
            hiddenNodesFeatureEnabled: hiddenNodesFeatureEnabled,
            showHiddenNodeBlur: !isFromSharedItem
        )
    }
    
    /// Get the most updated results from data source according to a query.
    /// - Parameter queryRequest: The query
    /// - Returns: The updated results list, paginated based on the current number of results that was filled previously (plus an amount of `loadMorePagesOffset` results to facilite "load more" function)
    func refreshedSearchResults(queryRequest: SearchQuery) async throws -> SearchResultsEntity? {
        let refreshedNodeList = try await nodeListEntity(from: queryRequest)

        guard let refreshedNodeList else { return nil }
        
        // After refreshing, the number of nodes can change and we need to update pagination info
        let newNodesCount = refreshedNodeList.nodesCount
        
        // When current filledItemsCount is zero, we don't want to get zero results again,
        // instead we want to get more result(s) if possible, in this case we'll try to get an amount of `pageSize`
        // E.g: Initially a folder doesn't contain any children, when user add children to this folder we'll want the
        // refreshed results to contains the newly added node instead of the old zero `filledItemsCount`
        let numOfNodesToReturn = min(filledItemsCount != 0 ? filledItemsCount : pageSize, newNodesCount)
        $filledItemsCount.mutate { $0 = numOfNodesToReturn }
        
        var results: [SearchResult] = []
        
        if numOfNodesToReturn > 0 {
            results += (0..<numOfNodesToReturn).compactMap { refreshedNodeList.nodeAt($0) }.map(mapNodeToSearchResult)
        }
        
        $nodeList.mutate { $0 = refreshedNodeList }
        
        return SearchResultsEntity(
            results: results,
            availableChips: availableChips,
            appliedChips: queryRequest.chips
        )
    }
    
    func search(queryRequest: SearchQuery, lastItemIndex: Int? = nil) async -> SearchResultsEntity? {
        if let lastItemIndex {
            return await loadMore(queryRequest: queryRequest, index: lastItemIndex)
        } else {
            return try? await searchInitially(queryRequest: queryRequest)
        }
    }
    
    func currentResultIds() -> [Search.ResultId] {
        guard let nodeList else {
            return []
        }
        // need to cache this probably so that subsequent opens are fast for large datasets
        return nodeList.toNodeEntities().map { $0.id }
    }
    /// the requirement is to return children/contents of the
    /// folder being searched when query is empty, no chips etc
    func searchInitially(queryRequest: SearchQuery) async throws -> SearchResultsEntity {

        // Initially, no item is filled yet
        $filledItemsCount.mutate { $0 = 0 }

        let newNodeList = try await nodeListEntity(from: queryRequest)
        $nodeList.mutate { $0 = newNodeList }

        return switch queryRequest {
        case .initial:
            fillResults()
        case .userSupplied(let searchQueryEntity):
            if shouldShowRoot(for: searchQueryEntity) {
                fillResults()
            } else {
                fillResults(query: searchQueryEntity)
            }
        }
    }
    
    func searchResultUpdateSignalSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        merge(specificNodeUpdateSequence(), genericNodeUpdateSequence())
            .eraseToAnyAsyncSequence()
    }
    
    @LoadMoreActor
    private func loadMore(queryRequest: SearchQuery, index: Int) -> SearchResultsEntity? {
        guard let nodeList,
                filledItemsCount < nodeList.nodesCount,
              index >= filledItemsCount - loadMorePagesOffset else { return nil }
        switch queryRequest {
        case .initial:
            return fillResults()
        case .userSupplied(let query):
            return fillResults(query: query)
        }
    }
    
    private func nodeListEntity(from searchQuery: SearchQuery) async throws -> NodeListEntity? {
        guard let searchFilterEntity = await buildSearchFilterEntity(from: searchQuery) else {
            return nil
        }
    
        return try await filesSearchUseCase.search(filter: searchFilterEntity, cancelPreviousSearchIfNeeded: searchFilterEntity.supportCancel)
    }
    
    private func buildSearchFilterEntity(from searchQuery: SearchQuery) async -> SearchFilterEntity? {
        let recursive = switch searchQuery {
        case .initial:
            false
        case .userSupplied(let searchQueryEntity):
            !shouldShowRoot(for: searchQueryEntity)
        }
        
        return if recursive {
            .recursive(
                searchText: searchQuery.query,
                searchDescription: searchQuery.query,
                searchTag: searchQuery.query.removingFirstLeadingHash(),
                searchTargetLocation: { if let parentNode { .parentNode(parentNode) } else { .folderTarget(.rootNode) } }(),
                supportCancel: true,
                sortOrderType: searchQuery.sorting.toDomainSortOrderEntity(),
                formatType: searchQuery.selectedNodeFormat?.toNodeFormatEntity() ?? .unknown,
                sensitiveFilterOption: await shouldExcludeSensitive() ? .nonSensitiveOnly : .disabled,
                nodeTypeEntity: searchQuery.selectedNodeType?.toNodeTypeEntity() ?? .unknown,
                modificationTimeFrame: searchQuery.selectedModificationTimeFrame?.toSearchFilterTimeFrame(),
                useAndForTextQuery: false
            )
        } else if let node = parentNode ?? nodeUseCase.rootNode() {
            .nonRecursive(
               searchText: searchQuery.query,
               searchDescription: searchQuery.query,
               searchTag: searchQuery.query.removingFirstLeadingHash(),
               searchTargetNode: node,
               supportCancel: true,
               sortOrderType: searchQuery.sorting.toDomainSortOrderEntity(),
               formatType: searchQuery.selectedNodeFormat?.toNodeFormatEntity() ?? .unknown,
               sensitiveFilterOption: await shouldExcludeSensitive() ? .nonSensitiveOnly : .disabled,
               nodeTypeEntity: searchQuery.selectedNodeType?.toNodeTypeEntity() ?? .unknown,
               modificationTimeFrame: searchQuery.selectedModificationTimeFrame?.toSearchFilterTimeFrame(),
               useAndForTextQuery: false
           )
        } else {
            nil
        }
    }
    
    private func shouldExcludeSensitive() async -> Bool {
        guard !isFromSharedItem else {
            return false
        }
        let excludeSensitives = await sensitiveDisplayPreferenceUseCase.excludeSensitives()

        return hiddenNodesFeatureEnabled
        && excludeSensitives
        && !isNodeARubbishBinRootOrInRubbishBin()
    }

    private func isNodeARubbishBinRootOrInRubbishBin() -> Bool {
        guard let handle = parentNode?.handle else { return false }
        return nodeUseCase.isARubbishBinRootNode(nodeHandle: handle)
        || nodeUseCase.isInRubbishBin(nodeHandle: handle)
    }

    private var parentNode: NodeEntity? {
        parentNodeProvider()
    }

    private func shouldShowRoot(for queryRequest: SearchQueryEntity) -> Bool {
        if queryRequest == .initialRootQuery {
            return true
        }
        if queryRequest.query == "" && queryRequest.chips == [] {
            return true
        }
        return false
    }
    
    private func fillResults(query: SearchQueryEntity? = nil) -> SearchResultsEntity {
        guard let nodeList, filledItemsCount < nodeList.nodesCount else {
            return .init(
                results: [],
                availableChips: availableChips,
                appliedChips: query != nil ? chipsFor(query: query!) : []
            )
        }
        
        let nextPageFirstIndex = filledItemsCount
        let nextPageLastIndex = min(nextPageFirstIndex + pageSize - 1, nodeList.nodesCount - 1)
        
        var results: [SearchResult] = []
        for i in nextPageFirstIndex...nextPageLastIndex {
            if let nodeAt = nodeList.nodeAt(i) {
                results.append(mapNodeToSearchResult(nodeAt))
            }
        }
        
        $filledItemsCount.mutate { $0 = nextPageLastIndex + 1 }

        return .init(
            results: results,
            availableChips: availableChips,
            appliedChips: query != nil ? chipsFor(query: query!) : []
        )
    }
    
    private func chipsFor(query: SearchQueryEntity) -> [SearchChipEntity] {
        query.chips
    }
    
    private func mapNodeToSearchResult(_ node: NodeEntity) -> SearchResult {
        mapper.map(node: node)
    }
    
    private func genericNodeUpdateSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        nodeUseCase.nodeUpdates
            .compactMap { [weak self] updatedNodes -> SearchResultUpdateSignal? in
                guard let self,
                      let parentNodeHandle = parentNodeProvider()?.handle,
                      updatedNodes.contains(where: { 
                          // check if parent node is updated or any of the children
                          $0.handle == parentNodeHandle || $0.parentHandle == parentNodeHandle
                      }) || nodeUpdateContainsCurrentSearchResultValue(nodeUpdates: updatedNodes) else { return nil }
                
                return SearchResultUpdateSignal.generic
            }
            .eraseToAnyAsyncSequence()
    }
    
    private func specificNodeUpdateSequence() -> AnyAsyncSequence<SearchResultUpdateSignal> {
        downloadedNodesListener.downloadedNodes
            .map { [mapper] in
            SearchResultUpdateSignal.specific(result: mapper.map(node: $0))
        }.eraseToAnyAsyncSequence()
    }
    
    /// Check to see if the current search results contains the updated nodes. Search can contain nodes not part of the parent node.
    /// - Parameter nodeUpdates: The updated nodes
    private func nodeUpdateContainsCurrentSearchResultValue(nodeUpdates: [NodeEntity]) -> Bool {
        let currentResultIds = currentResultIds()
        return nodeUpdates.contains(where: { currentResultIds.contains($0.id) })
    }
}

extension SearchChipEntity.NodeType {
    func toNodeTypeEntity() -> NodeTypeEntity {
        switch self {
        case .unknown:
            .unknown
        case .file:
            .file
        case .folder:
            .folder
        case .root:
            .root
        case .incoming:
            .incoming
        case .rubbish:
            .rubbish
        }
    }
}

extension SearchChipEntity.NodeFormat {
    func toNodeFormatEntity() -> NodeFormatEntity {
        switch self {
        case .unknown:
            .unknown
        case .photo:
            .photo
        case .audio:
            .audio
        case .video:
            .video
        case .document:
            .document
        case .pdf:
            .pdf
        case .presentation:
            .presentation
        case .archive:
            .archive
        case .program:
            .program
        case .misc:
            .misc
        case .spreadsheet:
            .spreadsheet
        case .allDocs:
            .allDocs
        }
    }
}

extension SearchChipEntity.TimeFrame {
    func toSearchFilterTimeFrame() -> SearchFilterEntity.TimeFrame {
        SearchFilterEntity.TimeFrame(startDate: startDate, endDate: endDate)
    }
}
