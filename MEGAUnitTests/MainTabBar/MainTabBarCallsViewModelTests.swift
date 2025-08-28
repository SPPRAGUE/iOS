import CallKit
@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class MainTabBarCallsViewModelTests: XCTestCase {
    private let router = MockMainTabBarCallsRouter()

    @MainActor
    func testCallUpdate_onCallUpdateInProgressAndBeingModerator_waitingRoomListenerExists() {
        let callUpdateUseCase = MockCallUpdateUseCase()
        let viewModel = makeMainTabBarCallsViewModel(
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        )
        
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .inProgress, changeType: .status))

        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
    }
    
    @MainActor
    func testCallUpdate_onCallUpdateJoining_callSessionListenerExists() {
        let callUpdateUseCase = MockCallUpdateUseCase()
        
        let viewModel = makeMainTabBarCallsViewModel(
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        )
        
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .joining, changeType: .status))

        evaluate {
            viewModel.callSessionUpdateTask != nil
        }
    }
    
    @MainActor
    func testCallUpdate_onSessionUpdateRecordingStart_alertShouldBeShown() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("User name"))
        let callUpdateUseCase = MockCallUpdateUseCase()
        let sessionUpdateUseCase = MockSessionUpdateUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            sessionUpdateUseCase: sessionUpdateUseCase
        )
        
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .joining, changeType: .status))

        evaluate {
            viewModel.callSessionUpdateTask != nil
        }
        
        sessionUpdateUseCase.sendSessionUpdate((ChatSessionEntity(changeType: .onRecording, onRecording: true), CallEntity()))
        
        evaluate { self.router.showScreenRecordingAlert_calledTimes == 1 }
    }
    
    @MainActor
    func testJoinCall_onSessionInProgressIsRecording_alertShouldBeShown() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("User name"))
        let callUpdateUseCase = MockCallUpdateUseCase()
        let sessionUpdateUseCase = MockSessionUpdateUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            sessionUpdateUseCase: sessionUpdateUseCase
        )
        
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .joining, changeType: .status))
        
        evaluate {
            viewModel.callSessionUpdateTask != nil
        }
        
        sessionUpdateUseCase.sendSessionUpdate((ChatSessionEntity(statusType: .inProgress, changeType: .status, onRecording: true), CallEntity()))
        
        evaluate { self.router.showScreenRecordingAlert_calledTimes == 1 }
    }
    
    @MainActor
    func testJoinCall_onSessionInProgressIsRecording_alertShouldNotBeShown() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity())
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("User name"))
        let callUpdateUseCase = MockCallUpdateUseCase()
        let sessionUpdateUseCase = MockSessionUpdateUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            sessionUpdateUseCase: sessionUpdateUseCase
        )
        
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .joining, changeType: .status))
        
        evaluate {
            viewModel.callSessionUpdateTask != nil
        }
        
        sessionUpdateUseCase.sendSessionUpdate((ChatSessionEntity(statusType: .inProgress, changeType: .status, onRecording: false), CallEntity()))
        
        evaluate { self.router.showScreenRecordingAlert_calledTimes == 0 }
    }
    
    @MainActor
    func testCallUpdate_onSessionUpdateRecordingStop_recordingNotificationShouldBeShown() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("User name"))
        let callUpdateUseCase = MockCallUpdateUseCase()
        let sessionUpdateUseCase = MockSessionUpdateUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase,
            sessionUpdateUseCase: sessionUpdateUseCase
        )
        
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .joining, changeType: .status))
        
        evaluate {
            viewModel.callSessionUpdateTask != nil
        }
        
        sessionUpdateUseCase.sendSessionUpdate((ChatSessionEntity(changeType: .onRecording, onRecording: false), CallEntity()))
        
        evaluate { self.router.showScreenRecordingNotification_calledTimes == 1 }
    }

    @MainActor
    func testCallUpdate_onCallUpdateInProgressAndNotBeingModerator_waitingRoomListenerNotExists() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let callUpdateUseCase = MockCallUpdateUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: chatRoomUseCase
        )
        
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .inProgress, changeType: .status))

        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription == nil
        }
    }
    
    @MainActor
    func testCallUpdate_onCallUpdateInProgressAndWaitingRoomNotEnabled_waitingRoomListenerNotExists() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: false), peerPrivilege: .standard)
        let callUpdateUseCase = MockCallUpdateUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: chatRoomUseCase
        )
        
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .inProgress, changeType: .status))

        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription == nil
        }
    }
    
    @MainActor
    func testCallUpdate_oneUserOnWaitingRoomAndBeingModerator_showOneUserAlert() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("User name"))
        let callUseCase = MockCallUseCase()
        let callUpdateUseCase = MockCallUpdateUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase
        )
        
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .inProgress, changeType: .status))
        
        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
        
        callUseCase.callWaitingRoomUsersUpdateSubject.send(CallEntity(waitingRoom: WaitingRoomEntity(sessionClientIds: [100])))

        evaluate {
            self.router.showOneUserWaitingRoomDialog_calledTimes == 1
        }
    }
    
    @MainActor
    func testCallUpdate_severalUsersOnWaitingAndRoomBeingModerator_showSeveralUsersAlert() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let callUseCase = MockCallUseCase()
        let callUpdateUseCase = MockCallUpdateUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: chatRoomUseCase
        )
        
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .inProgress, changeType: .status))
        
        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
        
        callUseCase.callWaitingRoomUsersUpdateSubject.send(CallEntity(waitingRoom: WaitingRoomEntity(sessionClientIds: [100, 101])))

        evaluate {
            self.router.showSeveralUsersWaitingRoomDialog_calledTimes == 1
        }
    }
    
    @MainActor
    func testCallUpdate_noUsersOnWaitingRoomAndBeingModerator_dismissAlert() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let callUseCase = MockCallUseCase()
        let callUpdateUseCase = MockCallUpdateUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: chatRoomUseCase
        )
        
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .inProgress, changeType: .status))
        
        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
        
        callUseCase.callWaitingRoomUsersUpdateSubject.send(CallEntity(waitingRoom: WaitingRoomEntity(sessionClientIds: [])))

        evaluate {
            self.router.dismissWaitingRoomDialog_calledTimes == 1
        }
    }
    
    @MainActor
    func testCallUpdate_severalUsersOnWaitingAndRoomBeingModeratorAndCallChangeTypeWaitingRoomUsersAllow_shouldNotShowSeveralUsersAlert() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let callUseCase = MockCallUseCase()
        let callUpdateUseCase = MockCallUpdateUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: chatRoomUseCase
        )
        
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .inProgress, changeType: .status))
        
        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
        
        callUseCase.callWaitingRoomUsersUpdateSubject.send(CallEntity(changeType: .waitingRoomUsersAllow, waitingRoom: WaitingRoomEntity(sessionClientIds: [100, 101])))

        evaluate {
            self.router.showSeveralUsersWaitingRoomDialog_calledTimes == 0
        }
    }
    
    @MainActor
    func testCallUpdate_oneUserOnWaitingRoomAndBeingModeratorAndCallChangeTypeWaitingRoomUsersAllow_shouldNotShowOneUserAlert() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("User name"))
        let callUseCase = MockCallUseCase()
        let callUpdateUseCase = MockCallUpdateUseCase()

        let viewModel = makeMainTabBarCallsViewModel( 
            callUseCase: callUseCase,
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase
        )
        
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .inProgress, changeType: .status))
        
        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
        
        callUseCase.callWaitingRoomUsersUpdateSubject.send(CallEntity(changeType: .waitingRoomUsersAllow, waitingRoom: WaitingRoomEntity(sessionClientIds: [100])))

        evaluate {
            self.router.showOneUserWaitingRoomDialog_calledTimes == 0
        }
    }
    
    @MainActor
    func testCallUpdate_callDestroyedUserIsCallerAndCallUINotVisible_shouldShowUpgradeToProAndTrackEvents() {
        let callUpdateUseCase = MockCallUpdateUseCase()
        let mockTracker = MockTracker()
        
        let viewModel = makeMainTabBarCallsViewModel(
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .standard)),
            accountUseCase: MockAccountUseCase(currentAccountDetails: AccountDetailsEntity.build()),
            tracker: mockTracker
        )
        viewModel.isCallUIVisible = false
        
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .terminatingUserParticipation, changeType: .status, termCodeType: .callDurationLimit, isOwnClientCaller: true))

        evaluate {
            self.router.showUpgradeToProDialog_calledTimes == 1
        }
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [MainTabBarScreenEvent(), UpgradeToProToGetUnlimitedCallsDialogEvent()]
        )
    }
    
    @MainActor
    func testCallUpdate_callDestroyedUserIsCallerAndCallUIVisible_shouldNotShowUpgradeToPro() {
        let callUpdateUseCase = MockCallUpdateUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .standard)),
            accountUseCase: MockAccountUseCase(currentAccountDetails: AccountDetailsEntity.build())
        )
        viewModel.isCallUIVisible = true
        
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .terminatingUserParticipation, changeType: .status, termCodeType: .callDurationLimit, isOwnClientCaller: true))

        evaluate {
            self.router.showUpgradeToProDialog_calledTimes == 0
        }
    }
    
    @MainActor
    func testCallUpdate_callDestroyedUserIsNotCaller_shouldNotShowUpgradeToPro() {
        let callUpdateUseCase = MockCallUpdateUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .standard)),
            accountUseCase: MockAccountUseCase(currentAccountDetails: AccountDetailsEntity.build())
        )
        viewModel.isCallUIVisible = false
        
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .terminatingUserParticipation, changeType: .status, termCodeType: .callDurationLimit))

        evaluate {
            self.router.showUpgradeToProDialog_calledTimes == 0
        }
    }

    @MainActor
    func testTabBarTapEvents_whenInvoked_shouldMatchTheEvents() {
        let mockTracker = MockTracker()

        let viewModel = makeMainTabBarCallsViewModel(tracker: mockTracker)

        viewModel.dispatch(.didTapCloudDriveTab)
        viewModel.dispatch(.didTapChatRoomsTab)
        viewModel.dispatch(.didTapMenuTab)
        viewModel.dispatch(.didTapPhotosTab)
        viewModel.dispatch(.didTapHomeTab)

        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [
                CloudDriveBottomNavigationItemEvent(),
                ChatRoomsBottomNavigationItemEvent(),
                MenuBottomNavigationItemEvent(),
                PhotosBottomNavigationItemEvent(),
                HomeBottomNavigationItemEvent()
            ]
        )
    }

    @MainActor
    func testCallUpdate_callPlusWaitingRoomExceedLimit_AdmitButtonDisabled() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true), peerPrivilege: .standard)
        let userUseCase = MockChatRoomUserUseCase(userDisplayNameForPeerResult: .success("User name"))
        let callUseCase = MockCallUseCase()
        let callUpdateUseCase = MockCallUpdateUseCase()

        let viewModel = makeMainTabBarCallsViewModel(
            callUseCase: callUseCase,
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: userUseCase
        )
        
        callUpdateUseCase.sendCallUpdate(CallEntity(status: .inProgress, changeType: .status))
        
        evaluate {
            viewModel.callWaitingRoomUsersUpdateSubscription != nil
        }
        
        callUseCase.callWaitingRoomUsersUpdateSubject.send(
            CallEntity(
                callLimits: .init(durationLimit: -1, maxUsers: 3, maxClientsPerUser: -1, maxClients: -1),
                numberOfParticipants: 3,
                waitingRoom: WaitingRoomEntity(sessionClientIds: [100, 101])
            )
        )
        
        evaluate {
            self.router.showSeveralUsersWaitingRoomDialog_calledTimes == 1
        }
        evaluate {
            self.router.shouldBlockAddingUsersToCall_received == [true]
        }
    }
    
    @MainActor
    func test_didTapCloudDriveTab_tracksAnalyticsEvent() {
        trackAnalyticsEventTest(
            action: .didTapCloudDriveTab,
            expectedEvent: CloudDriveBottomNavigationItemEvent()
        )
    }
    
    @MainActor
    func test_didTapChatRoomsTab_tracksAnalyticsEvent() {
        trackAnalyticsEventTest(
            action: .didTapChatRoomsTab,
            expectedEvent: ChatRoomsBottomNavigationItemEvent()
        )
    }
    
    // MARK: - Private methods
    
    private func evaluate(expression: @escaping () -> Bool) {
        let predicate = NSPredicate { _, _ in expression() }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [expectation], timeout: 5)
    }
    
    @MainActor
    private func makeMainTabBarCallsViewModel(
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        callUseCase: some CallUseCaseProtocol =  MockCallUseCase(),
        callUpdateUseCase: some CallUpdateUseCaseProtocol = MockCallUpdateUseCase(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol = MockChatRoomUserUseCase(),
        sessionUpdateUseCase: some SessionUpdateUseCaseProtocol = MockSessionUpdateUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        handleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        callController: some CallControllerProtocol = MockCallController(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
        tracker: some AnalyticsTracking = MockTracker()
    ) -> MainTabBarCallsViewModel {
        MainTabBarCallsViewModel(
            router: router,
            chatUseCase: chatUseCase,
            callUseCase: callUseCase,
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            sessionUpdateUseCase: sessionUpdateUseCase,
            accountUseCase: accountUseCase,
            handleUseCase: handleUseCase,
            callController: callController,
            callUpdateFactory: CXCallUpdateFactory(builder: { CXCallUpdate() }),
            featureFlagProvider: featureFlagProvider,
            tracker: tracker
        )
    }
    
    @MainActor
    private func trackAnalyticsEventTest(
        action: MainTabBarCallsAction,
        expectedEvent: some EventIdentifier
    ) {
        let mockTracker = MockTracker()
        let sut = makeMainTabBarCallsViewModel(tracker: mockTracker)
        
        sut.dispatch(action)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [expectedEvent]
        )
    }
}

final class MockMainTabBarCallsRouter: MainTabBarCallsRouting {
    
    var showOneUserWaitingRoomDialog_calledTimes = 0
    var showSeveralUsersWaitingRoomDialog_calledTimes = 0
    var dismissWaitingRoomDialog_calledTimes = 0
    var showConfirmDenyAction_calledTimes = 0
    var showParticipantsJoinedTheCall_calledTimes = 0
    var showWaitingRoomListFor_calledTimes = 0
    var showScreenRecordingAlert_calledTimes = 0
    var showScreenRecordingNotification_calledTimes = 0
    var navigateToPrivacyPolice_calledTimes = 0
    var dismissCallUI_calledTimes = 0
    var showCallWillEndAlert_calledTimes = 0
    var showUpgradeToProDialog_calledTimes = 0
    var startCallUI_calledTimes = 0
    var shouldBlockAddingUsersToCall_received = [Bool]()

    nonisolated init() { }
    
    func showOneUserWaitingRoomDialog(
        for username: String,
        chatName: String,
        isCallUIVisible: Bool,
        shouldUpdateDialog: Bool,
        shouldBlockAddingUsersToCall: Bool,
        admitAction: @escaping () -> Void,
        denyAction: @escaping () -> Void
    ) {
        shouldBlockAddingUsersToCall_received.append(shouldBlockAddingUsersToCall)
        showOneUserWaitingRoomDialog_calledTimes += 1
    }

    func showSeveralUsersWaitingRoomDialog(
        for participantsCount: Int,
        chatName: String,
        isCallUIVisible: Bool,
        shouldUpdateDialog: Bool,
        shouldBlockAddingUsersToCall: Bool,
        admitAction: @escaping () -> Void,
        seeWaitingRoomAction: @escaping () -> Void
    ) {
        shouldBlockAddingUsersToCall_received.append(shouldBlockAddingUsersToCall)
        showSeveralUsersWaitingRoomDialog_calledTimes += 1
    }
    
    func dismissWaitingRoomDialog(animated: Bool) {
        dismissWaitingRoomDialog_calledTimes += 1
    }

    func showConfirmDenyAction(for username: String, isCallUIVisible: Bool, confirmDenyAction: @escaping () -> Void, cancelDenyAction: @escaping () -> Void) {
        showConfirmDenyAction_calledTimes += 1
    }
    
    func showParticipantsJoinedTheCall(message: String) {
        showParticipantsJoinedTheCall_calledTimes += 1
    }
    
    func showWaitingRoomListFor(call: CallEntity, in chatRoom: ChatRoomEntity) {
        showWaitingRoomListFor_calledTimes += 1
    }
    
    func showScreenRecordingAlert(isCallUIVisible: Bool, acceptAction: @escaping (Bool) -> Void, learnMoreAction: @escaping () -> Void, leaveCallAction: @escaping () -> Void) {
        showScreenRecordingAlert_calledTimes += 1
    }
    
    func showScreenRecordingNotification(started: Bool, username: String) {
        showScreenRecordingNotification_calledTimes += 1
    }
    
    func navigateToPrivacyPolice() {
        navigateToPrivacyPolice_calledTimes += 1
    }
    
    func dismissCallUI() {
        dismissCallUI_calledTimes += 1
    }
    
    func showCallWillEndAlert(timeToEndCall: Double, isCallUIVisible: Bool) {
        showCallWillEndAlert_calledTimes += 1
    }
    
    func showUpgradeToProDialog(_ account: AccountDetailsEntity) {
        showUpgradeToProDialog_calledTimes += 1
    }
    
    func startCallUI(chatRoom: ChatRoomEntity, call: CallEntity, isSpeakerEnabled: Bool) {
        startCallUI_calledTimes += 1
    }
}
