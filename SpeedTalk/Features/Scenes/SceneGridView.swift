import SwiftUI
import SwiftData
import SpeedTalkCore

struct SceneGridView: View {
    @Environment(AppContainer.self) private var container
    @State private var searchText = ""

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(SpeedTalkCore.Scene.allCases, id: \.self) { scene in
                                NavigationLink {
                                    PhraseListView(scene: scene, searchText: "")
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Image(systemName: scene.symbol).font(.title3)
                                        Text(scene.title).font(.headline)
                                        Text("\(container.content.library.phrases(scene: scene).count) 句")
                                            .font(.captionLabel)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(20)
                    }
                } else {
                    PhraseListView(scene: nil, searchText: searchText)
                }
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("场景")
            .searchable(text: $searchText, prompt: "搜英文、中文或标签")
        }
    }
}
