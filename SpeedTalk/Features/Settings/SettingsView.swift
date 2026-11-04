import SwiftUI
import SwiftData
import SpeedTalkCore

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        Form {
            Section("学习") {
                Picker("每天", selection: goalBinding) {
                    Text("5 句 · 3 分钟").tag(5)
                    Text("10 句 · 加速档").tag(10)
                }
                VStack(alignment: .leading) {
                    Text("示范语速")
                        .font(.subheadline)
                    Slider(value: speechRateBinding, in: 0.38...0.55, step: 0.01)
                }
            }

            Section("提醒") {
                NavigationLink("每日提醒") { NotificationSettingsView() }
            }

            Section("AI") {
                Text("AI 纠音与对练在下一步接入，填好 Key 即可用。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("数据") {
                Text("录音不保存，学习记录只在本机。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("设置")
    }

    private var goalBinding: Binding<Int> {
        Binding(
            get: { profile?.dailyGoal ?? 5 },
            set: {
                profile?.dailyGoal = $0
                try? modelContext.save()
            }
        )
    }

    private var speechRateBinding: Binding<Double> {
        Binding(
            get: { profile?.speechRate ?? 0.48 },
            set: {
                profile?.speechRate = $0
                try? modelContext.save()
            }
        )
    }
}
