import Testing
import Foundation
@testable import SpeedTalkCore

/// 用合成课纲测试推进逻辑，避免依赖语料是否已补齐到 120 天
private func makeFixtureService() -> CurriculumService {
    var phrases: [Phrase] = []
    var stages: [Curriculum.Plan.Stage] = []

    for stageID in ["a", "b", "c"] {
        var days: [Curriculum.Plan.Stage.Unit.Day] = []
        for day in 1...2 {
            let ids = (1...5).map { "01-\(stageID)-\(day)-\($0)" }
            for (index, id) in ids.enumerated() {
                phrases.append(
                    Phrase(
                        id: id, plan: "01", stage: stageID, unit: 1, day: day, index: index + 1,
                        en: "Line \(id)", zh: "第 \(day) 天第 \(index + 1) 句",
                        scene: .dining, level: 1, focus: "test", register: .neutral,
                        tags: [], pronunciation: .init(ipa: "/test/", notes: ["note"]),
                        variants: ["variant"], avoid: "avoid", transfer: "transfer", context: "context"
                    )
                )
            }
            days.append(.init(day: day, title: "Day \(day)", phraseIDs: ids))
        }
        stages.append(.init(id: stageID, title: "Stage \(stageID)", units: [
            .init(index: 1, title: "Unit 1", days: days)
        ]))
    }

    let curriculum = Curriculum(version: 1, plans: [
        .init(id: "01", title: "生活生存", subtitle: "", stages: stages)
    ])
    return CurriculumService(curriculum: curriculum, library: PhraseLibrary(phrases: phrases))
}

@Test func dailySelectionReturnsFivePhrases() throws {
    let bundle = try ContentLoader.loadBundled()
    let selector = DailySelector(service: CurriculumService(curriculum: bundle.curriculum, library: bundle.library))
    let snapshot = PlanProgressSnapshot(planID: "01", stage: "a", day: 1, completedDays: 0)
    #expect(selector.selection(for: snapshot).count == 5)
}

@Test func advanceMovesToNextDay() {
    let engine = ProgressEngine(service: makeFixtureService())
    let result = engine.advance(PlanProgressSnapshot(planID: "01", stage: "a", day: 1, completedDays: 0))
    #expect(result.snapshot.day == 2)
    #expect(result.snapshot.completedDays == 1)
    #expect(result.didFinishPlan == false)
}

@Test func advanceRollsOverToNextStageAtStageEnd() {
    let engine = ProgressEngine(service: makeFixtureService())
    let result = engine.advance(PlanProgressSnapshot(planID: "01", stage: "a", day: 2, completedDays: 1))
    #expect(result.snapshot.stage == "b")
    #expect(result.snapshot.day == 1)
    #expect(result.snapshot.completedDays == 0)
    #expect(result.completedStage == "a")
}

@Test func advanceWithinStageReportsNoCompletedStage() {
    let engine = ProgressEngine(service: makeFixtureService())
    let result = engine.advance(PlanProgressSnapshot(planID: "01", stage: "a", day: 1, completedDays: 0))
    #expect(result.completedStage == nil)
}

@Test func stageTotalsMatchCurriculum() {
    let stage = makeFixtureService().curriculum.plan(id: "01")?.stages.first
    #expect(stage?.dayCount == 2)
    #expect(stage?.phraseCount == 10)
}

@Test func advanceAtLastStageFinishesPlan() {
    let engine = ProgressEngine(service: makeFixtureService())
    let result = engine.advance(PlanProgressSnapshot(planID: "01", stage: "c", day: 2, completedDays: 1))
    #expect(result.didFinishPlan)
}

@Test func reviewIntervalGrowsWhenScoreIsHigh() {
    let scheduler = ReviewScheduler()
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let outcome = scheduler.next(level: 0, score: 90, from: now, calendar: .current)
    #expect(outcome.level == 1)
    #expect(outcome.nextReviewAt.timeIntervalSince(now) >= 86_400)
}

@Test func reviewResetsWhenScoreIsLow() {
    let scheduler = ReviewScheduler()
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let outcome = scheduler.next(level: 4, score: 40, from: now, calendar: .current)
    #expect(outcome.level == 0)
    #expect(outcome.nextReviewAt.timeIntervalSince(now) < 2 * 86_400)
}

@Test func reviewCapsAtLevelFive() {
    let scheduler = ReviewScheduler()
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let outcome = scheduler.next(level: 5, score: 95, from: now, calendar: .current)
    #expect(outcome.level == 5)
}
