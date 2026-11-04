import Testing
import Foundation
@testable import SpeedTalkCore

@Test func bundledContentLoads() throws {
    let bundle = try ContentLoader.loadBundled()
    #expect(bundle.library.all.isEmpty == false)
    #expect(bundle.curriculum.plans.isEmpty == false)
}

@Test func bundledCurriculumHasNoDanglingReferences() throws {
    let bundle = try ContentLoader.loadBundled()
    let issues = CurriculumService(curriculum: bundle.curriculum, library: bundle.library).validate()
    #expect(issues.contains { $0.contains("不存在的句子") } == false)
}

@Test func phraseCanBeDecodedFromJSON() throws {
    let json = """
    {"id":"01-a-001-1","plan":"01","stage":"a","unit":1,"day":1,"index":1,
     "en":"I'm gonna grab a coffee.","zh":"我去买杯咖啡。","scene":"dining","level":1,
     "focus":"gonna = going to","register":"casual","tags":["缩略"],
     "pronunciation":{"ipa":"/aɪm ˈɡʌnə ɡræb ə ˈkɔːfi/","notes":["gonna 读 /ˈɡʌnə/"]},
     "variants":["I'm grabbing a coffee."],"avoid":"I am going to buy a cup of coffee.",
     "transfer":"I'm gonna grab ___.","context":"办公室随口问同事"}
    """.data(using: .utf8)!
    let phrase = try JSONDecoder().decode(Phrase.self, from: json)
    #expect(phrase.id == "01-a-001-1")
    #expect(phrase.scene == .dining)
    #expect(phrase.register == .casual)
}

@Test func librarySearchMatchesChineseAndEnglish() throws {
    let bundle = try ContentLoader.loadBundled()
    #expect(bundle.library.search("coffee").isEmpty == false)
    #expect(bundle.library.search("咖啡").isEmpty == false)
}

@Test func validationCatchesDanglingPhraseReference() {
    let phrase = Phrase.fixture(id: "01-a-001-1")
    let library = PhraseLibrary(phrases: [phrase])
    let curriculum = Curriculum(
        version: 1,
        plans: [
            .init(id: "01", title: "生活生存", subtitle: "", stages: [
                .init(id: "a", title: "吃住行基础", units: [
                    .init(index: 1, title: "第一周", days: [
                        .init(day: 1, title: "开口第一句", phraseIDs: ["01-a-001-1", "01-a-001-9"])
                    ])
                ])
            ])
        ]
    )
    let issues = CurriculumService(curriculum: curriculum, library: library).validate()
    #expect(issues.contains { $0.contains("01-a-001-9") })
}

@Test func plan01StageAHasExactly600Phrases() throws {
    let bundle = try ContentLoader.loadBundled()
    let count = bundle.library.phrases(plan: "01", stage: "a").count
    #expect(count == 600)
}

@Test func plan01StageAHas120DaysOfFive() throws {
    let bundle = try ContentLoader.loadBundled()
    let service = CurriculumService(curriculum: bundle.curriculum, library: bundle.library)
    #expect(service.dayCount(plan: "01", stage: "a") == 120)
    for day in 1...120 {
        #expect(service.day(plan: "01", stage: "a", day: day).count == 5)
    }
}

@Test func allPhrasesFollowCopyRules() throws {
    let bundle = try ContentLoader.loadBundled()
    for phrase in bundle.library.all {
        #expect(phrase.pronunciation.notes.isEmpty == false, "\(phrase.id) 缺发音提示")
        #expect(phrase.variants.isEmpty == false, "\(phrase.id) 缺变体")
        #expect(phrase.avoid?.isEmpty == false, "\(phrase.id) 缺 avoid 反例")
        #expect(phrase.focus.isEmpty == false, "\(phrase.id) 缺 focus")
        let limit = phrase.stage == "a" ? 10 : (phrase.stage == "b" ? 14 : 18)
        #expect(phrase.en.split(separator: " ").count <= limit, "\(phrase.id) 超长")
    }
}

@Test func phraseIDsAreUniqueAndWellFormed() throws {
    let bundle = try ContentLoader.loadBundled()
    let ids = bundle.library.all.map(\.id)
    #expect(Set(ids).count == ids.count)
    for phrase in bundle.library.all {
        #expect(phrase.id == String(format: "%@-%@-%03d-%d", phrase.plan, phrase.stage, phrase.day, phrase.index))
    }
}

@Test func bundledCurriculumIsFullyValid() throws {
    let bundle = try ContentLoader.loadBundled()
    let issues = CurriculumService(curriculum: bundle.curriculum, library: bundle.library).validate()
    #expect(issues.isEmpty, "课纲校验问题：\(issues.joined(separator: "; "))")
}

@Test func everyPlanTotalsMatchCertificate() throws {
    let bundle = try ContentLoader.loadBundled()
    for plan in bundle.curriculum.plans {
        #expect(plan.stages.count == 3, "\(plan.id) 阶段数不对")
        #expect(plan.totalDayCount == 360, "\(plan.id) 应为 360 天")
        #expect(plan.totalPhraseCount == 1800, "\(plan.id) 应为 1800 句")
    }
}
