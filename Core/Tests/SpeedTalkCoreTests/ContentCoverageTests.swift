import Testing
import Foundation
@testable import SpeedTalkCore

private struct StageRef: Sendable {
    let plan: String
    let stage: String
    var label: String { "\(plan)-\(stage)" }
}

private func stageRefs(_ bundle: ContentBundle) -> [StageRef] {
    bundle.curriculum.plans.flatMap { plan in
        plan.stages.map { StageRef(plan: plan.id, stage: $0.id) }
    }
}

@Test func bundledContentCoversEveryDefinedStage() throws {
    let bundle = try ContentLoader.loadBundled()
    let refs = stageRefs(bundle)
    #expect(refs.count == 9, "已定义阶段数应为 9，实际 \(refs.count)")

    let service = CurriculumService(curriculum: bundle.curriculum, library: bundle.library)
    for ref in refs {
        #expect(service.dayCount(plan: ref.plan, stage: ref.stage) == 120, "\(ref.label) 天数不是 120")
        #expect(bundle.library.phrases(plan: ref.plan, stage: ref.stage).count == 600, "\(ref.label) 句数不是 600")
        for day in 1...120 {
            #expect(service.day(plan: ref.plan, stage: ref.stage, day: day).count == 5, "\(ref.label)-\(day) 不是 5 句")
        }
    }

    #expect(bundle.library.all.count == refs.count * 600)
    #expect(bundle.curriculum.plans.flatMap(\.stages).flatMap(\.days).count == refs.count * 120)
}

@Test func everyDayTitleIsRealAndUniqueWithinStage() throws {
    let bundle = try ContentLoader.loadBundled()
    for ref in stageRefs(bundle) {
        guard let stage = bundle.curriculum.plan(id: ref.plan)?.stages.first(where: { $0.id == ref.stage }) else {
            Issue.record("\(ref.label) 缺少阶段定义")
            continue
        }
        let titles = stage.days.map(\.title)
        #expect(titles.count == 120)
        #expect(Set(titles).count == titles.count, "\(ref.label) 存在重复天标题")
        for day in stage.days {
            #expect(day.title.hasPrefix("第 ") == false, "\(ref.label)-\(day.day) 仍是占位标题")
            #expect(day.title.isEmpty == false)
        }
    }
}

@Test func everyStageHasFourThirtyDayUnitsWithTitles() throws {
    let bundle = try ContentLoader.loadBundled()
    for ref in stageRefs(bundle) {
        guard let stage = bundle.curriculum.plan(id: ref.plan)?.stages.first(where: { $0.id == ref.stage }) else {
            Issue.record("\(ref.label) 缺少阶段定义")
            continue
        }
        #expect(stage.units.count == 4, "\(ref.label) 单元数不是 4")
        for unit in stage.units {
            #expect(unit.days.count == 30, "\(ref.label) 第 \(unit.index) 单元不是 30 天")
            #expect(unit.title.contains("单元："), "\(ref.label) 第 \(unit.index) 单元仍是占位标题")
        }
    }
}

@Test func englishSentencesAreUniqueWithinStage() throws {
    let bundle = try ContentLoader.loadBundled()
    for ref in stageRefs(bundle) {
        let sentences = bundle.library
            .phrases(plan: ref.plan, stage: ref.stage)
            .map { $0.en.lowercased() }
        #expect(Set(sentences).count == sentences.count, "\(ref.label) 存在重复英文句子")
    }
}

@Test func everyPhraseHasCompletePronunciationAndContext() throws {
    let bundle = try ContentLoader.loadBundled()
    for phrase in bundle.library.all {
        #expect(phrase.pronunciation.ipa.hasPrefix("/") && phrase.pronunciation.ipa.hasSuffix("/"), "\(phrase.id) IPA 格式异常：\(phrase.pronunciation.ipa)")
        #expect(phrase.pronunciation.ipa.count > 4, "\(phrase.id) IPA 过短")
        #expect(phrase.context.isEmpty == false, "\(phrase.id) 缺使用场景说明")
        #expect(phrase.tags.isEmpty == false, "\(phrase.id) 缺标签")
        #expect((1...3).contains(phrase.level), "\(phrase.id) level 越界")
    }
}

@Test func englishSentencesAreFreeOfChineseAnnotation() throws {
    let bundle = try ContentLoader.loadBundled()
    for phrase in bundle.library.all {
        let hasCJK = phrase.en.unicodeScalars.contains { (0x4E00...0x9FFF).contains($0.value) }
        #expect(hasCJK == false, "\(phrase.id) 的英文含中文标注：\(phrase.en)")
    }
}

@Test func everyStageCoversItsScenes() throws {
    let bundle = try ContentLoader.loadBundled()
    for ref in stageRefs(bundle) {
        let scenes = Set(bundle.library.phrases(plan: ref.plan, stage: ref.stage).map(\.scene))
        #expect(scenes.isEmpty == false, "\(ref.label) 没有任何场景")
    }
    let allScenes = Set(bundle.library.all.map(\.scene))
    #expect(allScenes == Set(Scene.allCases), "全库场景覆盖不全：\(allScenes)")
}
