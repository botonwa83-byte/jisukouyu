import SwiftUI
import UIKit

/// 糖果系暖调色板：奶油纸面、蜜桃主色、薄荷/芒果/草莓点缀。
/// 十六进制 → 随明暗模式切换的颜色。
func dynamic(light: UInt32, dark: UInt32) -> Color {
    func ui(_ hex: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
    return Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? ui(dark) : ui(light) })
}

enum Theme {
    /// 正文墨色：暖可可棕，比纯黑柔。
    static let ink = dynamic(light: 0x4B3A33, dark: 0xF6EDE4)
    /// 页面底色：奶油米。
    static let paper = dynamic(light: 0xFFF6EC, dark: 0x1C1714)
    /// 卡片底色：暖白，比纯白更贴纸面。
    static let card = dynamic(light: 0xFFFDFA, dark: 0x2A2320)
    /// 主色：蜜桃珊瑚，按钮与强调。
    static let accent = dynamic(light: 0xFA7757, dark: 0xFF8F6B)
    /// 樱花粉：辅助点缀、标签底色。
    static let blush = dynamic(light: 0xFFB3C6, dark: 0xF08CA4)
    static let positive = dynamic(light: 0x3FB98F, dark: 0x4FD3A6)
    static let warning = dynamic(light: 0xFFAD33, dark: 0xFFC15C)
    static let danger = dynamic(light: 0xF24E7D, dark: 0xFF6B8A)
    /// 证书与通关页的金色。
    static let gold = dynamic(light: 0xB38F42, dark: 0xE3C077)

    static func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A": return positive
        case "B": return warning
        default: return danger
        }
    }
}

extension Font {
    static let phrase = Font.system(size: 34, weight: .semibold, design: .rounded)
    static let phraseSmall = Font.system(size: 26, weight: .semibold, design: .rounded)
    static let captionLabel = Font.system(size: 13, weight: .medium, design: .rounded)
}

extension View {
    /// 列表页去掉系统灰底，换成奶油纸面，保持暖调连续。
    func warmList() -> some View {
        scrollContentBackground(.hidden)
            .background(Theme.paper)
    }
}
