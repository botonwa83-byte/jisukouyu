import Foundation
import Observation
import SpeedTalkCore

@MainActor
@Observable
final class PracticeViewModel {
    enum Phase: Equatable {
        case idle
        case recording
        case scoring
        case result
        case denied
        case unavailable
    }

    let phrase: Phrase
    private let recognizer = SpeechRecognizer()
    private(set) var phase: Phase = .idle
    private(set) var report: ScoreReport?
    private(set) var transcript: String = ""
    private(set) var errorMessage: String?

    init(phrase: Phrase) {
        self.phrase = phrase
    }

    func prepare() async {
        let granted = await recognizer.requestAuthorization()
        if !granted { phase = .denied }
    }

    func beginRecording() async {
        guard phase != .recording else { return }
        errorMessage = nil
        report = nil
        do {
            try recognizer.start()
            phase = .recording
        } catch {
            phase = .unavailable
            errorMessage = "识别没起来，检查麦克风权限后再试"
        }
    }

    func endRecording() {
        let text = recognizer.stop()
        transcript = text
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "没听清，靠近一点再来一次"
            phase = .idle
            return
        }
        let seconds = max(recognizer.elapsed, 0.6)
        report = LocalScorer.score(expected: phrase.en, actual: text, duration: seconds)
        phase = .result
    }

    func useManualInput(_ text: String) {
        transcript = text
        let seconds = max(Double(text.split(separator: " ").count) / 2.8, 0.8)
        report = LocalScorer.score(expected: phrase.en, actual: text, duration: seconds)
        phase = .result
    }

    func reset() {
        report = nil
        errorMessage = nil
        phase = .idle
    }
}
