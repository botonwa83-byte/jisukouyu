import Foundation

public struct AchievementDefinition: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let symbol: String

    public init(id: String, title: String, detail: String, symbol: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.symbol = symbol
    }
}

public enum AchievementCatalog {
    public static let all: [AchievementDefinition] = [
        .init(id: "first-checkin", title: "第一天", detail: "完成第一次打卡", symbol: "flag"),
        .init(id: "streak-7", title: "一周不断", detail: "连续打卡 7 天", symbol: "flame"),
        .init(id: "streak-30", title: "一个月", detail: "连续打卡 30 天", symbol: "flame.fill"),
        .init(id: "streak-100", title: "百天", detail: "连续打卡 100 天", symbol: "crown"),
        .init(id: "mastered-100", title: "百句成口", detail: "掌握 100 句", symbol: "text.bubble"),
        .init(id: "mastered-200", title: "两百句", detail: "掌握 200 句", symbol: "text.bubble.fill"),
        .init(id: "mastered-500", title: "五百句", detail: "掌握 500 句", symbol: "books.vertical"),
        .init(id: "stage-finished", title: "阶段通关", detail: "完成一个 600 句阶段", symbol: "checkmark.seal"),
        .init(id: "plan-finished", title: "方案通关", detail: "完成一个 1800 句方案", symbol: "trophy")
    ]

    public static func unlocked(totalMastered: Int, streak: Int, finishedPlanCount: Int) -> [String] {
        var ids: [String] = []
        if streak >= 1 { ids.append("first-checkin") }
        if streak >= 7 { ids.append("streak-7") }
        if streak >= 30 { ids.append("streak-30") }
        if streak >= 100 { ids.append("streak-100") }
        if totalMastered >= 100 { ids.append("mastered-100") }
        if totalMastered >= 200 { ids.append("mastered-200") }
        if totalMastered >= 500 { ids.append("mastered-500") }
        if totalMastered >= 600 { ids.append("stage-finished") }
        if finishedPlanCount >= 1 { ids.append("plan-finished") }
        return ids
    }
}
