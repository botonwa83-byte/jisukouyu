import Foundation

public extension Curriculum.Plan {
    /// 全部阶段的天数之和（每个方案应为 360 天）。
    var totalDayCount: Int {
        stages.reduce(0) { $0 + $1.days.count }
    }

    /// 全部阶段的句子数之和（每个方案应为 1800 句）。
    var totalPhraseCount: Int {
        stages.reduce(0) { total, stage in
            total + stage.phraseCount
        }
    }
}

public extension Curriculum.Plan.Stage {
    /// 本阶段的天数（每个阶段应为 120 天）。
    var dayCount: Int { days.count }

    /// 本阶段的句子数（每个阶段应为 600 句）。
    var phraseCount: Int {
        days.reduce(0) { $0 + $1.phraseIDs.count }
    }
}
