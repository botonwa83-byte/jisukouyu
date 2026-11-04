import SwiftUI
import SwiftData
import SpeedTalkCore

struct ReviewQueueView: View {
    @Environment(AppContainer.self) private var container
    @Query private var progressList: [PhraseProgress]

    private var duePhrases: [Phrase] {
        progressList
            .filter { ($0.nextReviewAt ?? .distantPast) <= Date.now }
            .sorted { ($0.nextReviewAt ?? .distantPast) < ($1.nextReviewAt ?? .distantPast) }
            .prefix(5)
            .compactMap { container.content.library.phrase(id: $0.phraseID) }
    }

    var body: some View {
        List {
            if duePhrases.isEmpty {
                Text("今天没有到期复习，去学新句子。")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(duePhrases) { phrase in
                    NavigationLink {
                        PracticeView(phrase: phrase, onFinished: { _ in })
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(phrase.en).font(.subheadline.weight(.medium))
                            Text(phrase.zh).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("复习")
    }
}
