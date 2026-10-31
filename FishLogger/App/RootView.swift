import SwiftData
import SwiftUI
import UIKit

enum AppTab: String {
    case today, history, stats, species, settings
}

struct RootView: View {
    @SceneStorage("selectedTab") private var selectedTab: AppTab = .today
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(filter: #Predicate<Trip> { $0.endDate == nil }) private var activeTrips: [Trip]

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "fish") }
                .tag(AppTab.today)
            HistoryView()
                .tabItem { Label("Log", systemImage: "calendar") }
                .tag(AppTab.history)
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
                .tag(AppTab.stats)
            SpeciesGuideView()
                .tabItem { Label("Species", systemImage: "book") }
                .tag(AppTab.species)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .fullScreenCover(isPresented: needsWelcome) {
            OnboardingView(onFinish: {})
                .environment(settings)
                .appTextSize(settings.textSize)
        }
        .onAppear(perform: syncSessionState)
        .onChange(of: activeTrips.count) { syncSessionState() }
        .onChange(of: settings.keepScreenOn) { syncSessionState() }
        .onChange(of: scenePhase) { syncSessionState() }
    }

    /// Finishing or skipping setup flips the setting, which closes the cover.
    private var needsWelcome: Binding<Bool> {
        Binding(get: { !settings.hasSeenWelcome }, set: { _ in })
    }

    /// Sensors and the screen-awake flag follow whether a trip is running.
    private func syncSessionState() {
        let tripRunning = !activeTrips.isEmpty
        UIApplication.shared.isIdleTimerDisabled = tripRunning && settings.keepScreenOn && scenePhase == .active
        if tripRunning, scenePhase == .active {
            CatchLogger.startSensors()
        } else if !tripRunning {
            CatchLogger.stopSensors()
        }
    }
}
