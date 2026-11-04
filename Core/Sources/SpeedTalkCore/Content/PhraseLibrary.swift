import Foundation

public struct PhraseLibrary: Sendable {
    private let byID: [String: Phrase]
    public let all: [Phrase]

    public init(phrases: [Phrase]) {
        self.all = phrases
        self.byID = Dictionary(uniqueKeysWithValues: phrases.map { ($0.id, $0) })
    }

    public func phrase(id: String) -> Phrase? { byID[id] }

    public func phrases(plan: String, stage: String) -> [Phrase] {
        all.filter { $0.plan == plan && $0.stage == stage }
            .sorted { ($0.day, $0.index) < ($1.day, $1.index) }
    }

    public func search(_ query: String) -> [Phrase] {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !keyword.isEmpty else { return all }
        return all.filter {
            $0.en.lowercased().contains(keyword)
            || $0.zh.contains(keyword)
            || $0.tags.contains { $0.lowercased().contains(keyword) }
        }
    }

    public func phrases(scene: Scene) -> [Phrase] {
        all.filter { $0.scene == scene }.sorted { $0.id < $1.id }
    }
}
