import SwiftUI

/// What the fish section on Today can do, from a tap, the long-press menu, or VoiceOver. The tiles
/// and the list take the same set, so both views offer the same things.
struct TodayFishActions {
    let onLog: (Species, Int) -> Void
    /// Lists this trip's catches of the species, to add notes and details.
    let onDetails: (Species) -> Void
    /// Asks before removing this trip's catches of the species.
    let onReset: (Species) -> Void
    let onOtherFish: () -> Void
    let onPhotoID: () -> Void
}

extension View {
    /// The long-press menu and the matching VoiceOver actions for one fish. Details and Reset show
    /// only once the fish has catches on the running trip.
    func todayFishMenu(species: Species, count: Int, actions: TodayFishActions) -> some View {
        modifier(TodayFishMenu(species: species, count: count, actions: actions))
    }
}

struct TodayFishMenu: ViewModifier {
    let species: Species
    let count: Int
    let actions: TodayFishActions

    @Environment(AppSettings.self) private var settings

    init(species: Species, count: Int, actions: TodayFishActions) {
        self.species = species
        self.count = count
        self.actions = actions
    }

    func body(content: Content) -> some View {
        let isFavourite = settings.isFavourite(species.id)
        let favouriteTitle = isFavourite ? "Remove from favourites" : "Add to favourites"
        let hasCatches = count > 0
        return content
            .contextMenu {
                Button { actions.onLog(species, 2) } label: { Label("Log 2", systemImage: "2.circle") }
                Button { actions.onLog(species, 3) } label: { Label("Log 3", systemImage: "3.circle") }
                Button { actions.onLog(species, 5) } label: { Label("Log 5", systemImage: "5.circle") }
                if hasCatches {
                    Divider()
                    Button { actions.onDetails(species) } label: { Label("Details", systemImage: "info.circle") }
                    Button(role: .destructive) {
                        actions.onReset(species)
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                }
                Divider()
                Button {
                    settings.toggleFavourite(species.id)
                } label: {
                    Label(favouriteTitle, systemImage: isFavourite ? "star.slash" : "star")
                }
            }
            // One builder, so Details and Reset come and go without the fish losing VoiceOver focus.
            .accessibilityActions {
                Button("Log 2") { actions.onLog(species, 2) }
                Button("Log 3") { actions.onLog(species, 3) }
                Button("Log 5") { actions.onLog(species, 5) }
                if hasCatches {
                    Button("Details") { actions.onDetails(species) }
                    Button("Reset") { actions.onReset(species) }
                }
                Button(favouriteTitle) { settings.toggleFavourite(species.id) }
            }
    }
}

/// The one line under the fish while there are no favourites yet.
struct TodayFishFootnote: View {
    let text: String

    init(text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
