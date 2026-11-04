import SwiftUI
import SwiftData
import SpeedTalkCore

struct PracticeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    let phrase: Phrase
    let onFinished: (Int) -> Void

    @State private var vm: PracticeViewModel?
    @State private var manualText = ""
    @State private var showManual = false
    @State private var showAIReview = false

    var body: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text(phrase.en)
                    .font(.phraseSmall)
                    .fixedSize(horizontal: false, vertical: true)
                Text(phrase.zh).font(.subheadline).foregroundStyle(.secondary)
                PhraseAudioBar(phrase: phrase)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            if let report = vm?.report {
                ScrollView {
                    VStack(spacing: 12) {
                        ScoreResultView(
                            report: report,
                            onRetry: { vm?.reset() },
                            onNext: {
                                save(score: report.score)
                                onFinished(report.score)
                                dismiss()
                            }
                        )
                        Button {
                            showAIReview = true
                        } label: {
                            Label("AI 精细点评", systemImage: "sparkles")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .foregroundStyle(Theme.accent)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                }
            } else {
                Spacer()
                recordButton
                if let message = vm?.errorMessage {
                    Text(message).font(.footnote).foregroundStyle(Theme.danger)
                }
                Button("打不了字？用键盘跟读") { showManual = true }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(20)
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
        .background(Theme.paper.ignoresSafeArea())
        .navigationTitle("跟读")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAIReview) {
            AIReviewSheet(phrase: phrase, transcript: vm?.transcript ?? "")
        }
        .sheet(isPresented: $showManual) {
            NavigationStack {
                Form {
                    TextField("把你说的写下来", text: $manualText, axis: .vertical)
                        .lineLimit(2...4)
                }
                .navigationTitle("键盘跟读")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("评分") {
                            vm?.useManualInput(manualText)
                            showManual = false
                        }
                    }
                }
            }
            .presentationDetents([.height(240)])
        }
        .task {
            if vm == nil { vm = PracticeViewModel(phrase: phrase) }
            await vm?.prepare()
        }
    }

    private var recordButton: some View {
        let recording = vm?.phase == .recording
        return Text(recording ? "松开结束" : "按住说")
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 26)
            .background(recording ? Theme.danger : Theme.accent, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard vm?.phase != .recording else { return }
                        Task { await vm?.beginRecording() }
                    }
                    .onEnded { _ in
                        vm?.endRecording()
                    }
            )
    }

    private func save(score: Int) {
        let store = ProgressStore(context: modelContext)
        let profile = profiles.first ?? {
            let created = UserProfile()
            modelContext.insert(created)
            return created
        }()
        store.recordAttempt(
            phraseID: phrase.id,
            score: score,
            transcript: vm?.transcript ?? "",
            duration: 0,
            profile: profile
        )
    }
}
