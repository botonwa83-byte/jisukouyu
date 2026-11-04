import SwiftUI
import SwiftData
import SpeedTalkCore

struct TalkView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("选一个场景，用英语开口。AI 扮演对方，回你话并顺带纠一句。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section("场景") {
                    ForEach(TalkScene.allCases) { scene in
                        NavigationLink {
                            ChatView(scene: scene)
                        } label: {
                            Label(scene.title, systemImage: scene.symbol)
                        }
                    }
                }
                if KeychainStore.read()?.isEmpty ?? true {
                    Section {
                        Text("还没填 API Key，对练需要它。去「我的 · 设置 · AI 设置」。")
                            .font(.footnote)
                            .foregroundStyle(Theme.warning)
                    }
                }
            }
            .navigationTitle("对练")
        }
    }
}
