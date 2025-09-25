@testable import MEGA
import MEGAAppPresentation
import MEGADomain

final class MockAudioPlayerHandler: AudioPlayerHandlerProtocol {
    var goBackward_calledTimes = 0
    var playPrevious_calledTimes = 0
    var togglePlay_calledTimes = 0
    var pause_calledTimes = 0
    var play_calledTimes = 0
    var playNext_calledTimes = 0
    var goForward_calledTimes = 0
    var updateProgressCompleted_calledTimes = 0
    var onShuffle_calledTimes = 0
    var isSingleItemPlaylist_calledTimes = 0
    var onRepeatAll_calledTimes = 0
    var onRepeatOne_calledTimes = 0
    var onRepeatDisabled_calledTimes = 0
    var onMoveItem_calledTimes = 0
    var onDeleteItems_calledTimes = 0
    var addPlayer_calledTimes = 0
    var addPlayerTracks_calledTimes = 0 {
        didSet {
            onAddPlayerTracksCompletion?()
        }
    }
    var addPlayerListener_calledTimes = 0
    var removePlayerListener_calledTimes = 0
    var playItem_calledTimes = 0
    var changePlayerRate_calledTimes = 0
    var setCurrent_callTimes = 0
    var initMiniPlayerCallCount = 0
    var refreshCurrentItemState_calledTimes = 0
    var closePlayer_calledTimes = 0
    var resettingAudioPlayer_calledTimes = 0
    var repeatMode = RepeatMode.none
    var shuffle = false
    
    var onAddPlayerTracksCompletion: (() -> Void)?
    var onAddPlayerListenerCompletion: (() -> Void)?
    var onRefreshCurrentItemStateCompletion: (() -> Void)?
    var onPlayerResumePlaybackCompletion: (() -> Void)?
    var mockPlayerCurrentItem: AudioPlayerItem = AudioPlayerItem.mockItem
    var mockPlayerQueueItems: [AudioPlayerItem]?
    
    private var _isPlayerDefined: Bool
    private var _isSingleItemPlaylist: Bool
    
    private(set) var playerResumePlayback_Calls = [TimeInterval]()
    
    init(isPlayerDefined: Bool = false, isSingleItemPlaylist: Bool = false) {
        _isPlayerDefined = isPlayerDefined
        _isSingleItemPlaylist = isSingleItemPlaylist
    }
    
    func isPlayerDefined() -> Bool { _isPlayerDefined }
    func isPlayerEmpty() -> Bool { false }
    
    func currentPlayer() -> AudioPlayer? {
        AudioPlayer()
    }
    
    func setCurrent(
        player: AudioPlayer?,
        tracks: [AudioPlayerItem],
        playerListener: any AudioPlayerObserversProtocol
    ) {
        addPlayer_calledTimes += 1
        addPlayerTracks_calledTimes += 1
        _isPlayerDefined = true
    }
    
    func configurePlayer(listener: any AudioPlayerObserversProtocol) {
        addPlayerListener_calledTimes += 1
        onAddPlayerListenerCompletion?()
    }
    
    func removePlayer(listener: any AudioPlayerObserversProtocol) {
        removePlayerListener_calledTimes += 1
    }
    
    func addPlayer(tracks: [AudioPlayerItem]) {
        addPlayerTracks_calledTimes += 1
    }
    
    func move(item: AudioPlayerItem, to position: IndexPath, direction: MovementDirection) {
        onMoveItem_calledTimes += 1
    }
    
    func delete(items: [AudioPlayerItem]) async {
        onDeleteItems_calledTimes += 1
    }
    
    func playerProgressCompleted(percentage: Float) {
        updateProgressCompleted_calledTimes += 1
    }
    
    func playerResumePlayback(from timeInterval: TimeInterval) {
        playerResumePlayback_Calls.append(timeInterval)
        onPlayerResumePlaybackCompletion?()
    }
    
    func playerShuffle(active: Bool) {
        shuffle = active
        onShuffle_calledTimes += 1
    }
    
    func isSingleItemPlaylist() -> Bool {
        _isSingleItemPlaylist
    }
    
    func goBackward() {
        goBackward_calledTimes += 1
    }
   
    func playPrevious() {
        playPrevious_calledTimes += 1
    }
    
    func playerTogglePlay() {
        togglePlay_calledTimes += 1
    }
    
    func playerPause() {
        pause_calledTimes += 1
    }
    
    func playerPlay() {
        play_calledTimes += 1
    }
    
    func playNext() {
        playNext_calledTimes += 1
    }
    
    func goForward() {
        goForward_calledTimes += 1
    }
    
    func play(item: AudioPlayerItem) {
        playItem_calledTimes += 1
    }
    
    func playerRepeatAll(active: Bool) {
        onRepeatAll_calledTimes += 1
    }
    
    func playerRepeatOne(active: Bool) {
        onRepeatOne_calledTimes += 1
    }
    
    func playerRepeatDisabled() {
        onRepeatDisabled_calledTimes += 1
    }
    
    func changePlayer(speed: SpeedMode) {
        changePlayerRate_calledTimes += 1
    }
    
    func playerCurrentItem() -> AudioPlayerItem? { mockPlayerCurrentItem }
    func playerCurrentItemTime() -> TimeInterval { 0.0 }
    func playerQueueItems() -> [AudioPlayerItem]? { mockPlayerQueueItems }
    func playerPlaylistItems() -> [AudioPlayerItem]? { nil}
    func initMiniPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController, shouldReloadPlayerInfo: Bool, shouldResetPlayer: Bool, isFromSharedItem: Bool) {
        initMiniPlayerCallCount += 1
    }
    func initFullScreenPlayer(node: MEGANode?, fileLink: String?, filePaths: [String]?, isFolderLink: Bool, presenter: UIViewController, messageId: HandleEntity, chatId: HandleEntity, isFromSharedItem: Bool, allNodes: [MEGANode]?) {}
    func playerHidden(_ hidden: Bool, presenter: UIViewController) {}
    func closePlayer() {
        closePlayer_calledTimes += 1
    }
    func presentMiniPlayer(_ viewController: UIViewController) {}
    func isPlayerPlaying() -> Bool { true }
    func isPlayerPaused() -> Bool { false }
    func isPlayerAlive() -> Bool { true }
    func updateMiniPlayerPresenter(_ presenter: any AudioPlayerPresenterProtocol) {}
    func addMiniPlayerHandler(_ handler: any AudioMiniPlayerHandlerProtocol) {}
    func removeMiniPlayerHandler(_ handler: any AudioMiniPlayerHandlerProtocol) {}
    func isShuffleEnabled() -> Bool { shuffle }
    func currentRepeatMode() -> RepeatMode { repeatMode }
    func refreshCurrentItemState() {
        refreshCurrentItemState_calledTimes += 1
        onRefreshCurrentItemStateCompletion?()
    }
    func audioInterruptionDidStart() {}
    func audioInterruptionDidEndNeedToResume(_ resume: Bool) {}
    func remoteCommandEnabled(_ enabled: Bool) {}
    func resetAudioPlayerConfiguration() {}
    func refreshContentOffset(presenter: any AudioPlayerPresenterProtocol, isHidden: Bool) {}
    func playerTracksContains(url: URL) -> Bool { true }
    func upcomingPlaylistItems() -> [AudioPlayerItem] { mockPlayerQueueItems ?? [] }
    func resetCurrentItem(shouldResetPlayback: Bool) {
        setCurrent_callTimes += 1
    }
    func currentSpeedMode() -> SpeedMode { .normal }
    
    @MainActor func dismissFullScreenPlayer() async {}
    
    func resettingAudioPlayer(shouldResetPlayback: Bool) {
        resettingAudioPlayer_calledTimes += 1
    }
}

extension MockAudioPlayerHandler {
    func setCurrentRepeatMode(_ repeatMode: RepeatMode) {
        self.repeatMode = repeatMode
    }
}
