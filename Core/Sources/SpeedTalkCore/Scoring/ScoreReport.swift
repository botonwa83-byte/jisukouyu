import Foundation

public enum Grade: String, Sendable, Equatable {
    case a = "A"
    case b = "B"
    case c = "C"

    public init(score: Int) {
        switch score {
        case 85...: self = .a
        case 70..<85: self = .b
        default: self = .c
        }
    }

    public var title: String {
        switch self {
        case .a: return "这遍到位了"
        case .b: return "还差一点"
        case .c: return "再来一遍"
        }
    }
}

public struct ScoreReport: Sendable, Equatable {
    public let score: Int
    public let grade: Grade
    public let completeness: Double
    public let accuracy: Double
    public let fluency: Double
    public let wordsPerSecond: Double
    public let alignments: [WordAlignment]

    public init(
        score: Int,
        completeness: Double,
        accuracy: Double,
        fluency: Double,
        wordsPerSecond: Double,
        alignments: [WordAlignment]
    ) {
        self.score = score
        self.grade = Grade(score: score)
        self.completeness = completeness
        self.accuracy = accuracy
        self.fluency = fluency
        self.wordsPerSecond = wordsPerSecond
        self.alignments = alignments
    }
}
