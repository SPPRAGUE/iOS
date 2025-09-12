@preconcurrency import Combine
import ContentLibraries
@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
@testable import MEGADomain
import MEGADomainMock
import MEGAPermissionsMock
import MEGAPreference
import XCTest

final class PhotosViewModelTests: XCTestCase {
    var sut: PhotosViewModel!
    
    @MainActor
    override func setUp() {
        let publisher = PhotoUpdatePublisher(photosViewController: PhotosViewController())
        let allPhotos = sampleNodesForAllLocations()
        let allPhotosForCloudDrive = sampleNodesForCloudDriveOnly()
        let allPhotosForCameraUploads = sampleNodesForCameraUploads()
        let usecase = MockPhotoLibraryUseCase(allPhotos: allPhotos,
                                              allPhotosFromCloudDriveOnly: allPhotosForCloudDrive,
                                              allPhotosFromCameraUpload: allPhotosForCameraUploads)
        sut = PhotosViewModel(
            photoUpdatePublisher: publisher,
            photoLibraryUseCase: usecase,
            contentConsumptionUserAttributeUseCase: MockContentConsumptionUserAttributeUseCase(
                timelineUserAttributeEntity: .init(mediaType: .images, location: .cloudDrive, usePreference: true)),
            sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc),
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(), 
            devicePermissionHandler: MockDevicePermissionHandler(),
            cameraUploadsSettingsViewRouter: MockCameraUploadsSettingsViewRouter())
    }
    
    @MainActor
    func testCameraUploadExplorerSortOrderType_whenGivenValueEqualsModificationDesc_shouldReturnNewest() async throws {
                
        let givenSortOrder = SortOrderEntity.modificationDesc
        
        // Arrange
        let sut = makePhotosViewModel(sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: givenSortOrder))
        // Act
        let result = await sut.$cameraUploadExplorerSortOrderType.values.first { @Sendable sort in sort == .newest }
        // Assert
        XCTAssertEqual(result, .newest)
    }
    
    @MainActor
    func testCameraUploadExplorerSortOrderType_whenGivenValueEqualsModificationAsc_shouldReturnOldest() async throws {
        
        let givenSortOrder = SortOrderEntity.modificationAsc
        
        // Arrange
        let sut = makePhotosViewModel(
            sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(
                sortOrderEntity: givenSortOrder))
        
        // Act
        var result: SortOrderType?
        let exp = expectation(description: "Expected correct sortOrderType to be returned")
        let cancellable = sut.$cameraUploadExplorerSortOrderType
            .first(where: { $0 == .oldest })
            .sink {
                result = $0
                exp.fulfill()
            }

        await fulfillment(of: [exp], timeout: 1)
        cancellable.cancel()
        
        // Assert
        XCTAssertEqual(result, .oldest)
    }
    
    @MainActor
    func testCameraUploadExplorerSortOrderType_whenGivenValueEqualsNonModificationType_shouldReturnNewest() async throws {
                
        let givenSortOrder = SortOrderEntity.favouriteAsc
        
        // Arrange
        let sut = makePhotosViewModel(sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: givenSortOrder))
        // Act
        let result = await sut.$cameraUploadExplorerSortOrderType.values.first { @Sendable sort in sort == .newest }
        // Assert
        XCTAssertEqual(result, .newest)
    }
    
    // MARK: - All locations test cases
    @MainActor
    func testLoadingPhotos_withAllMediaAllLocations_shouldReturnTrue() async throws {
        let expectedPhotos = sampleNodesForAllLocations()
        sut.filterType = .allMedia
        sut.filterLocation = . allLocations
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedPhotos)
    }
    
    @MainActor
    func testLoadingPhotos_withAllMediaAllLocations_shouldExcludeThumbnailLessPhotos() async throws {
        let photos = [
            NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 1, parentHandle: 0, hasThumbnail: true),
            NodeEntity(nodeType: .file, name: "TestImage2.png", handle: 2, parentHandle: 1, hasThumbnail: true),
            NodeEntity(nodeType: .file, name: "TestVideo1.mp4", handle: 3, parentHandle: 2, hasThumbnail: false),
            NodeEntity(nodeType: .file, name: "TestVideo2.mp4", handle: 4, parentHandle: 3, hasThumbnail: false),
            NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 5, parentHandle: 4, hasThumbnail: true)
        ]
        
        let publisher = PhotoUpdatePublisher(photosViewController: PhotosViewController())
        let usecase = MockPhotoLibraryUseCase(allPhotos: photos,
                                              allPhotosFromCloudDriveOnly: [],
                                              allPhotosFromCameraUpload: [])
        sut = PhotosViewModel(
            photoUpdatePublisher: publisher,
            photoLibraryUseCase: usecase,
            contentConsumptionUserAttributeUseCase: MockContentConsumptionUserAttributeUseCase(),
            sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc),
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(),
            devicePermissionHandler: MockDevicePermissionHandler(),
            cameraUploadsSettingsViewRouter: MockCameraUploadsSettingsViewRouter())
        
        sut.filterType = .allMedia
        sut.filterLocation = . allLocations
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, photos.filter { $0.hasThumbnail })
    }
    
    @MainActor
    func testLoadingPhotos_withImagesAllLocations_shouldReturnTrue() async throws {
        let expectedImages = sampleNodesForAllLocations().filter(\.fileExtensionGroup.isImage)
        sut.filterType = .images
        sut.filterLocation = .allLocations
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedImages)
    }
    
    @MainActor
    func testLoadingVideos_withImagesAllLocations_shouldReturnTrue() async throws {
        let expectedVideos = sampleNodesForAllLocations().filter(\.fileExtensionGroup.isVideo)
        sut.filterType = .videos
        sut.filterLocation = . allLocations
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedVideos)
    }
    
    // MARK: - Cloud Drive only test cases
    @MainActor
    func testLoadingPhotos_withAllMediaFromCloudDrive_shouldReturnTrue() async throws {
        let expectedPhotos = sampleNodesForCloudDriveOnly()
        sut.filterType = .allMedia
        sut.filterLocation = .cloudDrive
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedPhotos)
    }
    
    @MainActor
    func testLoadingPhotos_withImagesFromCloudDrive_shouldReturnTrue() async throws {
        let expectedImages = sampleNodesForCloudDriveOnly().filter(\.fileExtensionGroup.isImage)
        sut.filterType = .images
        sut.filterLocation = .cloudDrive
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedImages)
    }
    
    @MainActor
    func testLoadingPhotos_withVideosFromCloudDrive_shouldReturnTrue() async throws {
        let expectedVideos = sampleNodesForCloudDriveOnly().filter(\.fileExtensionGroup.isVideo)
        sut.filterType = .videos
        sut.filterLocation = .cloudDrive
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedVideos)
    }
    
    // MARK: - Camera Uploads test cases
    @MainActor
    func testLoadingPhotos_withAllMediaFromCameraUploads_shouldReturnTrue() async throws {
        let expectedPhotos = sampleNodesForCameraUploads()
        sut.filterType = .allMedia
        sut.filterLocation = .cameraUploads
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedPhotos)
    }
    
    @MainActor
    func testLoadingPhotos_withImagesFromCameraUploads_shouldReturnTrue() async throws {
        let expectedImages = sampleNodesForCameraUploads().filter(\.fileExtensionGroup.isImage)
        sut.filterType = .images
        sut.filterLocation = .cameraUploads
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedImages)
    }
    
    @MainActor
    func testLoadingPhotos_withVideosFromCameraUploads_shouldReturnTrue() async throws {
        let expectedVideos = sampleNodesForCameraUploads().filter(\.fileExtensionGroup.isVideo)
        sut.filterType = .videos
        sut.filterLocation = .cameraUploads
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodes, expectedVideos)
    }
    
    @MainActor
    func testIsSelectHidden_onToggle_changesInitialFalseValueToTrue() {
        XCTAssertFalse(sut.isSelectHidden)
        sut.isSelectHidden.toggle()
        XCTAssertTrue(sut.isSelectHidden)
    }
    
    @MainActor
    func testFilterType_whenCheckingSavedFilter_shouldReturnRightValues() {
        XCTAssertEqual(PhotosFilterOptions.images, sut.filterType(from: .images))
        XCTAssertEqual(PhotosFilterOptions.videos, sut.filterType(from: .videos))
        XCTAssertEqual(PhotosFilterOptions.allMedia, sut.filterType(from: .allMedia))
    }
    
    @MainActor
    func testFilterLocation_whenCheckingSavedFilter_shouldReturnRightValues() {
        XCTAssertEqual(PhotosFilterOptions.cloudDrive, sut.filterLocation(from: .cloudDrive))
        XCTAssertEqual(PhotosFilterOptions.cameraUploads, sut.filterLocation(from: .cameraUploads))
        XCTAssertEqual(PhotosFilterOptions.allLocations, sut.filterLocation(from: .allLocations))
    }
    
    @MainActor
    func testLoadAllPhotosWithSavedFilters_whenTheScreenAppear_shouldLoadTheExistingFilters() async {
        let useCase = MockContentConsumptionUserAttributeUseCase(
            timelineUserAttributeEntity: .init(mediaType: .videos, location: .cloudDrive, usePreference: true))
            
        let sut = makePhotosViewModel(contentConsumptionUserAttributeUseCase: useCase)
        
        sut.loadAllPhotosWithSavedFilters()
        await sut.contentConsumptionAttributeLoadingTask?.value
        
        XCTAssertEqual(sut.filterType, .videos)
        XCTAssertEqual(sut.filterLocation, .cloudDrive)
    }
    
    @MainActor
    func testNavigateToCameraUploadSettings_called_shouldStartNavigation() {
        let cameraUploadsSettingsViewRouter = MockCameraUploadsSettingsViewRouter()
        let sut = makePhotosViewModel(preferenceUseCase: MockPreferenceUseCase(dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: false]),
                                      cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter)
        
        sut.navigateToCameraUploadSettings()
        
        XCTAssertEqual(cameraUploadsSettingsViewRouter.startCalled, 1)
    }
    
    @MainActor
    func testCameraUploadStatusButtonTapped_whenCameraUploadesIsDisabled_shouldNavigateToCUSetting() {
        let cameraUploadsSettingsViewRouter = MockCameraUploadsSettingsViewRouter()
        let sut = makePhotosViewModel(
            preferenceUseCase: MockPreferenceUseCase(dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: false]),
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter)
        
        sut.cameraUploadStatusButtonViewModel.onTappedHandler?()
        
        XCTAssertEqual(cameraUploadsSettingsViewRouter.startCalled, 1)
        XCTAssertFalse(sut.timelineViewModel.cameraUploadStatusBannerViewModel.cameraUploadStatusShown)
    }
    
    @MainActor
    func testCameraUploadStatusButtonTapped_whenCameraUploadesEnabled_shouldShowCUStatusBanner() {
        let cameraUploadsSettingsViewRouter = MockCameraUploadsSettingsViewRouter()
        let sut = makePhotosViewModel(
            preferenceUseCase: MockPreferenceUseCase(dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: true]),
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter)
        
        sut.cameraUploadStatusButtonViewModel.onTappedHandler?()
        
        XCTAssertEqual(cameraUploadsSettingsViewRouter.startCalled, 0)
        XCTAssertTrue(sut.timelineViewModel.cameraUploadStatusBannerViewModel.cameraUploadStatusShown)
    }
    
    @MainActor
    func testTrackHideNodeMenuEvent_shouldTrackEvent() {
        let tracker = MockTracker()
        let sut = makePhotosViewModel(
            tracker: tracker
        )
        
        sut.trackHideNodeMenuEvent()
        
        assertTrackAnalyticsEventCalled(trackedEventIdentifiers: tracker.trackedEventIdentifiers, with: [TimelineHideNodeMenuItemEvent()])
    }
    
    private func sampleNodesForAllLocations() -> [NodeEntity] {
        let node1 = NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 1, parentHandle: 0, hasThumbnail: true)
        let node2 = NodeEntity(nodeType: .file, name: "TestImage2.png", handle: 2, parentHandle: 1, hasThumbnail: true)
        let node3 = NodeEntity(nodeType: .file, name: "TestVideo1.mp4", handle: 3, parentHandle: 2, hasThumbnail: true)
        let node4 = NodeEntity(nodeType: .file, name: "TestVideo2.mp4", handle: 4, parentHandle: 3, hasThumbnail: true)
        let node5 = NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 5, parentHandle: 4, hasThumbnail: true)
        let node6 = NodeEntity(nodeType: .file, name: "TestImage2.png", handle: 6, parentHandle: 5, hasThumbnail: true)
        let node7 = NodeEntity(nodeType: .file, name: "TestVideo1.mp4", handle: 7, parentHandle: 6, hasThumbnail: true)
        let node8 = NodeEntity(nodeType: .file, name: "TestVideo2.mp4", handle: 8, parentHandle: 7, hasThumbnail: true)
        
        return [node1, node2, node3, node4, node5, node6, node7, node8]
    }
    
    private func sampleNodesForCloudDriveOnly() -> [NodeEntity] {
        let node1 = NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 1, parentHandle: 1, hasThumbnail: true)
        let node2 = NodeEntity(nodeType: .file, name: "TestImage2.png", handle: 2, parentHandle: 1, hasThumbnail: true)
        let node3 = NodeEntity(nodeType: .file, name: "TestVideo1.mp4", handle: 3, parentHandle: 1, hasThumbnail: true)
        let node4 = NodeEntity(nodeType: .file, name: "TestVideo2.mp4", handle: 4, parentHandle: 1, hasThumbnail: true)
        
        return [node1, node2, node3, node4]
    }
    
    private func sampleNodesForCameraUploads() -> [NodeEntity] {
        let node1 = NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 1, parentHandle: 1, hasThumbnail: true)
        let node2 = NodeEntity(nodeType: .file, name: "TestImage2.png", handle: 2, parentHandle: 1, hasThumbnail: true)
        let node3 = NodeEntity(nodeType: .file, name: "TestVideo1.mp4", handle: 3, parentHandle: 1, hasThumbnail: true)
        let node4 = NodeEntity(nodeType: .file, name: "TestVideo2.mp4", handle: 4, parentHandle: 1, hasThumbnail: true)
        
        return [node1, node2, node3, node4]
    }
    
    @MainActor
    private func makePhotosViewModel(
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol = MockContentConsumptionUserAttributeUseCase(),
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol = MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        cameraUploadsSettingsViewRouter: some Routing = MockCameraUploadsSettingsViewRouter(),
        monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase = MockMonitorCameraUploadUseCase(),
        tracker: MockTracker = MockTracker()
    ) -> PhotosViewModel {
        let publisher = PhotoUpdatePublisher(photosViewController: PhotosViewController())
        let usecase = MockPhotoLibraryUseCase(allPhotos: [],
                                              allPhotosFromCloudDriveOnly: [],
                                              allPhotosFromCameraUpload: [])
        return PhotosViewModel(photoUpdatePublisher: publisher,
                               photoLibraryUseCase: usecase,
                               contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
                               sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
                               preferenceUseCase: preferenceUseCase,
                               monitorCameraUploadUseCase: monitorCameraUploadUseCase,
                               devicePermissionHandler: MockDevicePermissionHandler(),
                               cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter,
                               tracker: tracker
        )
    }
}

@MainActor
private class MockCameraUploadsSettingsViewRouter: Routing {
    private(set) var startCalled = 0
    
    nonisolated init() {}
    
    func start() {
        startCalled += 1
    }
}
