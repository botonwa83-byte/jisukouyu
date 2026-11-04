import Foundation
import SwiftData

@Model
final class UserProfile {
    var activePlan: String = "01"
    var streak: Int = 0
    var longestStreak: Int = 0
    var lastStudyDate: Date?
    var startDate: Date = Date.now
    var dailyGoal: Int = 5
    var speechRate: Double = 0.48
    var hasOnboarded: Bool = false
    var reminderHour: Int = 20
    var aiBaseURL: String = "https://api.openai.com/v1"
    var aiModel: String = "gpt-4o-mini"
    var aiQuotaPerDay: Int = 30
    var aiQuotaUsed: Int = 0
    var aiQuotaDate: Date?

    init() {}
}
