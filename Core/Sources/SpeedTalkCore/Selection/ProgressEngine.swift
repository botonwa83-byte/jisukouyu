import Foundation

public struct PlanAdvanceResult: Equatable, Sendable {
    public let snapshot: PlanProgressSnapshot
    public let didFinishPlan: Bool
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
            return PlanAdvanceResult(snapshot: next, didFinishPlan: false)
        }

        return PlanAdvanceResult(snapshot: next, didFinishPlan: true)
    }
}
