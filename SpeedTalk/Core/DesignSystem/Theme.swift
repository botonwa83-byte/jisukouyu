import SwiftUI

enum Theme {
    static let ink = Color(red: 0.09, green: 0.10, blue: 0.12)
    static let paper = Color(red: 0.98, green: 0.97, blue: 0.95)
    static let accent = Color(red: 0.10, green: 0.45, blue: 0.94)
    static let positive = Color(red: 0.13, green: 0.66, blue: 0.42)
    static let warning = Color(red: 0.90, green: 0.45, blue: 0.13)
    static let danger = Color(red: 0.83, green: 0.22, blue: 0.24)

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
