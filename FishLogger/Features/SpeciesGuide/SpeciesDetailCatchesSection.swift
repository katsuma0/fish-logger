import SwiftData
import SwiftUI

/// "Your catches" on a species page: totals, measured records, and the latest entries.
/// The totals come in worked out already, so this never walks every catch of the species in `body`.
struct SpeciesDetailCatchesSection: View {
    /// The latest catches of one species, newest first. At most `recentLimit` are shown.
    let catches: [FishCatch]
    /// Over every catch of the species. Nil until the first count is done, so no "0" flashes up.
    let totals: SpeciesCatchTotals?
    let onOpen: (FishCatch) -> Void

    @Environment(AppSettings.self) private var settings

    /// The species page fetches only this many rows.
    static let recentLimit = 10

    init(catches: [FishCatch], totals: SpeciesCatchTotals?, onOpen: @escaping (FishCatch) -> Void) {
        self.catches = catches
        self.totals = totals
        self.onOpen = onOpen
    }

    var body: some View {
        Section {
            if catches.isEmpty {
                Text("None logged yet.")
                    .foregroundStyle(.secondary)
            } else {
                if let totals {
                    LabeledContent("Fish logged", value: "\(totals.fish)")
                    LabeledContent("Trips", value: "\(totals.trips)")
                    if let longest = totals.longestCm {
                        LabeledContent("Longest measured", value: settings.length(longest))
                    }
                    if let heaviest = totals.heaviestKg {
                        LabeledContent("Heaviest measured", value: settings.weight(heaviest))
                    }
                }
                if let lastCaught {
                    LabeledContent("Last caught", value: lastCaught.formatted(date: .abbreviated, time: .omitted))
                }

                ForEach(recentCatches) { fishCatch in
                    Button {
                        onOpen(fishCatch)
                    } label: {
                        // These come from many days, so every row shows its date.
                        CatchRow(fishCatch: fishCatch, showsDate: true)
                    }
                    .foregroundStyle(.primary)
                    .accessibilityHint("Opens the catch details")
                }
            }
        } header: {
            Text("Your catches")
        } footer: {
            if (totals?.entries ?? 0) > Self.recentLimit {
                Text("Showing the \(Self.recentLimit) most recent entries.")
            }
        }
    }

    // MARK: Numbers

    private var recentCatches: [FishCatch] {
        Array(catches.prefix(Self.recentLimit))
    }

    /// Newest first, so the latest is the first one.
    private var lastCaught: Date? {
        catches.first?.timestamp
    }
}
