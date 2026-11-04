import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        if let profile = profiles.first, profile.hasOnboarded {
            ContentView()
        } else {
            OnboardingView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("今日", systemImage: "sun.max") }
            CourseView()
                .tabItem { Label("课表", systemImage: "list.bullet.rectangle") }
            SceneGridView()
                .tabItem { Label("场景", systemImage: "square.grid.2x2") }
            TalkView()
                .tabItem { Label("对练", systemImage: "bubble.left.and.bubble.right") }
            MeView()
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
        }
        .tint(Theme.accent)
    }
}
