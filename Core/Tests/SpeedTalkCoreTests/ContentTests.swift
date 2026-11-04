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
