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
                welcome
            } else {
                planPicker
            }
        }
        .padding(24)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .background(Theme.paper.ignoresSafeArea())
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SPEEDTALK")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(4)
                .foregroundStyle(Theme.accent)
                .padding(.top, 8)

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 10) {
                Text("每天 5 句")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("3 分钟，把地道美语练成肌肉记忆。")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 16) {
                feature("text.bubble", "一句一用的真实句子", "点单、面试、社交，学了当天就能说")
                feature("waveform", "开口就有分", "逐词高亮，卡在哪个词一目了然")
                feature("calendar", "120 天一个阶段", "三个方案各 1800 句，进度各自保留")
            }
            .padding(.top, 32)

            Spacer(minLength: 24)

            VStack(spacing: 12) {
                PrimaryButton(title: "选方案") {
                    withAnimation(.snappy) { step = 1 }
                }
                Text("无需注册 · 录音不出设备")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func feature(_ systemImage: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 34, height: 34)
                .background(Theme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var planPicker: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button {
                withAnimation(.snappy) { step = 0 }
            } label: {
                Label("返回", systemImage: "chevron.left")
                    .font(.captionLabel)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text("选一个方案开始")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("每个方案 1800 句，随时可切换，进度各自保留。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(container.content.curriculum.plans) { plan in
                        planRow(plan)
                    }
                }
                .padding(.vertical, 2)
            }

            PrimaryButton(title: "开始第一天", action: start)
        }
    }

    private func planRow(_ plan: Curriculum.Plan) -> some View {
        let ready = plan.stages.isEmpty == false
        return Button {
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
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        selectedPlan == plan.id ? Theme.accent.opacity(0.5) : Theme.ink.opacity(0.05),
                        lineWidth: 1
                    )
            }
            .opacity(ready ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!ready)
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
