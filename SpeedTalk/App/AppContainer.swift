import Foundation
import Observation
import SwiftData
import SpeedTalkCore

@Observable
final class AppContainer {
    let content: ContentBundle
    let service: CurriculumService
    let selector: DailySelector
    let engine: ProgressEngine
    let modelContainer: ModelContainer

    init(content: ContentBundle, modelContainer: ModelContainer) {
        self.content = content
        self.service = CurriculumService(curriculum: content.curriculum, library: content.library)
        self.selector = DailySelector(service: service)
        self.engine = ProgressEngine(service: service)
        self.modelContainer = modelContainer
    }

    static func live() throws -> AppContainer {
        let content = try ContentLoader.loadBundled()
        let container = try ModelContainerFactory.make()
        return AppContainer(content: content, modelContainer: container)
    }
}
