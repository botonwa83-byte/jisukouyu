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

    private var index: Int? { siblings.firstIndex { $0.id == phrase.id } }
    private var hasNext: Bool { index.map { siblings.indices.contains($0 + 1) } ?? false }
    private var hasPrevious: Bool { index.map { $0 > 0 } ?? false }

    var body: some View {
        VStack(spacing: 0) {
            PhraseDetailView(phrase: phrase)
                .gesture(swipe)
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
            .padding(.horizontal, 16)
            .padding(.top, 16)

            if hasNext {
                Button {
                    advance()
                } label: {
                    Label("下一句", systemImage: "chevron.right.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("detailNext")
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .padding(.bottom, 12)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// 详情页左右滑动也能翻到上一句/下一句。
    private var swipe: some Gesture {
        DragGesture(minimumDistance: 40)
            .onEnded { value in
                guard abs(value.translation.width) > 60,
                      abs(value.translation.width) > abs(value.translation.height)
                else { return }
                if value.translation.width < 0 {
                    advance()
                } else {
                    goBack()
                }
            }
    }

    private func advance() {
        guard let index, siblings.indices.contains(index + 1) else { return }
        withAnimation(.snappy) { phrase = siblings[index + 1] }
    }

    private func goBack() {
        guard let index, index > 0 else { return }
        withAnimation(.snappy) { phrase = siblings[index - 1] }
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
