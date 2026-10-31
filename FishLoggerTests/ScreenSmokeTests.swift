import Foundation
import SwiftData
import SwiftUI
import Testing
import UIKit
@testable import FishLogger

/// Opens every tab and the main pushed and sheet screens in a phone-sized window, over a throwaway
/// store with one finished trip and two catches, and checks each one comes up. Catches crashes and
/// missing environment on open, not layout.
///
/// Serialized because every test swaps `AppSettings.shared.hasSeenWelcome` and makes its own window key.
@MainActor
@Suite(.serialized)
struct ScreenSmokeTests {
    /// Held by the suite so it outlives every model a screen touches.
    let container: ModelContainer
    let trip: Trip
    let walleyeCatch: FishCatch
    let perchCatch: FishCatch

    /// iPhone 15 and 16 in points.
    private static let phoneFrame = CGRect(x: 0, y: 0, width: 390, height: 844)

    init() throws {
        let container = AppModelContainer.inMemory()
        let context = container.mainContext

        // Finished an hour ago, so nothing starts sensors or the stale trip card.
        let start = Date(timeIntervalSinceNow: -3 * 3600)
        let trip = Trip(
            startDate: start,
            locationName: "Lake Simcoe",
            latitude: 44.43,
            longitude: -79.33,
            waterBody: .lake,
            method: .boat
        )
        trip.endDate = Date(timeIntervalSinceNow: -3600)
        context.insert(trip)

        let walleyeCatch = FishCatch(speciesID: "walleye", timestamp: start.addingTimeInterval(1800), lengthCm: 55, weightKg: 1.8)
        walleyeCatch.lure = "Jig"
        walleyeCatch.latitude = 44.431
        walleyeCatch.longitude = -79.332
        context.insert(walleyeCatch)
        walleyeCatch.trip = trip

        let perchCatch = FishCatch(speciesID: "yellow_perch", timestamp: start.addingTimeInterval(3600), count: 3, sizeClass: .small)
        perchCatch.released = false
        context.insert(perchCatch)
        perchCatch.trip = trip

        try context.save()

        self.container = container
        self.trip = trip
        self.walleyeCatch = walleyeCatch
        self.perchCatch = perchCatch
    }

    // MARK: Tabs

    @Test func rootViewOpens() async throws {
        try await expectScreenOpens(RootView())
    }

    @Test func todayOpens() async throws {
        try await expectScreenOpens(TodayView())
    }

    @Test func historyOpens() async throws {
        try await expectScreenOpens(HistoryView())
    }

    @Test func statsOpens() async throws {
        try await expectScreenOpens(StatsView())
    }

    @Test func speciesGuideOpens() async throws {
        try await expectScreenOpens(SpeciesGuideView())
    }

    @Test func settingsOpens() async throws {
        try await expectScreenOpens(SettingsView())
    }

    // MARK: First launch

    /// Left at whatever the welcome flag already is, the same as the cover RootView shows.
    @Test func onboardingOpens() async throws {
        try await expectScreenOpens(OnboardingView(onFinish: {}), hasSeenWelcome: nil)
    }

    // MARK: Pushed screens and sheets

    @Test func catchEditorOpensForALoggedCatch() async throws {
        try await expectScreenOpens(NavigationStack { CatchEditorView(fishCatch: walleyeCatch) })
    }

    @Test func tripDetailOpens() async throws {
        try await expectScreenOpens(NavigationStack { TripDetailView(trip: trip) })
    }

    @Test func identifyOpens() async throws {
        try await expectScreenOpens(IdentifyView())
    }

    @Test func walleyeDetailOpens() async throws {
        let walleye = try #require(SpeciesCatalog.species(id: "walleye"))
        try await expectScreenOpens(NavigationStack { SpeciesDetailView(species: walleye) })
    }

    @Test func fishingProfileOpens() async throws {
        try await expectScreenOpens(NavigationStack { FishingProfileView() })
    }

    // MARK: Hosting

    /// A screen in its own key window, with the window it replaced as key.
    @MainActor
    private struct HostedScreen {
        let window: UIWindow
        let controller: UIViewController
        let previousKeyWindow: UIWindow?

        /// Takes the screen down while the store is still open, so nothing on it reads a closed store.
        func close() {
            window.isHidden = true
            window.rootViewController = nil
            previousKeyWindow?.makeKey()
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        }
    }

    /// Opens the screen with the app's settings and the test store, lets `onAppear` and `.task`
    /// run, and checks the hosting view is up in the window with nothing presented over it.
    /// `hasSeenWelcome` nil leaves the flag alone; otherwise it is set for the test and put back after.
    private func expectScreenOpens(_ screen: some View, hasSeenWelcome: Bool? = true) async throws {
        let settings = AppSettings.shared
        let savedWelcome = settings.hasSeenWelcome
        if let hasSeenWelcome {
            settings.hasSeenWelcome = hasSeenWelcome
        }
        defer {
            if hasSeenWelcome != nil {
                settings.hasSeenWelcome = savedWelcome
            }
        }

        let hosted = host(screen)
        defer { hosted.close() }

        // `.task` work is queued on the main actor, which the run loop spin in `host` may not drain
        // from inside this test, so step off it for a moment too.
        try await Task.sleep(for: .milliseconds(200))
        hosted.window.layoutIfNeeded()

        let view = try #require(hosted.controller.viewIfLoaded)
        #expect(view.window === hosted.window)
        #expect(hosted.controller.presentedViewController == nil)
    }

    /// Puts the screen in a 390 by 844 key window, lays it out, and runs the main run loop briefly
    /// so layout and `onAppear` happen.
    private func host(_ screen: some View) -> HostedScreen {
        let controller = UIHostingController(
            rootView: screen
                .environment(AppSettings.shared)
                .modelContainer(container)
        )
        let scene = Self.windowScene()
        let previousKeyWindow = scene?.keyWindow
        let window = scene.map { UIWindow(windowScene: $0) } ?? UIWindow(frame: Self.phoneFrame)
        window.frame = Self.phoneFrame
        window.rootViewController = controller
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        return HostedScreen(window: window, controller: controller, previousKeyWindow: previousKeyWindow)
    }

    /// The test host's scene, so the window is really on screen. A window without one still lays out.
    private static func windowScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
    }
}
