import AppIntents

/// Siri phrases that work with no setup. Every phrase names the app, which App Shortcuts requires.
struct FishLoggerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogCatchIntent(),
            phrases: [
                "Log a \(\.$species) in \(.applicationName)",
                "Log \(\.$species) in \(.applicationName)",
                "Log a fish in \(.applicationName)"
            ],
            shortTitle: "Log a Catch",
            systemImageName: "fish"
        )
        AppShortcut(
            intent: StartTripIntent(),
            phrases: [
                "Start fishing in \(.applicationName)",
                "Start a trip in \(.applicationName)"
            ],
            shortTitle: "Start Fishing",
            systemImageName: "figure.fishing"
        )
        AppShortcut(
            intent: EndTripIntent(),
            phrases: [
                "End fishing in \(.applicationName)",
                "End my trip in \(.applicationName)"
            ],
            shortTitle: "End Trip",
            systemImageName: "flag.checkered"
        )
    }
}
