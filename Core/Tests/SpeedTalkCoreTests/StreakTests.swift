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

@Test func displayStreakKeepsSameDayAndYesterday() {
    let now = Date()
    #expect(StreakCalculator.currentStreak(current: 4, last: now, now: now, calendar: .current) == 4)
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
    #expect(StreakCalculator.currentStreak(current: 4, last: yesterday, now: now, calendar: .current) == 4)
}

@Test func displayStreakResetsWhenLapsed() {
    let now = Date()
    let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now)!
    #expect(StreakCalculator.currentStreak(current: 9, last: threeDaysAgo, now: now, calendar: .current) == 0)
    #expect(StreakCalculator.currentStreak(current: 9, last: nil, now: now, calendar: .current) == 0)
}
