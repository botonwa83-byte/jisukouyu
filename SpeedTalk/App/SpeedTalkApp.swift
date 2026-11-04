import SwiftUI
import SwiftData

@main
struct SpeedTalkApp: App {
    private let container: AppContainer
    private let modelContainer: ModelContainer

    init() {
        do {
            let container = try AppContainer.live()
            self.container = container
            self.modelContainer = container.modelContainer
        } catch {
            fatalError("内容或数据库加载失败：\(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .modelContainer(modelContainer)
        }
    }
}
