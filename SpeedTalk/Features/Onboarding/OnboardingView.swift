import SwiftUI
import SwiftData
import SpeedTalkCore

struct OnboardingView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var selectedPlan: String = "01"
    @State private var step: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if step == 0 {
                Text("每天 5 句")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("3 分钟，把地道美语练成肌肉记忆。")
                    .foregroundStyle(.secondary)
                Spacer()
                PrimaryButton(title: "选方案") { step = 1 }
            } else {
                Text("选一个方案开始")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("每个方案 1800 句，随时可切换，进度各自保留。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(container.content.curriculum.plans) { plan in
                    let ready = plan.stages.isEmpty == false
                    Button {
                        if ready { selectedPlan = plan.id }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(plan.id) · \(plan.title)").font(.headline)
                                Text(ready ? plan.subtitle : "内容制作中")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if ready {
                                Image(systemName: selectedPlan == plan.id ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(selectedPlan == plan.id ? Theme.accent : .secondary)
                            }
                        }
                        .padding(16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .opacity(ready ? 1 : 0.5)
                    }
                    .buttonStyle(.plain)
                    .disabled(!ready)
                }

                Spacer()
                PrimaryButton(title: "开始第一天", action: start)
            }
        }
        .padding(24)
        .background(Theme.paper.ignoresSafeArea())
    }

    private func start() {
        let profile = profiles.first ?? {
            let created = UserProfile()
            modelContext.insert(created)
            return created
        }()
        profile.activePlan = selectedPlan
        profile.hasOnboarded = true
        let existing = try? modelContext.fetch(FetchDescriptor<PlanProgress>())
        if existing?.first(where: { $0.planID == selectedPlan }) == nil {
            modelContext.insert(PlanProgress(planID: selectedPlan))
        }
        try? modelContext.save()
    }
}
