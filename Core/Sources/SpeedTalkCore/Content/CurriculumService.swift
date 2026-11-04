import Foundation

public struct CurriculumService: Sendable {
    public static let stageOrder = ["a", "b", "c"]

    public let curriculum: Curriculum
    public let library: PhraseLibrary

    public init(curriculum: Curriculum, library: PhraseLibrary) {
        self.curriculum = curriculum
        self.library = library
    }

    public func dayCount(plan: String, stage: String) -> Int {
        curriculum.plan(id: plan)?
            .stages.first { $0.id == stage }?
            .days.count ?? 0
    }

    public func day(plan: String, stage: String, day: Int) -> [Phrase] {
        guard let planModel = curriculum.plan(id: plan),
              let stageModel = planModel.stages.first(where: { $0.id == stage }),
              let dayModel = stageModel.days.first(where: { $0.day == day })
        else { return [] }
        return dayModel.phraseIDs.compactMap { library.phrase(id: $0) }
    }

    public func nextStage(after stage: String, plan: String) -> String? {
        guard let planModel = curriculum.plan(id: plan) else { return nil }
        let order = planModel.stages.map(\.id)
        guard let index = order.firstIndex(of: stage), index + 1 < order.count else { return nil }
        return order[index + 1]
    }

    public func validate() -> [String] {
        var issues: [String] = []
        for plan in curriculum.plans {
            for stage in plan.stages {
                let days = stage.days
                if days.count > 120 {
                    issues.append("\(plan.id)-\(stage.id) 天数超过 120，实际 \(days.count)")
                }
                let dayNumbers = days.map(\.day).sorted()
                if dayNumbers != Array(1...max(days.count, 1)) {
                    issues.append("\(plan.id)-\(stage.id) 天序号不连续")
                }
                for day in days {
                    if day.phraseIDs.count != 5 {
                        issues.append("\(plan.id)-\(stage.id)-\(day.day) 句数应为 5，实际 \(day.phraseIDs.count)")
                    }
                    for id in day.phraseIDs where library.phrase(id: id) == nil {
                        issues.append("\(plan.id)-\(stage.id)-\(day.day) 引用了不存在的句子 \(id)")
                    }
                }
            }
        }
        return issues
    }
}
