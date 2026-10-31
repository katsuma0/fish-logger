import SwiftData
import SwiftUI
import UIKit

enum AppTab: String {
    case today, history, stats, species, settings
}

struct RootView: View {
    /// Away longer than this with a trip running, and the app comes back on Today, ready to log.
    /// Shorter app switches keep the tab the person was on.
    private static let awayInterval: TimeInterval = 120

    @SceneStorage("selectedTab") private var selectedTab: AppTab = .today
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(filter: #Predicate<Trip> { $0.endDate == nil }) private var activeTrips: [Trip]
    @State private var backgroundedAt: Date?
    @State private var hasLaunched = false

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "fish") }
                .tag(AppTab.today)
            HistoryView()
                .tabItem { Label("Trips", systemImage: "calendar") }
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
        .onAppear(perform: launch)
        .onChange(of: activeTrips.count) { syncSessionState() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                backgroundedAt = .now
            case .active:
                returnToTodayIfAway()
            default:
                break
            }
            syncSessionState()
        }
    }

    /// A cold launch during a trip opens on Today, whatever tab was saved, because the app was
    /// most likely closed for a while.
    private func launch() {
        if !hasLaunched {
            hasLaunched = true
            if !activeTrips.isEmpty { selectedTab = .today }
        }
        syncSessionState()
    }

    private func returnToTodayIfAway() {
        let awayFor = backgroundedAt.map { Date.now.timeIntervalSince($0) } ?? 0
        backgroundedAt = nil
        if awayFor > Self.awayInterval, !activeTrips.isEmpty {
            selectedTab = .today
        }
    }

    /// Finishing or skipping setup flips the setting, which closes the cover.
    private var needsWelcome: Binding<Bool> {
        Binding(get: { !settings.hasSeenWelcome }, set: { _ in })
    }

    /// GPS and the barometer follow whether a trip is running.
    private func syncSessionState() {
        let tripRunning = !activeTrips.isEmpty
        if tripRunning, scenePhase == .active {
            CatchLogger.startSensors()
        } else if !tripRunning {
            CatchLogger.stopSensors()
        }
    }
}
