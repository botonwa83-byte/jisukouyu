import AVFoundation
import Observation

@MainActor
@Observable
final class SpeechPlayer: NSObject, AVSpeechSynthesizerDelegate {
    enum Speed: Double, CaseIterable {
        case slow = 0.40
        case normal = 0.50

        var title: String {
            switch self {
            case .slow: return "慢速"
            case .normal: return "常速"
            }
        }
    }

    private let synthesizer = AVSpeechSynthesizer()
    private let session = AudioSessionManager.shared
    private var interruptionObserver: NSObjectProtocol?
    private(set) var isSpeaking = false

    override init() {
        super.init()
        synthesizer.delegate = self
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .began
            else { return }
            Task { @MainActor in self?.stop() }
        }
    }

    /// 播报一句示范音；会话激活失败时返回 false，界面不要显示「正在播」。
    @discardableResult
    func speak(_ text: String, speed: Speed = .normal, language: String = "en-US") -> Bool {
        stop()
        do {
            try session.activatePlayback()
        } catch {
            return false
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = Float(speed.rawValue)
        utterance.pitchMultiplier = 1.0
        isSpeaking = true
        synthesizer.speak(utterance)
        return true
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        finishPlayback()
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.finishPlayback() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.finishPlayback() }
    }

    /// 播完/被打断都要还回会话，否则 `.duckOthers` 会一直压着别的 App。
    private func finishPlayback() {
        isSpeaking = false
        session.deactivatePlayback()
    }
}
