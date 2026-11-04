import Foundation

public enum LocalScorer {
    public static func score(expected: String, actual: String, duration: Double) -> ScoreReport {
        let expectedTokens = TextNormalizer.tokens(expected)
        let actualTokens = TextNormalizer.tokens(actual)
        let alignments = WordAligner.align(expected: expectedTokens, actual: actualTokens)

        var matched = 0
        var missing = 0
        var extra = 0
        var replaced = 0
        for alignment in alignments {
            switch alignment {
            case .matched: matched += 1
            case .missing: missing += 1
            case .extra: extra += 1
            case .replaced: replaced += 1
            }
        }

        let expectedCount = max(expectedTokens.count, 1)
        let actualCount = max(actualTokens.count, 1)
        let completeness = Double(matched) / Double(expectedCount)
        let accuracy = max(0, 1 - Double(replaced + extra + missing) / Double(max(expectedCount, actualCount)))
        let wps = duration > 0 ? Double(expectedTokens.count) / duration : 0
        let fluency = fluencyScore(wordsPerSecond: wps, duration: duration)

        let total = 100 * (0.5 * completeness + 0.3 * accuracy + 0.2 * fluency)
        return ScoreReport(
            score: max(0, min(100, Int(total.rounded()))),
            completeness: completeness,
            accuracy: accuracy,
            fluency: fluency,
            wordsPerSecond: wps,
            alignments: alignments
        )
    }

    static func fluencyScore(wordsPerSecond wps: Double, duration: Double) -> Double {
        guard duration > 0 else { return 0 }
        if wps < 2.0 { return max(0.2, 1 - (2.0 - wps) * 0.6) }
        if wps > 3.5 { return max(0.3, 1 - (wps - 3.5) * 0.4) }
        return 1.0
    }
}
