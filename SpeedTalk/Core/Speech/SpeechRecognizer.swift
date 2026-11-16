import AVFoundation
import Observation
import Speech

@MainActor
@Observable
final class SpeechRecognizer {
    enum State: Equatable {
        case idle
        case recording
        case processing
        case denied
        case unavailable
    }

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var startedAt: Date?

    private(set) var state: State = .idle
    private(set) var transcript: String = ""
    private(set) var elapsed: TimeInterval = 0
    private var interruptionObserver: NSObjectProtocol?

    var isAvailable: Bool { recognizer?.isAvailable ?? false }

    init() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .began
            else { return }
            Task { @MainActor in self?.handleInterruption() }
        }
    }

    func requestAuthorization() async -> Bool {
        let speechGranted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speechGranted else {
            state = .denied
            return false
        }
        let micGranted = await AVAudioApplication.requestRecordPermission()
        if !micGranted { state = .denied }
        return micGranted
    }

    func start() throws {
        guard let recognizer, recognizer.isAvailable else {
            state = .unavailable
            throw NSError(domain: "SpeechRecognizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "识别服务不可用"])
        }

        transcript = ""
        elapsed = 0
        startedAt = Date.now
        try AudioSessionManager.shared.activateRecording()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        self.request = request

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            input.removeTap(onBus: 0)
            AudioSessionManager.shared.deactivateRecording()
            throw error
        }

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.finishAudio()
                }
            }
        }
        state = .recording
    }

    @discardableResult
    func stop() -> String {
        guard state == .recording else { return transcript }
        elapsed = startedAt.map { Date.now.timeIntervalSince($0) } ?? 0
        state = .processing
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.finish()
        AudioSessionManager.shared.deactivateRecording()
        state = .idle
        return transcript
    }

    /// 识别自己结束（静音超时、出错）时的收尾，同样要还回会话。
    private func finishAudio() {
        let wasRecording = state == .recording
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        elapsed = startedAt.map { Date.now.timeIntervalSince($0) } ?? 0
        state = .idle
        if wasRecording {
            AudioSessionManager.shared.deactivateRecording()
        }
    }

    /// 来电等中断：直接收尾，避免按钮卡在录音态。
    private func handleInterruption() {
        guard state == .recording else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        elapsed = startedAt.map { Date.now.timeIntervalSince($0) } ?? 0
        state = .idle
        AudioSessionManager.shared.deactivateRecording()
    }
}
