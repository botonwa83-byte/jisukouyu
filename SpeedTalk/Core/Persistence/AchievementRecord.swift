import Foundation
import SwiftData

@Model
final class AchievementRecord {
    @Attribute(.unique) var achievementID: String
    var unlockedAt: Date

    init(achievementID: String, unlockedAt: Date = Date.now) {
        self.achievementID = achievementID
        self.unlockedAt = unlockedAt
    }
}
