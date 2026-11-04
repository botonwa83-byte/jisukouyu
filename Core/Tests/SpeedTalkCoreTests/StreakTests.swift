import Testing
import Foundation
@testable import SpeedTalkCore

@Test func firstStudyMakesStreakOne() {
    #expect(StreakCalculator.nextStreak(current: 0, lastStudyDate: nil, now: Date(), calendar: .current) == 1)
}

@Test func sameDayKeepsStreak() {
    let now = Date()
    let earlier = now.addingTimeInterval(-3600)
    #expect(StreakCalculator.nextStreak(current: 5, lastStudyDate: earlier, now: now, calendar: .current) == 5)
}

@Test func yesterdayIncrementsStreak() {
    let now = Date()
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
    #expect(StreakCalculator.nextStreak(current: 5, lastStudyDate: yesterday, now: now, calendar: .current) == 6)
}

@Test func gapResetsStreak() {
    let now = Date()
    let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now)!
    #expect(StreakCalculator.nextStreak(current: 9, lastStudyDate: threeDaysAgo, now: now, calendar: .current) == 1)
}
