import SwiftUI

/// 阶段通关庆祝层：每个 600 句阶段走完时弹出，提示进入下一阶段。
struct StageCompletionView: View {
    @Environment(\.dismiss) private var dismiss

    let planTitle: String
    let stageID: String
    let stageTitle: String
    let dayCount: Int
    let phraseCount: Int
    let averageScore: Int
    let nextStageTitle: String?
    let onContinue: () -> Void

    private let gold = Color(red: 0.72, green: 0.56, blue: 0.26)
    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.paper, Color(red: 0.96, green: 0.94, blue: 0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 8)
                badge
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)
                heading
                metrics
                Spacer(minLength: 0)
                actions
            }
            .padding(24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                appeared = true
            }
        }
    }

    private var badge: some View {
        ZStack {
            Circle()
                .fill(gold.opacity(0.12))
                .frame(width: 96, height: 96)
            Circle()
                .strokeBorder(gold.opacity(0.35), lineWidth: 6)
                .frame(width: 80, height: 80)
            Image(systemName: "flag.checkered")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(gold)
        }
        .accessibilityHidden(true)
    }

    private var heading: some View {
        VStack(spacing: 6) {
            Text("阶 段 通 关")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(6)
                .foregroundStyle(gold)
            Text("\(stageID) 阶段 · \(stageTitle)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("\(planTitle)的 \(dayCount) 天走完了，\(phraseCount) 句都会说了")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var metrics: some View {
        HStack(spacing: 0) {
            metric("句", value: "\(phraseCount)", label: "累计句子")
            Divider().frame(height: 34)
            metric("天", value: "\(dayCount)", label: "课表天数")
            Divider().frame(height: 34)
            metric("分", value: averageScore > 0 ? "\(averageScore)" : "—", label: "本组均分")
        }
        .padding(.vertical, 14)
        .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func metric(_ unit: String, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(unit)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var actions: some View {
        VStack(spacing: 10) {
            PrimaryButton(title: primaryTitle) {
                dismiss()
                onContinue()
            }
            Button {
                dismiss()
            } label: {
                Text("稍后再说")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var primaryTitle: String {
        if let nextStageTitle {
            return "进入下一阶段 · \(nextStageTitle)"
        }
        return "查看通关证书"
    }
}

#Preview {
    StageCompletionView(
        planTitle: "生活生存",
        stageID: "a",
        stageTitle: "吃住行基础",
        dayCount: 120,
        phraseCount: 600,
        averageScore: 86,
        nextStageTitle: "办事与医疗",
        onContinue: {}
    )
}
