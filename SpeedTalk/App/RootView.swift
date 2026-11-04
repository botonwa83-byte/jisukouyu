import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var planProgress: [PlanProgress]

    var body: some View {
        Group {
            if let profile = profiles.first, profile.hasOnboarded {
                ContentView()
            } else if skipOnboardingForSmokeTest {
                ContentView()
            } else {
                OnboardingView()
            }
        }
        .task {
            seedForSmokeTestIfNeeded()
            resetAdvanceBudgetIfNeeded()
        }
    }

    /// 仅 Debug 构建支持 `-skipOnboarding`，用于模拟器冒烟与截图验收。
    private var skipOnboardingForSmokeTest: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-skipOnboarding")
        #else
        false
        #endif
    }

    private func seedForSmokeTestIfNeeded() {
        #if DEBUG
        guard skipOnboardingForSmokeTest, profiles.isEmpty else { return }
        let profile = UserProfile()
        profile.hasOnboarded = true
        profile.activePlan = "01"
        modelContext.insert(profile)
        modelContext.insert(PlanProgress(planID: "01"))
        try? modelContext.save()
        #endif
    }

    /// 仅 Debug 构建支持 `-resetAdvanceBudget`：清掉跨用例残留的当日推进额度。
    private func resetAdvanceBudgetIfNeeded() {
        #if DEBUG
        guard ProcessInfo.processInfo.arguments.contains("-resetAdvanceBudget") else { return }
        var changed = false
        for plan in planProgress where plan.advanceDate != nil || plan.advanceCount != 0 {
            plan.advanceDate = nil
            plan.advanceCount = 0
            changed = true
        }
        if changed { try? modelContext.save() }
        #endif
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
    @State private var selection: AppSection? = SplitRootView.initialSection

    /// Debug 构建可用 `-section=course` 指定首屏，便于 iPad 分栏截图验收。
    private static var initialSection: AppSection {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.arguments
            .first(where: { $0.hasPrefix("-section=") })?
            .split(separator: "=").last,
           let section = AppSection(rawValue: String(raw)) {
            return section
        }
        #endif
        return .today
    }

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
