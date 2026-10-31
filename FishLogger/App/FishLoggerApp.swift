import SwiftData
import SwiftUI

@main
struct FishLoggerApp: App {
    @State private var settings = AppSettings.shared

    init() {
        // Lets Siri match species names in phrases like "Log a walleye in Fish Logger".
        FishLoggerShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .preferredColorScheme(settings.appearance.colorScheme)
                .appTextSize(settings.textSize)
        }
        .modelContainer(AppModelContainer.shared)
    }
}

enum AppModelContainer {
    static let schema = Schema([Trip.self, FishCatch.self, CatchPhoto.self])

    /// One container for the app and App Intents, so Siri logs land in the same store.
    @MainActor
    static let shared: ModelContainer = {
        do {
            return try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema)])
        } catch {
            fatalError("Could not open the fish log: \(error)")
        }
    }()

    /// Throwaway store for previews and tests. Each one is kept for the life of the process: a
    /// SwiftUI view can hold the main context a little longer than its test holds the container,
    /// and SwiftData traps when that context tries to autosave on app resign with its container gone.
    @MainActor
    static func inMemory() -> ModelContainer {
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
            kept.append(container)
            return container
        } catch {
            fatalError("Could not create an in-memory store: \(error)")
        }
    }

    @MainActor private static var kept: [ModelContainer] = []
}
