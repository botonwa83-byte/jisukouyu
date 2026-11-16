import SwiftUI
import SwiftData
import SpeedTalkCore

struct PhraseDetailScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressList: [PhraseProgress]

    @State private var phrase: Phrase
    /// 同一来源的句子序列，用于「下一句」按列表顺序推进。
    private let siblings: [Phrase]

    init(phrase: Phrase, siblings: [Phrase] = []) {
        _phrase = State(initialValue: phrase)
        self.siblings = siblings
    }

    private var progress: PhraseProgress? { progressList.first { $0.phraseID == phrase.id } }

    var body: some View {
        VStack(spacing: 0) {
            PhraseDetailView(phrase: phrase)
            HStack(spacing: 12) {
                Button {
                    toggleFavorite()
                } label: {
                    Label(
                        progress?.isFavorite == true ? "已收藏" : "收藏",
                        systemImage: progress?.isFavorite == true ? "star.fill" : "star"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                NavigationLink {
                    PracticeView(
                        phrase: phrase,
                        onScore: { _ in },
                        nextPhrase: {
                            guard let index = siblings.firstIndex(where: { $0.id == phrase.id }),
                                  siblings.indices.contains(index + 1)
                            else { return nil }
                            return siblings[index + 1]
                        },
                        onPhraseChange: { phrase = $0 }
                    )
                } label: {
                    Text("练这一句")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggleFavorite() {
        if let existing = progress {
            existing.isFavorite.toggle()
        } else {
            let created = PhraseProgress(phraseID: phrase.id)
            created.isFavorite = true
            modelContext.insert(created)
        }
        try? modelContext.save()
    }
}
