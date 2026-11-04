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

enum AppSection: String, CaseIterable, Identifiable {
    case today, course, scenes, talk, me

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "今日"
        case .course: return "课表"
        case .scenes: return "场景"
        case .talk: return "对练"
        case .me: return "我的"
        }
    }

    var symbol: String {
        switch self {
        case .today: return "sun.max"
        case .course: return "list.bullet.rectangle"
        case .scenes: return "square.grid.2x2"
        case .talk: return "bubble.left.and.bubble.right"
        case .me: return "person.crop.circle"
        }
    }
}

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            SplitRootView()
        } else {
            TabRootView()
        }
    }
}

struct TabRootView: View {
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

struct SplitRootView: View {
    @State private var selection: AppSection? = .today

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.symbol)
                    .tag(section)
            }
            .navigationTitle("极速口语")
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 280)
        } detail: {
            switch selection ?? .today {
            case .today: TodayView()
            case .course: CourseView()
            case .scenes: SceneGridView()
            case .talk: TalkView()
            case .me: MeView()
            }
        }
        .tint(Theme.accent)
    }
}
