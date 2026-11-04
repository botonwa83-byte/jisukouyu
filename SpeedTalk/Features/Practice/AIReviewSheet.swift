import SwiftUI
import SwiftData
import SpeedTalkCore

struct AIReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    let phrase: Phrase
    let transcript: String

    @State private var review: PronunciationReview?
    @State private var message = "正在听你的发音…"
    @State private var loading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let review {
                        Text(review.summary)
                            .font(.headline)
                        if review.tips.isEmpty == false {
                            block("要点") {
                                ForEach(review.tips, id: \.self) { tip in
                                    Label(tip, systemImage: "waveform")
                                        .font(.subheadline)
                                }
                            }
                        }
                        if review.wordIssues.isEmpty == false {
                            block("逐词") {
                                ForEach(review.wordIssues, id: \.self) { issue in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(issue.word).font(.subheadline.weight(.semibold))
                                        Text(issue.issue).font(.footnote).foregroundStyle(Theme.danger)
                                        Text(issue.fix).font(.footnote).foregroundStyle(Theme.positive)
                                    }
                                }
                            }
                        }
                        if review.betterSayings.isEmpty == false {
                            block("更地道") {
                                ForEach(review.betterSayings, id: \.self) { saying in
                                    Text(saying).font(.subheadline)
                                }
                            }
                        }
                    } else {
                        HStack(spacing: 10) {
                            if loading { ProgressView() }
                            Text(message).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("AI 精细点评")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("知道了") { dismiss() }
                }
            }
            .task { await request() }
        }
    }

    private func block(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.captionLabel).foregroundStyle(.secondary)
            content()
        }
    }

    private func request() async {
        guard let profile = profiles.first else {
            message = "先完成一次打卡，再来点评"
            loading = false
            return
        }
        if profile.aiQuotaUsed >= profile.aiQuotaPerDay,
           Calendar.current.isDate(profile.aiQuotaDate ?? .distantPast, inSameDayAs: Date.now) {
            message = "今天的 AI 额度用完了，明天再来"
            loading = false
            return
        }
        guard let key = KeychainStore.read(), !key.isEmpty else {
            message = "还没填 API Key，去「我的 · 设置 · AI 设置」填一下"
            loading = false
            return
        }

        let config = AIConfig(baseURL: profile.aiBaseURL, model: profile.aiModel, apiKey: key)
        do {
            let result = try await OpenAIClient().review(
                config: config,
                target: phrase.en,
                transcript: transcript,
                ipa: phrase.pronunciation.ipa
            )
            review = result
            if Calendar.current.isDate(profile.aiQuotaDate ?? .distantPast, inSameDayAs: Date.now) {
                profile.aiQuotaUsed += 1
            } else {
                profile.aiQuotaUsed = 1
            }
            profile.aiQuotaDate = Date.now
            try? modelContext.save()
        } catch {
            message = (error as? LocalizedError)?.errorDescription ?? "点评失败，稍后再试"
        }
        loading = false
    }
}
