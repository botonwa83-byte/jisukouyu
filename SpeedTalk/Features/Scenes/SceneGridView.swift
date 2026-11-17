import SwiftUI
import SwiftData
import SpeedTalkCore

struct SceneGridView: View {
    @Environment(AppContainer.self) private var container
    @Environment(StoreManager.self) private var store
    @State private var searchText = ""
    @State private var selectedScene: SpeedTalkCore.Scene?
    @State private var showPaywall = false
    @State private var paywallFeature: String?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(SpeedTalkCore.Scene.allCases, id: \.self) { scene in
                                Button {
                                    open(scene)
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: scene.symbol)
                                                .font(.title3)
                                                .foregroundStyle(tint(for: scene))
                                            Spacer()
                                            if isLocked(scene) {
                                                Image(systemName: "lock.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(Theme.accent)
                                            }
                                        }
                                        Text(scene.title).font(.headline)
                                        Text("\(container.content.library.phrases(scene: scene).count) 句")
                                            .font(.captionLabel)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
            .navigationDestination(item: $selectedScene) { scene in
                PhraseListView(scene: scene, searchText: "")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(feature: paywallFeature)
            }
        }
    }

    /// 免费版只开放「生活」场景，其余需完整版。
    private func isLocked(_ scene: SpeedTalkCore.Scene) -> Bool {
        scene != .life && !store.isPremium
    }

    private func open(_ scene: SpeedTalkCore.Scene) {
        if isLocked(scene) {
            paywallFeature = scene.title
            showPaywall = true
        } else {
            selectedScene = scene
        }
    }

    private func tint(for scene: SpeedTalkCore.Scene) -> Color {
        let palette: [Color] = [Theme.accent, Theme.blush, Theme.positive, Theme.warning]
        let index = SpeedTalkCore.Scene.allCases.firstIndex(of: scene) ?? 0
        return palette[index % palette.count]
    }
}
