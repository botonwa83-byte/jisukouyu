import Foundation

public struct PlanProgressSnapshot: Equatable, Sendable {
    public var planID: String
    public var stage: String
    public var day: Int
    public var completedDays: Int

    public init(planID: String, stage: String, day: Int, completedDays: Int) {
        self.planID = planID
        self.stage = stage
        self.day = day
        self.completedDays = completedDays
    }

    public static func initial(planID: String) -> PlanProgressSnapshot {
        PlanProgressSnapshot(planID: planID, stage: "a", day: 1, completedDays: 0)
    }
}
