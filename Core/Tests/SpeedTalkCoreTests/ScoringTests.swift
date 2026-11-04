import Testing
import Foundation
@testable import SpeedTalkCore

@Test func normalizerStripsPunctuationAndLowercases() {
    #expect(TextNormalizer.tokens("Hello, WORLD! It's 5 o'clock.") == ["hello", "world", "it's", "5", "o'clock"])
}

@Test func normalizerExpandsSpokenContractionsOnBothSides() {
    #expect(TextNormalizer.tokens("I'm gonna grab a coffee") == ["i", "am", "going", "to", "grab", "a", "coffee"])
    #expect(TextNormalizer.tokens("I'm going to grab a coffee") == ["i", "am", "going", "to", "grab", "a", "coffee"])
    #expect(TextNormalizer.tokens("I wanna go") == ["i", "want", "to", "go"])
}

@Test func alignerMarksMissingWord() {
    let ops = WordAligner.align(expected: ["want", "anything"], actual: ["want"])
    #expect(ops.contains(.missing("anything")))
}

@Test func alignerMarksExtraWord() {
    let ops = WordAligner.align(expected: ["want"], actual: ["want", "some"])
    #expect(ops.contains(.extra("some")))
}

@Test func alignerMarksReplacement() {
    let ops = WordAligner.align(expected: ["coffee"], actual: ["cocoa"])
    #expect(ops.contains(.replaced(expected: "coffee", actual: "cocoa")))
}

@Test func perfectReadingScoresHigh() {
    let report = LocalScorer.score(
        expected: "I'm gonna grab a coffee.",
        actual: "I am going to grab a coffee",
        duration: 2.2
    )
    #expect(report.score >= 85)
    #expect(report.grade == .a)
}

@Test func missingHalfTheSentenceScoresLow() {
    let report = LocalScorer.score(
        expected: "Can I get this to go please",
        actual: "can i get",
        duration: 1.5
    )
    #expect(report.score < 70)
    #expect(report.completeness < 0.7)
}

@Test func silentAudioScoresZeroFluency() {
    let report = LocalScorer.score(expected: "hello there", actual: "hello there", duration: 0)
    #expect(report.fluency == 0)
}

@Test func gradeThresholds() {
    #expect(Grade(score: 85) == .a)
    #expect(Grade(score: 84) == .b)
    #expect(Grade(score: 69) == .c)
}
