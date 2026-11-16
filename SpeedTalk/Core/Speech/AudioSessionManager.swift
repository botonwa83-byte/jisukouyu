import AVFoundation

/// 统一管理音频会话。
///
/// 录音与播放各自引用计数：所有使用者释放后才真正 `setActive(false)`，
/// 避免「识别收尾」与「播报开始」互相抢会话导致静音或引擎报错。
final class AudioSessionManager {
    static let shared = AudioSessionManager()

    private let session = AVAudioSession.sharedInstance()
    private var recordingCount = 0
    private var playbackCount = 0

    private init() {}

    // MARK: - 录音

    /// 进入录音：支持蓝牙耳麦（HFP）、外放播报、压低其他 App 音量。
    func activateRecording() throws {
        recordingCount += 1
        applyRecordingConfig()
        try activate()
    }

    /// 退出录音；播报仍在进行时只回落到录音配置，不关闭会话。
    func deactivateRecording() {
        guard recordingCount > 0 else { return }
        recordingCount -= 1
        releaseIfIdle()
    }

    // MARK: - 播放

    /// 进入播报：音频模式，压低其他 App。
    func activatePlayback() throws {
        playbackCount += 1
        applyPlaybackConfig()
        try activate()
    }

    /// 退出播报；录音仍在进行时保留会话并回到录音配置。
    func deactivatePlayback() {
        guard playbackCount > 0 else { return }
        playbackCount -= 1
        releaseIfIdle()
    }

    /// 强制释放全部会话（切后台、来电等场景的兜底）。
    func deactivate() {
        recordingCount = 0
        playbackCount = 0
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - 内部

    private func releaseIfIdle() {
        if recordingCount > 0 {
            applyRecordingConfig()
            return
        }
        if playbackCount > 0 {
            applyPlaybackConfig()
            return
        }
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func applyRecordingConfig() {
        try? session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.allowBluetooth, .defaultToSpeaker, .duckOthers]
        )
    }

    private func applyPlaybackConfig() {
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }

    private func activate() throws {
        // `notifyOthersOnDeactivation` 只在 deactivate 时才有意义。
        try session.setActive(true)
    }
}
