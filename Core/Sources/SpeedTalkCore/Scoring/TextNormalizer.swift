import Foundation

public enum TextNormalizer {
    /// 口语缩略展开表：两侧都展开后再比对，避免 "gonna" 与 "going to" 互判为错
    private static let expansions: [(String, String)] = [
        ("gonna", "going to"),
        ("wanna", "want to"),
        ("gotta", "got to"),
        ("lemme", "let me"),
        ("gimme", "give me"),
        ("kinda", "kind of"),
        ("sorta", "sort of"),
        ("dunno", "do not know"),
        ("'em", "them"),
        ("y'all", "you all"),
        ("i'm", "i am")
    ]

    public static func tokens(_ text: String) -> [String] {
        let cleaned = text
            .lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .map { character -> Character in
                if character.isLetter || character.isNumber || character == "'" { return character }
                return " "
            }

        var words = String(cleaned)
            .split(separator: " ")
            .map(String.init)
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "'")) }
            .filter { !$0.isEmpty }

        for (spoken, full) in expansions {
            words = expand(words, spoken: spoken, full: full)
        }
        return words
    }

    private static func expand(_ words: [String], spoken: String, full: String) -> [String] {
        let fullWords = full.split(separator: " ").map(String.init)
        return words.flatMap { word -> [String] in
            word == spoken ? fullWords : [word]
        }
    }
}
