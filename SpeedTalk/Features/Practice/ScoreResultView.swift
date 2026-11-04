import SwiftUI
import SpeedTalkCore

struct ScoreResultView: View {
    let report: ScoreReport
    let onRetry: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(report.score)")
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.gradeColor(report.grade.rawValue))
                Text(report.grade.rawValue)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.gradeColor(report.grade.rawValue))
                Text(report.grade.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 14) {
                metric("完整", report.completeness)
                metric("准确", report.accuracy)
                metric("流利", report.fluency)
            }

            WordHighlightView(alignments: report.alignments)

            HStack(spacing: 12) {
                Button("重说一遍", action: onRetry)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Theme.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                Button("下一句", action: onNext)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Theme.paper)
    }

    private func metric(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.captionLabel).foregroundStyle(.secondary)
            SwiftUI.ProgressView(value: value)
                .tint(value > 0.8 ? Theme.positive : Theme.warning)
        }
        .frame(maxWidth: .infinity)
    }
}
