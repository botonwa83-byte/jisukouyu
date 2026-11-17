import SwiftUI
import SwiftData
import SpeedTalkCore

struct TalkView: View {
    @Environment(StoreManager.self) private var store
    @Query private var profiles: [UserProfile]

    var body: some View {
        NavigationStack {
            if store.isPremium {
                sceneList
            } else {
                lockedGate
            }
        }
    }

    private var sceneList: some View {
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
        .warmList()
        .centeredColumn()
        .navigationTitle("对练")
    }

    /// 未解锁时的门禁页：讲清楚完整版权益，引导去付费墙。
    private var lockedGate: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.circle")
                .font(.system(size: 56))
                .foregroundStyle(Theme.accent)
            Text("AI 对练是完整版功能")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.ink)
            Text("一次买断，永久解锁 AI 对练、AI 精细点评与全部场景句库。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            NavigationLink {
                PaywallView(feature: "AI 对练")
            } label: {
                Text("查看完整版")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(Theme.paper.ignoresSafeArea())
        .centeredColumn()
        .navigationTitle("对练")
    }
}
