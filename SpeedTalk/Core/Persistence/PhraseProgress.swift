import Foundation
import SwiftData

@Model
final class PhraseProgress {
    @Attribute(.unique) var phraseID: String
    var masteryLevel: Int = 0
    var bestScore: Int = 0
    var attemptCount: Int = 0
    var isFavorite: Bool = false
    var lastReviewedAt: Date?
    var nextReviewAt: Date?
    var lastTranscript: String?

    init(phraseID: String) {
        self.phraseID = phraseID
    }
}
