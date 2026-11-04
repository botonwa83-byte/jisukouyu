import Foundation

public struct DailySelector: Sendable {
    private let service: CurriculumService

    public init(service: CurriculumService) {
        self.service = service
    }

    public func selection(for snapshot: PlanProgressSnapshot) -> [Phrase] {
        service.day(plan: snapshot.planID, stage: snapshot.stage, day: snapshot.day)
    }

    public func dayTitle(plan: String, stage: String, day: Int) -> String {
        service.curriculum.plan(id: plan)?
            .stages.first { $0.id == stage }?
            .units.flatMap(\.days).first { $0.day == day }?
            .title ?? "第 \(day) 天"
    }

    /// 当天剩余到期复习：由调用方传入到期句 ID，最多取 limit 条
    public func reviewPick(from dueIDs: [String], limit: Int = 2) -> [Phrase] {
        dueIDs.prefix(limit).compactMap { service.library.phrase(id: $0) }
    }
}
