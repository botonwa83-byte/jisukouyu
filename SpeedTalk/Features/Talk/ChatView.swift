import SwiftUI
import SwiftData
import SpeedTalkCore

@Observable
final class ChatViewModel {
    private(set) var messages: [ChatMessage] = []
    private(set) var sending = false
    private(set) var errorMessage: String?

    func seed(_ text: String) {
        guard messages.isEmpty else { return }
        messages.append(ChatMessage(role: .assistant, text: text))
    }

    func appendUser(_ text: String) {
        messages.append(ChatMessage(role: .user, text: text))
    }

    func send(config: AIConfig, scene: TalkScene) async {
        guard !sending else { return }
        sending = true
        errorMessage = nil
        do {
            let reply = try await OpenAIClient().reply(config: config, scene: scene, messages: messages)
            messages.append(ChatMessage(role: .assistant, text: reply))
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "回复失败，再试一次"
        }
        sending = false
    }
}

struct ChatView: View {
    @Query private var profiles: [UserProfile]
    let scene: TalkScene

    @State private var vm = ChatViewModel()
    @State private var recognizer = SpeechRecognizer()
    @State private var draft = ""
    @State private var isRecording = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(vm.messages) { message in
                            bubble(message)
                                .id(message.id)
                        }
                        if vm.sending {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("对方正在回…").font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                        if let error = vm.errorMessage {
                            Text(error).font(.footnote).foregroundStyle(Theme.danger)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: vm.messages.count) {
                    if let last = vm.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Divider()

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    TextField("也可以打字", text: $draft)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(sendDraft)
                    Button("发送", action: sendDraft)
                        .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Text(isRecording ? "松开结束" : "按住说一句")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(isRecording ? Theme.danger : Theme.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                guard !isRecording else { return }
                                Task { await startRecording() }
                            }
                            .onEnded { _ in
                                stopRecording()
                            }
                    )
            }
            .padding(16)
        }
        .background(Theme.paper.ignoresSafeArea())
        .navigationTitle(scene.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            vm.seed(scene.opener)
            await recognizer.requestAuthorization()
        }
    }

    private func bubble(_ message: ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.role == .user ? "你" : "对方")
                .font(.captionLabel)
                .foregroundStyle(.secondary)
            Text(message.text)
                .font(.body)
                .padding(12)
                .background(
                    message.role == .user ? Theme.accent.opacity(0.12) : Color.white,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sendDraft() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        draft = ""
        vm.appendUser(text)
        Task { await send() }
    }

    private func startRecording() async {
        do {
            try recognizer.start()
            isRecording = true
        } catch {
            isRecording = false
        }
    }

    private func stopRecording() {
        guard isRecording else { return }
        let text = recognizer.stop()
        isRecording = false
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        vm.appendUser(text)
        Task { await send() }
    }

    private func send() async {
        guard let profile = profiles.first, let key = KeychainStore.read(), !key.isEmpty else {
            return
        }
        await vm.send(
            config: AIConfig(baseURL: profile.aiBaseURL, model: profile.aiModel, apiKey: key),
            scene: scene
        )
    }
}
