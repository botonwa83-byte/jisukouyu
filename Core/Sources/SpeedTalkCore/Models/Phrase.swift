import Foundation

public struct Phrase: Codable, Identifiable, Hashable, Sendable {
    public struct Pronunciation: Codable, Hashable, Sendable {
        public let ipa: String
        public let notes: [String]

        public init(ipa: String, notes: [String]) {
            self.ipa = ipa
            self.notes = notes
        }
    }

    public let id: String
    public let plan: String
    public let stage: String
    public let unit: Int
    public let day: Int
    public let index: Int
    public let en: String
    public let zh: String
    public let scene: Scene
    public let level: Int
    public let focus: String
    public let register: Register
    public let tags: [String]
    public let pronunciation: Pronunciation
    public let variants: [String]
    public let avoid: String?
    public let transfer: String?
    public let context: String

    public init(
        id: String, plan: String, stage: String, unit: Int, day: Int, index: Int,
        en: String, zh: String, scene: Scene, level: Int, focus: String,
        register: Register, tags: [String], pronunciation: Pronunciation,
        variants: [String], avoid: String?, transfer: String?, context: String
    ) {
        self.id = id
        self.plan = plan
        self.stage = stage
        self.unit = unit
        self.day = day
        self.index = index
        self.en = en
        self.zh = zh
        self.scene = scene
        self.level = level
        self.focus = focus
        self.register = register
        self.tags = tags
        self.pronunciation = pronunciation
        self.variants = variants
        self.avoid = avoid
        self.transfer = transfer
        self.context = context
    }
}

extension Phrase {
    public static func fixture(id: String = "01-a-001-1") -> Phrase {
        Phrase(
            id: id, plan: "01", stage: "a", unit: 1, day: 1, index: 1,
            en: "I'm gonna grab a coffee.", zh: "我去买杯咖啡。",
            scene: .dining, level: 1, focus: "gonna = going to",
            register: .casual, tags: ["缩略"],
            pronunciation: .init(ipa: "/aɪm ˈɡʌnə ɡræb ə ˈkɔːfi/", notes: ["gonna 读 /ˈɡʌnə/"]),
            variants: ["I'm grabbing a coffee."],
            avoid: "I am going to buy a cup of coffee.",
            transfer: "I'm gonna grab ___.",
            context: "办公室随口问同事"
        )
    }
}
