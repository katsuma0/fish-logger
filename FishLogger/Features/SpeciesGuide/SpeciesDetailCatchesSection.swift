import SwiftData
import SwiftUI

/// "Your catches" on a species page: totals, measured records, and the latest entries.
struct SpeciesDetailCatchesSection: View {
    /// Catches of one species, newest first.
    let catches: [FishCatch]
    let onOpen: (FishCatch) -> Void

    @Environment(AppSettings.self) private var settings

    private static let recentLimit = 10

    init(catches: [FishCatch], onOpen: @escaping (FishCatch) -> Void) {
        self.catches = catches
        self.onOpen = onOpen
    }

    var body: some View {
        Section {
            if catches.isEmpty {
                Text("None logged yet.")
                    .foregroundStyle(.secondary)
            } else {
                LabeledContent("Fish logged", value: "\(totalFish)")
                LabeledContent("Trips", value: "\(tripCount)")
                if let longest {
                    LabeledContent("Longest measured", value: settings.length(longest))
                }
                if let heaviest {
                    LabeledContent("Heaviest measured", value: settings.weight(heaviest))
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
            if catches.count > Self.recentLimit {
                Text("Showing the \(Self.recentLimit) most recent entries.")
            }
        }
    }

    // MARK: Numbers

    private var recentCatches: [FishCatch] {
        Array(catches.prefix(Self.recentLimit))
    }

    private var totalFish: Int {
        catches.reduce(0) { $0 + $1.count }
    }

    private var tripCount: Int {
        Set(catches.compactMap { $0.trip?.id }).count
    }

    /// Measured fish only, so a bucketed "trophy" never passes for a record.
    private var longest: Double? {
        catches.compactMap { $0.lengthCm }.max()
    }

    private var heaviest: Double? {
        catches.compactMap { $0.weightKg }.max()
    }

    /// Newest first, so the latest is the first one.
    private var lastCaught: Date? {
        catches.first?.timestamp
    }
}
