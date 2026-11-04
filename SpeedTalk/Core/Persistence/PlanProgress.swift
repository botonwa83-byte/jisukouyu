import Foundation
import SwiftData
import SpeedTalkCore

@Model
final class PlanProgress {
    @Attribute(.unique) var planID: String
    var currentStage: String = "a"
    var currentDay: Int = 1
    var completedDays: Int = 0
    var isCompleted: Bool = false
    var finishedAt: Date?
    var advanceDate: Date?
    var advanceCount: Int = 0

    init(planID: String) {
        self.planID = planID
    }

    var snapshot: PlanProgressSnapshot {
        PlanProgressSnapshot(planID: planID, stage: currentStage, day: currentDay, completedDays: completedDays)
    }

    /// 今日还能推进几天；跨自然日自动恢复额度。
    var advanceBudget: AdvanceBudget {
        AdvanceBudget(date: advanceDate, used: advanceCount)
    }

    var advanceRemaining: Int {
        advanceBudget.remaining(on: .now, calendar: .current)
    }

    func consumeAdvance(_ days: Int, now: Date = .now, calendar: Calendar = .current) {
        let next = advanceBudget.consuming(days, on: now, calendar: calendar)
        advanceDate = next.date
        advanceCount = next.used
    }

    func apply(_ snapshot: PlanProgressSnapshot) {
        planID = snapshot.planID
        currentStage = snapshot.stage
        currentDay = snapshot.day
        completedDays = snapshot.completedDays
    }
}
