import Combine
@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGASdk
import XCTest

final class NodeCollectionViewCellViewModelTests: XCTestCase {
    
    @MainActor
    func testIsNodeVideo_videoName_shouldBeTrue() {
        let viewModel = sut()
        
        XCTAssertTrue(viewModel.isNodeVideo(name: "video.mp4"))
    }
    
    @MainActor
    func testIsNodeVideo_imageName_shouldBeFalse() {
        let viewModel = sut()
        
        XCTAssertFalse(viewModel.isNodeVideo(name: "image.png"))
    }
    
    @MainActor
    func testIsNodeVideo_noName_shouldBeFalse() {
        let viewModel = sut()
        
        XCTAssertFalse(viewModel.isNodeVideo(name: ""))
    }
    
    @MainActor
    func testIsNodeVideoWithValidDuration_withVideo_validDuration_shouldBeTrue() {
        let mockNode = NodeEntity(name: "video.mp4", handle: 1, duration: 10)
        let viewModel = sut(node: mockNode)
        
        XCTAssertTrue(viewModel.isNodeVideoWithValidDuration())
    }
    
    @MainActor
    func testIsNodeVideoWithValidDuration_withVideo_zeroDuration_shouldBeTrue() {
        let mockNode = NodeEntity(name: "video.mp4", handle: 1, duration: 0)
        let viewModel = sut(node: mockNode)
        
        XCTAssertTrue(viewModel.isNodeVideoWithValidDuration())
    }
    
    @MainActor
    func testIsNodeVideoWithValidDuration_withVideo_invalidDuration_shouldBeFalse() {
        let mockNode = NodeEntity(name: "video.mp4", handle: 1, duration: -1)
        let viewModel = sut(node: mockNode)
        
        XCTAssertFalse(viewModel.isNodeVideoWithValidDuration())
    }
    
    @MainActor
    func testIsNodeVideoWithValidDuration_notVideo_shouldBeFalse() {
        let mockNode = NodeEntity(name: "image.png", handle: 1, duration: 0)
        let viewModel = sut(node: mockNode)
        
        XCTAssertFalse(viewModel.isNodeVideoWithValidDuration())
    }
    
    @MainActor
    func testIsNodeVideoWithValidDuration_noName_shouldBeFalse() {
        let mockNode = NodeEntity(name: "", handle: 1, duration: 0)
        let viewModel = sut(node: mockNode)
        
        XCTAssertFalse(viewModel.isNodeVideoWithValidDuration())
    }
    
    @MainActor
    func testHasThumbnail_NodeEntityHasThumbnail_shouldBeTrue() {
        let mockNode = NodeEntity(handle: 1, hasThumbnail: true)
        let viewModel = sut(node: mockNode)
        
        XCTAssertTrue(viewModel.hasThumbnail)
    }
    
    @MainActor
    func testHasThumbnail_nodeIsNil_shouldBeFalse() {
        let viewModel = sut(node: nil)
        
        XCTAssertFalse(viewModel.hasThumbnail)
    }
    
    @MainActor
    func testConfigureCell_whenFeatureFlagOnAndNodeIsNil_shouldSetIsSensitiveFalse() async {
        let viewModel = sut(
            node: NodeEntity(handle: 1, isMarkedSensitive: true),
            isFromSharedItem: true,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(false)),
            featureFlagHiddenNodes: true)
        
        await viewModel.configureCell().value

        let expectation = expectation(description: "viewModel.isSensitive should return value")
        let subscription = viewModel.$isSensitive
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { isSensitive in
                XCTAssertFalse(isSensitive)
                expectation.fulfill()
            }
        
        await fulfillment(of: [expectation], timeout: 1)
        
        subscription.cancel()
    }
    
    @MainActor
    func testConfigureCell_whenFeatureFlagOnAndIsFromSharedItem_shouldSetIsSensitiveFalse() async {
        let viewModel = sut(
            node: nil,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(false)),
            featureFlagHiddenNodes: true)
        
        await viewModel.configureCell().value

        let expectation = expectation(description: "viewModel.isSensitive should return value")
        let subscription = viewModel.$isSensitive
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { isSensitive in
                XCTAssertFalse(isSensitive)
                expectation.fulfill()
            }
        
        await fulfillment(of: [expectation], timeout: 1)
        
        subscription.cancel()
    }
    
    @MainActor
    func testConfigureCell_whenAccountIsInvalid_shouldSetIsSensitiveFalse() async {
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)
        let viewModel = sut(
            node: node,
            isFromSharedItem: false,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                isAccessible: false),
            featureFlagHiddenNodes: true)
        
        await viewModel.configureCell().value

        let expectation = expectation(description: "viewModel.isSensitive should return value")
        let subscription = viewModel.$isSensitive
            .first { !$0 }
            .sink { isSensitive in
                XCTAssertFalse(isSensitive)
                expectation.fulfill()
            }
        
        await fulfillment(of: [expectation], timeout: 1)
        
        subscription.cancel()
    }
    
    @MainActor
    func testConfigureCell_whenFeatureFlagOnAndNodeIsSensitive_shouldSetIsSensitiveTrue() async {
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)
        let viewModel = sut(
            node: node,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                isAccessible: true,
                isInheritingSensitivityResult: .success(false)),
            featureFlagHiddenNodes: true)
        
        await viewModel.configureCell().value

        let expectation = expectation(description: "viewModel.isSensitive should return value")
        let subscription = viewModel.$isSensitive
            .first { $0 }
            .sink { isSensitive in
                XCTAssertTrue(isSensitive)
                expectation.fulfill()
            }
        
        await fulfillment(of: [expectation], timeout: 1)
        
        subscription.cancel()
    }
    
    @MainActor
    func testConfigureCell_whenFeatureFlagOffAndNodeIsSensitive_shouldSetIsSensitiveFalse() async {
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)
        let viewModel = sut(
            node: node,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                isAccessible: true,
                isInheritingSensitivityResult: .success(false)),
            featureFlagHiddenNodes: false)
        
        await viewModel.configureCell().value

        let expectation = expectation(description: "viewModel.isSensitive should return value")
        let subscription = viewModel.$isSensitive
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .first { !$0 }
            .sink { isSensitive in
                XCTAssertFalse(isSensitive)
                expectation.fulfill()
            }
        
        await fulfillment(of: [expectation], timeout: 1)
        
        subscription.cancel()
    }
    
    @MainActor
    func testConfigureCell_whenFeatureFlagOnAndNodeInheritedSensitivity_shouldSetIsSensitiveTrue() async {
        let node = NodeEntity(handle: 1, isMarkedSensitive: false)
        let viewModel = sut(
            node: node,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                isAccessible: true,
                isInheritingSensitivityResult: .success(true)),
            featureFlagHiddenNodes: true)
        
        await viewModel.configureCell().value

        let expectation = expectation(description: "viewModel.isSensitive should return value")
        let subscription = viewModel.$isSensitive
            .first { $0 }
            .sink { isSensitive in
                XCTAssertTrue(isSensitive)
                expectation.fulfill()
            }
        
        await fulfillment(of: [expectation], timeout: 1)
        
        subscription.cancel()
    }
        
    @MainActor
    func testConfigureCell_whenFeatureFlagOffAndNodeInheritedSensitivity_shouldSetIsSensitiveFalse() async {
        let node = NodeEntity(handle: 1, isMarkedSensitive: false)
        let viewModel = sut(
            node: node,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(true)),
            featureFlagHiddenNodes: false)

        await viewModel.configureCell().value
        
        let expectation = expectation(description: "viewModel.isSensitive should return value")
        let subscription = viewModel.$isSensitive
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .first { !$0 }
            .sink { isSensitive in
                XCTAssertFalse(isSensitive)
                expectation.fulfill()
            }
        
        await fulfillment(of: [expectation], timeout: 1)
        
        subscription.cancel()
    }
    
    @MainActor
    func testThumbnailLoading_whenNodeHasValidThumbnail_shouldReturnCachedImage() async throws {
        let imageUrl = try makeImageURL()
        let node = NodeEntity(handle: 1, hasThumbnail: true, isMarkedSensitive: true)

        let viewModel = sut(
            node: node,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(true)),
            thumbnailUseCase: MockThumbnailUseCase(
                loadThumbnailResult: .success(.init(url: imageUrl, type: .thumbnail))))
        
        await viewModel.configureCell().value
        
        let result = viewModel.thumbnail?.pngData()
        let expected = UIImage(contentsOfFile: imageUrl.path())?.pngData()
        
        XCTAssertEqual(result, expected)
    }
    
    @MainActor
    func testThumbnailLoading_whenNodeHasThumbnailAndFailsToLoad_shouldReturnFileTypeImage() async throws {
        let imageData = try XCTUnwrap(UIImage(systemName: "heart.fill")?.pngData())
        let node = NodeEntity(nodeType: .file, name: "test.txt", handle: 1, hasThumbnail: true, isMarkedSensitive: true)
        
        let nodeIconUseCase = MockNodeIconUsecase(stubbedIconData: imageData)
        let viewModel = sut(
            node: node,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isInheritingSensitivityResult: .success(true)),
            nodeIconUseCase: nodeIconUseCase)
        
        await viewModel.configureCell().value
        
        let result = viewModel.thumbnail?.pngData()
        
        XCTAssertEqual(result?.hashValue, imageData.hashValue)
    }

    @MainActor
    func testIsNodeVideo_whenFolder_shouldReturnFalse() {
        let node = NodeEntity(nodeType: .folder, name: "mkv", handle: 1, isFolder: true)
        let sut = sut(node: node)
        XCTAssertFalse(sut.isNodeVideo())
    }

    @MainActor
    func testIsNodeVideo_whenTxtFile_shouldReturnFalse() {
        let node = NodeEntity(nodeType: .file, name: "test.txt", handle: 1, isFile: true)
        let sut = sut(node: node)
        XCTAssertFalse(sut.isNodeVideo())
    }

    @MainActor
    func testIsNodeVideo_whenVideoFile_shouldReturnTrue() {
        let node = NodeEntity(nodeType: .file, name: "test.mkv", handle: 1, isFile: true)
        let sut = sut(node: node)
        XCTAssertTrue(sut.isNodeVideo())
    }
}

extension NodeCollectionViewCellViewModelTests {
    @MainActor
    private func sut(node: NodeEntity? = nil,
                     isFromSharedItem: Bool = false,
                     sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
                     nodeIconUseCase: some NodeIconUsecaseProtocol = MockNodeIconUsecase(stubbedIconData: Data()),
                     thumbnailUseCase: some ThumbnailUseCaseProtocol = MockThumbnailUseCase(),
                     featureFlagHiddenNodes: Bool = false) -> NodeCollectionViewCellViewModel {
        NodeCollectionViewCellViewModel(
            node: node,
            isFromSharedItem: isFromSharedItem,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            thumbnailUseCase: thumbnailUseCase,
            nodeIconUseCase: nodeIconUseCase,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: featureFlagHiddenNodes]))
    }
}
