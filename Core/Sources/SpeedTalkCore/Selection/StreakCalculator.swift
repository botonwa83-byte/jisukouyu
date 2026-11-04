import Foundation

public enum StreakCalculator {
    public static func nextStreak(
        current: Int,
        lastStudyDate: Date?,
        now: Date,
        calendar: Calendar
    ) -> Int {
        guard let lastStudyDate else { return 1 }
        if calendar.isDate(lastStudyDate, inSameDayAs: now) {
            return max(current, 1)
        }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastStudyDate),
            to: calendar.startOfDay(for: now)
        ).day ?? 0
        return days == 1 ? max(current, 1) + 1 : 1
    }

    public static func currentStreak(current: Int, last: Date?, now: Date, calendar: Calendar) -> Int {
        guard let last else { return 0 }
        let start = calendar.startOfDay(for: last)
        let today = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return days <= 1 ? current : 0
    }
}
