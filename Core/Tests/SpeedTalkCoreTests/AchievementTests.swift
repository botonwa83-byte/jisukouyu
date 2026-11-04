import Testing
@testable import SpeedTalkCore

@Test func firstCheckInUnlocksWelcome() {
    let ids = AchievementCatalog.unlocked(totalMastered: 0, streak: 1, finishedPlanCount: 0)
    #expect(ids.contains("first-checkin"))
}

@Test func twoHundredMasteredUnlocksCollector() {
    let ids = AchievementCatalog.unlocked(totalMastered: 200, streak: 3, finishedPlanCount: 0)
    #expect(ids.contains("mastered-200"))
}

@Test func finishingPlanUnlocksPlanBadge() {
    let ids = AchievementCatalog.unlocked(totalMastered: 1800, streak: 30, finishedPlanCount: 1)
    #expect(ids.contains("plan-finished"))
}

@Test func noStreakUnlocksNothing() {
    let ids = AchievementCatalog.unlocked(totalMastered: 0, streak: 0, finishedPlanCount: 0)
    #expect(ids.isEmpty)
}
