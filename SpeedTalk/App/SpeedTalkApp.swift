import SwiftUI
import SpeedTalkCore

@main
struct SpeedTalkApp: App {
    var body: some Scene {
        WindowGroup {
            Text("极速口语 \(SpeedTalkCore.version)")
        }
    }
}
