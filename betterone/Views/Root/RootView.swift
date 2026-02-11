import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.onboardingComplete {
            MainTabView()
        } else {
            OnboardingContainerView()
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0:
                    CoachingNavigationView()
                case 1:
                    NavigationStack {
                        SettingsView()
                    }
                case 2:
                    NavigationStack {
                        Text("Search")
                            .font(.title)
                            .navigationTitle("Search")
                    }
                default:
                    CoachingNavigationView()
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)

            if appState.showTabBar {
                // Floating tab bar + search button
                HStack(spacing: 14) {
                    // Pill-shaped tab bar
                    HStack(spacing: 0) {
                        TabButton(
                            icon: "house.fill",
                            label: "Home",
                            isSelected: selectedTab == 0
                        ) { selectedTab = 0 }

                        TabButton(
                            icon: "gearshape.fill",
                            label: "Settings",
                            isSelected: selectedTab == 1
                        ) { selectedTab = 1 }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .glassEffect(.regular, in: .capsule)

                    // Circular search button — plain glass, content shows through
                    Button { selectedTab = 2 } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 52, height: 52)
                    }
                    .glassEffect(.regular, in: .circle)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(Theme.animationDefault, value: appState.showTabBar)
    }
}

struct TabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20))

                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isSelected ? Theme.accent : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Theme.accent.opacity(0.15))
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct CoachingNavigationView: View {
    var body: some View {
        NavigationStack {
            HomeView()
                .navigationDestination(for: SectionSelection.self) { section in
                    SectionDetailView(selection: section)
                }
                .navigationDestination(for: Topic.self) { topic in
                    ChatView(topic: topic)
                }
        }
    }
}
