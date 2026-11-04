import Foundation
import SwiftData

@Model
final class DailyLog {
    @Attribute(.unique) var dateKey: String
    var plan: String
    var stage: String
    var day: Int
    var completedCount: Int = 0
    var totalScore: Int = 0
    var isCheckedIn: Bool = false

    init(dateKey: String, plan: String, stage: String, day: Int) {
        self.dateKey = dateKey
        self.plan = plan
        self.stage = stage
        self.day = day
    }
}
