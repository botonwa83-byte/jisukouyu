import SwiftUI
import SpeedTalkCore

struct WordHighlightView: View {
    let alignments: [WordAlignment]

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(Array(alignments.enumerated()), id: \.offset) { _, alignment in
                switch alignment {
                case .matched(let word):
                    chip(word, color: Theme.positive, strikethrough: false)
                case .missing(let word):
                    chip(word, color: Theme.danger, strikethrough: true)
                case .extra(let word):
                    chip(word, color: .secondary, strikethrough: false)
                case .replaced(let expected, let actual):
                    chip("\(expected) → \(actual)", color: Theme.warning, strikethrough: false)
                }
            }
        }
    }

    private func chip(_ text: String, color: Color, strikethrough: Bool) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .medium, design: .rounded))
            .strikethrough(strikethrough)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .foregroundStyle(color)
    }
}

/// 简单流式布局，避免引入第三方
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: totalHeight + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
