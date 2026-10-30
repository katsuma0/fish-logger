import SwiftData
import SwiftUI

@main
struct FishLoggerApp: App {
    @State private var settings = AppSettings.shared

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

    /// Throwaway store for previews and tests.
    @MainActor
    static func inMemory() -> ModelContainer {
        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
        } catch {
            fatalError("Could not create an in-memory store: \(error)")
        }
    }
}
