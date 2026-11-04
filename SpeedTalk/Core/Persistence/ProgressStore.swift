import Foundation
import SwiftData
import SpeedTalkCore

@MainActor
final class ProgressStore {
    private let context: ModelContext
    private let reviewScheduler = ReviewScheduler()

    init(context: ModelContext) {
        self.context = context
    }

    func phraseProgress(id: String) -> PhraseProgress {
        let descriptor = FetchDescriptor<PhraseProgress>(predicate: #Predicate { $0.phraseID == id })
        if let existing = try? context.fetch(descriptor).first { return existing }
        let created = PhraseProgress(phraseID: id)
        context.insert(created)
        return created
    }

    func recordAttempt(
        phraseID: String,
        score: Int,
        transcript: String,
        duration: Double,
        profile: UserProfile,
        now: Date = Date.now
    ) {
        let progress = phraseProgress(id: phraseID)
        progress.attemptCount += 1
        progress.bestScore = max(progress.bestScore, score)
        progress.lastTranscript = transcript
        progress.lastReviewedAt = now
        if score >= 80 {
            progress.masteryLevel = min(progress.masteryLevel + 1, 5)
        } else if score < 60 {
            progress.masteryLevel = max(progress.masteryLevel - 1, 0)
        }
        let outcome = reviewScheduler.next(level: progress.masteryLevel, score: score, from: now, calendar: .current)
        progress.nextReviewAt = outcome.nextReviewAt

        let newStreak = StreakCalculator.nextStreak(
            current: profile.streak,
            lastStudyDate: profile.lastStudyDate,
            now: now,
            calendar: .current
        )
        profile.streak = newStreak
        profile.longestStreak = max(profile.longestStreak, newStreak)
        profile.lastStudyDate = now
        try? context.save()
    }

    func logDayCompletion(
        plan: String,
        stage: String,
        day: Int,
        completedCount: Int,
        totalScore: Int,
        now: Date = Date.now
    ) {
        let key = Self.dateKey(now)
        let descriptor = FetchDescriptor<DailyLog>(predicate: #Predicate { $0.dateKey == key })
        let log: DailyLog
        if let existing = try? context.fetch(descriptor).first {
            log = existing
        } else {
            log = DailyLog(dateKey: key, plan: plan, stage: stage, day: day)
            context.insert(log)
        }
        log.completedCount = completedCount
        log.totalScore = totalScore
        log.isCheckedIn = completedCount >= 5
        try? context.save()
    }

    static func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
