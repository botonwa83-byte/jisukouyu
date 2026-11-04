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

    init(planID: String) {
        self.planID = planID
    }

    var snapshot: PlanProgressSnapshot {
        PlanProgressSnapshot(planID: planID, stage: currentStage, day: currentDay, completedDays: completedDays)
    }

    func apply(_ snapshot: PlanProgressSnapshot) {
        planID = snapshot.planID
        currentStage = snapshot.stage
        currentDay = snapshot.day
        completedDays = snapshot.completedDays
    }
}
