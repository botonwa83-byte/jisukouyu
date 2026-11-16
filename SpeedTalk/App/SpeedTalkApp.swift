import SwiftUI
import SwiftData
import UIKit

@main
struct SpeedTalkApp: App {
    @Environment(\.scenePhase) private var scenePhase

    private let container: AppContainer
    private let modelContainer: ModelContainer

    init() {
        // 标题换成暖可可色，别让系统纯黑打断糖果暖调。
        let warmInk = UIColor { $0.userInterfaceStyle == .dark ? .init(red: 0.965, green: 0.929, blue: 0.894, alpha: 1) : .init(red: 0.294, green: 0.227, blue: 0.2, alpha: 1) }
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: warmInk]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: warmInk]
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
                .onChange(of: scenePhase) { _, phase in
                    // 切后台立即还回音频会话，别一直占着麦克风、压着别的 App。
                    if phase == .background {
                        AudioSessionManager.shared.deactivate()
                    }
                }
        }
    }
}
