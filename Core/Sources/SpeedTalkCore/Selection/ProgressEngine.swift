import Foundation

public struct PlanAdvanceResult: Equatable, Sendable {
    public let snapshot: PlanProgressSnapshot
    public let didFinishPlan: Bool
    /// 本次推进刚走完的阶段 ID；未跨阶段时为 nil，用来触发阶段通关庆祝。
    public let completedStage: String?

    public init(snapshot: PlanProgressSnapshot, didFinishPlan: Bool, completedStage: String? = nil) {
        self.snapshot = snapshot
        self.didFinishPlan = didFinishPlan
        self.completedStage = completedStage
    }
}

public struct ProgressEngine: Sendable {
    private let service: CurriculumService

    public init(service: CurriculumService) {
        self.service = service
    }

    public func advance(_ snapshot: PlanProgressSnapshot) -> PlanAdvanceResult {
        guard let plan = service.curriculum.plan(id: snapshot.planID) else {
            return PlanAdvanceResult(snapshot: snapshot, didFinishPlan: false)
        }
        let order = plan.stages.map(\.id)
        let stageIndex = order.firstIndex(of: snapshot.stage) ?? 0
        let dayCount = max(service.dayCount(plan: snapshot.planID, stage: snapshot.stage), 1)

        var next = snapshot
        next.completedDays = min(snapshot.completedDays + 1, dayCount)

        if snapshot.day < dayCount {
            next.day = snapshot.day + 1
            return PlanAdvanceResult(snapshot: next, didFinishPlan: false)
        }

        if stageIndex + 1 < order.count {
            next.stage = order[stageIndex + 1]
            next.day = 1
            next.completedDays = 0
            return PlanAdvanceResult(snapshot: next, didFinishPlan: false, completedStage: snapshot.stage)
        }

        return PlanAdvanceResult(snapshot: next, didFinishPlan: true, completedStage: snapshot.stage)
    }
}
