import Foundation

public struct ReviewOutcome: Equatable, Sendable {
    public let level: Int
    public let nextReviewAt: Date
}

public struct ReviewScheduler: Sendable {
    /// 等级 1...5 对应的间隔天数
    public static let intervals: [Int] = [1, 3, 7, 16, 35]

    public init() {}

    public func next(level: Int, score: Int, from date: Date, calendar: Calendar) -> ReviewOutcome {
        if score < 70 {
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            return ReviewOutcome(level: 0, nextReviewAt: nextDate)
        }
        let newLevel = min(max(level + 1, 1), 5)
        let days = Self.intervals[newLevel - 1]
        let nextDate = calendar.date(byAdding: .day, value: days, to: date) ?? date
        return ReviewOutcome(level: newLevel, nextReviewAt: nextDate)
    }
}
