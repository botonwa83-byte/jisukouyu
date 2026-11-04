import SwiftUI
import SpeedTalkCore

/// 方案通关证书：完成某个方案的 c 阶段后展示，也可从课表随时回看。
struct PlanCertificateView: View {
    @Environment(\.dismiss) private var dismiss

    let planID: String
    let title: String
    let subtitle: String
    let totalDays: Int
    let totalPhrases: Int
    let masteredCount: Int
    let streak: Int
    let finishedAt: Date?

    private let gold = Color(red: 0.72, green: 0.56, blue: 0.26)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.paper, Color(red: 0.95, green: 0.93, blue: 0.87)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    certificate
                    ShareLink(item: shareText, subject: Text("我的 \(title) 通关证书")) {
                        Label("分享这份成绩", systemImage: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(gold.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(gold)
                    }
                    Button {
                        dismiss()
                    } label: {
                        Text("收起证书")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var certificate: some View {
        VStack(spacing: 16) {
            HStack {
                Text("SPEEDTALK")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(gold)
                Spacer()
                Text("NO. \(certificateNumber)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            seal
                .padding(.top, 4)

            VStack(spacing: 6) {
                Text("通 关 证 书")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .tracking(8)
                    .foregroundStyle(gold)
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("已完成全部 \(String(totalPhrases)) 句 · \(String(totalDays)) 天课表")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.75))

            Rectangle()
                .fill(gold.opacity(0.25))
                .frame(height: 1)
                .padding(.vertical, 2)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                metric("总句数", "\(totalPhrases)", "句")
                metric("学习天", "\(totalDays)", "天")
                metric("已掌握", "\(masteredCount)", "句")
                metric("连续打卡", "\(streak)", "天")
            }

            VStack(spacing: 4) {
                Text(finishedLine)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.8))
                Text("说得出，才算真的学会")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(22)
        .background(.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(gold.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: Theme.ink.opacity(0.08), radius: 24, y: 12)
    }

    private var seal: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [gold.opacity(0.16), gold.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 104, height: 104)
            Circle()
                .strokeBorder(gold.opacity(0.25), lineWidth: 8)
                .frame(width: 92, height: 92)
            Circle()
                .strokeBorder(gold, lineWidth: 1.5)
                .frame(width: 74, height: 74)
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(gold)
        }
        .accessibilityHidden(true)
    }

    private func metric(_ label: String, _ value: String, _ unit: String) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(unit)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var certificateNumber: String {
        let year = Calendar.current.component(.year, from: finishedAt ?? .now)
        return "ST\(planID)-\(year)"
    }

    private var finishedLine: String {
        guard let finishedAt else { return "旧记录 · 通关日期未记录" }
        let date = finishedAt.formatted(
            .dateTime.year().month().day().locale(Locale(identifier: "zh_CN"))
        )
        return "通关于 \(date)"
    }

    private var shareText: String {
        "我在 SpeedTalk 学完了《\(title)》\(totalPhrases) 句，连续打卡 \(streak) 天。说得出，才算真的学会。"
    }
}

#Preview {
    PlanCertificateView(
        planID: "01",
        title: "生存英语",
        subtitle: "先能活下来：点单、问路、购物、救急",
        totalDays: 360,
        totalPhrases: 1800,
        masteredCount: 1632,
        streak: 41,
        finishedAt: .now
    )
}
