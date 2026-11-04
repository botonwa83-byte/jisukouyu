import SwiftUI
import SwiftData
import SpeedTalkCore

struct MeView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var planProgress: [PlanProgress]
    @Query private var phraseProgress: [PhraseProgress]
    @Query private var achievements: [AchievementRecord]

    private var mastered: Int { phraseProgress.filter { $0.masteryLevel >= 4 }.count }
    private var finishedPlans: Int { planProgress.filter(\.isCompleted).count }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 18) {
                        stat("\(profiles.first?.streak ?? 0)", "连续打卡")
                        stat("\(mastered)", "已掌握")
                        stat("\(planProgress.reduce(0) { $0 + $1.completedDays })", "学习天")
                    }
                    .padding(.vertical, 6)
                }

                Section("方案进度") {
                    if planProgress.isEmpty {
                        Text("还没开始，去今日学第一组。")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(planProgress.sorted { $0.planID < $1.planID }) { progress in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("\(progress.planID) · \(container.content.curriculum.plan(id: progress.planID)?.title ?? "")")
                                    Spacer()
                                    Text(progress.isCompleted ? "已通关" : "\(progress.currentStage) · Day \(progress.currentDay)")
                                        .font(.captionLabel)
                                        .foregroundStyle(.secondary)
                                }
                                SwiftUI.ProgressView(value: Double(progress.completedDays), total: 120)
                                    .tint(Theme.accent)
                            }
                        }
                    }
                }

                Section("复习") {
                    NavigationLink {
                        ReviewQueueView()
                    } label: {
                        Label("到期复习 \(dueCount) 句", systemImage: "arrow.clockwise")
                    }
                }

                Section("成就") {
                    AchievementWall()
                }

                Section {
                    NavigationLink("设置") { SettingsView() }
                    NavigationLink("隐私说明") { PrivacyView() }
                }
            }
            .navigationTitle("我的")
            .task { refreshAchievements() }
        }
    }

    private var dueCount: Int {
        phraseProgress.filter { ($0.nextReviewAt ?? .distantPast) <= Date.now }.count
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 26, weight: .bold, design: .rounded))
            Text(label).font(.captionLabel).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func refreshAchievements() {
        let unlocked = Set(AchievementCatalog.unlocked(
            totalMastered: mastered,
            streak: profiles.first?.streak ?? 0,
            finishedPlanCount: finishedPlans
        ))
        let existing = Set(achievements.map(\.achievementID))
        for id in unlocked.subtracting(existing) {
            modelContext.insert(AchievementRecord(achievementID: id))
        }
        try? modelContext.save()
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("录音只用在本机评分").font(.headline)
                Text("跟读录音仅存放在临时目录，评分完成后立即删除，不会上传。")
                Text("发给 AI 的只有文字").font(.headline)
                Text("AI 纠音与对练只发送句子文本和你说的文字，不发送音频。")
                Text("API Key 存在钥匙串").font(.headline)
                Text("Key 只保存在系统钥匙串，不写入日志、不随备份上传。")
            }
            .font(.subheadline)
            .padding(20)
        }
        .navigationTitle("隐私说明")
    }
}
