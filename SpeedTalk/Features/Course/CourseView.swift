import SwiftUI
import SwiftData
import SpeedTalkCore

struct CourseView: View {
    @Environment(AppContainer.self) private var container
    @Query private var progressList: [PlanProgress]
    @Query private var profiles: [UserProfile]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(container.content.curriculum.plans) { plan in
                        planCard(plan)
                    }
                }
                .padding(20)
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("课表")
        }
    }

    private func planCard(_ plan: Curriculum.Plan) -> some View {
        let progress = progressList.first { $0.planID == plan.id }
        let isActive = (profiles.first?.activePlan ?? "01") == plan.id
        let isReady = plan.stages.isEmpty == false
        return NavigationLink {
            PlanDetailView(plan: plan)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(plan.id).font(.captionLabel).foregroundStyle(.secondary)
                    Text(plan.title).font(.headline)
                    if isActive, isReady { TagChip(text: "在学") }
                    Spacer()
                    if progress?.isCompleted == true {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.positive)
                    }
                }
                Text(plan.subtitle).font(.subheadline).foregroundStyle(.secondary)
                if isReady {
                    ProgressView(value: Double(progress?.completedDays ?? 0), total: 120)
                        .tint(isActive ? Theme.accent : .secondary)
                    Text(progressText(progress))
                        .font(.captionLabel)
                        .foregroundStyle(.secondary)
                } else {
                    Text("内容制作中，先把 01 练顺")
                        .font(.captionLabel)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(18)
            .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func progressText(_ progress: PlanProgress?) -> String {
        guard let progress else { return "还没开始 · 每天 \(profiles.first?.dailyGoal ?? 5) 句" }
        if progress.isCompleted { return "已通关 1800 句" }
        return "\(progress.currentStage) 阶段 · Day \(progress.currentDay) · 已完成 \(progress.completedDays) 天"
    }
}
