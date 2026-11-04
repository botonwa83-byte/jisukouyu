import Foundation

public struct ContentBundle: Sendable {
    public let library: PhraseLibrary
    public let curriculum: Curriculum

    public init(library: PhraseLibrary, curriculum: Curriculum) {
        self.library = library
        self.curriculum = curriculum
    }
}

public enum ContentLoaderError: Error, CustomStringConvertible {
    case missingResource(String)

    public var description: String {
        switch self {
        case .missingResource(let name): return "找不到内容文件：\(name)"
        }
    }
}

public enum ContentLoader {
    struct PhraseFile: Decodable {
        let version: Int
        let phrases: [Phrase]
    }

    public static func loadBundled() throws -> ContentBundle {
        guard let phraseURL = Bundle.module.url(forResource: "phrases", withExtension: "json") else {
            throw ContentLoaderError.missingResource("phrases.json")
        }
        guard let curriculumURL = Bundle.module.url(forResource: "curriculum", withExtension: "json") else {
            throw ContentLoaderError.missingResource("curriculum.json")
        }
        let decoder = JSONDecoder()
        let phraseFile = try decoder.decode(PhraseFile.self, from: Data(contentsOf: phraseURL))
        let curriculum = try decoder.decode(Curriculum.self, from: Data(contentsOf: curriculumURL))
        return ContentBundle(library: PhraseLibrary(phrases: phraseFile.phrases), curriculum: curriculum)
    }

    public static func load(phrasesData: Data, curriculumData: Data) throws -> ContentBundle {
        let decoder = JSONDecoder()
        let phraseFile = try decoder.decode(PhraseFile.self, from: phrasesData)
        let curriculum = try decoder.decode(Curriculum.self, from: curriculumData)
        return ContentBundle(library: PhraseLibrary(phrases: phraseFile.phrases), curriculum: curriculum)
    }
}
