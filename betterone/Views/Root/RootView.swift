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

    var body: some View {
        @Bindable var appState = appState
        ZStack(alignment: .bottom) {
            Group {
                switch appState.selectedTab {
                case 0:
                    CoachingNavigationView()
                case 1:
                    HistoryNavigationView()
                case 2:
                    NavigationStack {
                        SettingsView()
                    }
                case 3:
                    NavigationStack {
                        SearchView()
                            .navigationDestination(for: Topic.self) { topic in
                                ChatView(topic: topic)
                            }
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
                            isSelected: appState.selectedTab == 0
                        ) { appState.selectedTab = 0 }

                        TabButton(
                            icon: "clock.fill",
                            label: "History",
                            isSelected: appState.selectedTab == 1
                        ) { appState.selectedTab = 1 }

                        TabButton(
                            icon: "gearshape.fill",
                            label: "Settings",
                            isSelected: appState.selectedTab == 2
                        ) { appState.selectedTab = 2 }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .glassEffect(.regular, in: .capsule)

                    // Circular search button — plain glass, content shows through
                    Button { appState.selectedTab = 3 } label: {
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

struct HistoryNavigationView: View {
    var body: some View {
        NavigationStack {
            HistoryView()
                .navigationDestination(for: ChatSession.self) { session in
                    HistoryDetailView(session: session)
                }
        }
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
