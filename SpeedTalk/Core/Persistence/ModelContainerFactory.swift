import Foundation
import SwiftData

enum ModelContainerFactory {
    static let schema = Schema([
        UserProfile.self,
        PlanProgress.self,
        PhraseProgress.self,
        DailyLog.self,
        AchievementRecord.self
    ])

    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
