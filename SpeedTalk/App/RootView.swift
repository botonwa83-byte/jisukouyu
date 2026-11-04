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
        Text("今日")
    }
}
