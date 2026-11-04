import SwiftUI
import SwiftData
import SpeedTalkCore

struct PhraseListView: View {
    @Environment(AppContainer.self) private var container
    @Query private var progressList: [PhraseProgress]

    let scene: SpeedTalkCore.Scene?
    let searchText: String

    @State private var onlyFavorites = false

    private var phrases: [Phrase] {
        var base: [Phrase]
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            base = container.content.library.search(searchText)
        } else if let scene {
            base = container.content.library.phrases(scene: scene)
        } else {
            base = container.content.library.all
        }
        if onlyFavorites {
            let favoriteIDs = Set(progressList.filter(\.isFavorite).map(\.phraseID))
            base = base.filter { favoriteIDs.contains($0.id) }
        }
        return base
    }

    var body: some View {
        List {
            Toggle("只看收藏", isOn: $onlyFavorites)
            if phrases.isEmpty {
                Text("这里还没有句子，换一个关键词试试。")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(phrases) { phrase in
                    NavigationLink {
                        PhraseDetailScreen(phrase: phrase)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(phrase.en).font(.subheadline.weight(.medium))
                            Text(phrase.zh).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(scene?.title ?? "搜索")
        .navigationBarTitleDisplayMode(.inline)
    }
}
