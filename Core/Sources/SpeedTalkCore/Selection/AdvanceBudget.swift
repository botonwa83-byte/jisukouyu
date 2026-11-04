import Foundation

/// 超前学习预算：同一个自然日内最多推进 2 天（spec §4）。
public struct AdvanceBudget: Equatable, Sendable {
    public static let dailyLimit = 2

    public let date: Date?
    public let used: Int

    public init(date: Date? = nil, used: Int = 0) {
        self.date = date
        self.used = used
    }

    public func remaining(on now: Date, calendar: Calendar) -> Int {
        guard let date, calendar.isDate(date, inSameDayAs: now) else {
            return Self.dailyLimit
        }
        return max(0, Self.dailyLimit - used)
    }

    public func consuming(_ count: Int, on now: Date, calendar: Calendar) -> AdvanceBudget {
        let sameDay = date.map { calendar.isDate($0, inSameDayAs: now) } ?? false
        let base = sameDay ? used : 0
        return AdvanceBudget(date: now, used: min(Self.dailyLimit, base + max(0, count)))
    }
}
