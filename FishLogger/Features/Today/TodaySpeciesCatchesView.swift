import SwiftData
import SwiftUI

/// Every catch of one species on the running trip, newest first. Tapping one opens the catch editor
/// for notes, size, lure and the rest. Opened from Details in a fish's long-press menu on Today.
/// Present it inside a NavigationStack, so the editor can push.
struct TodaySpeciesCatchesView: View {
    let trip: Trip
    let species: Species

    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    init(trip: Trip, species: Species) {
        self.trip = trip
        self.species = species
    }

    var body: some View {
        let catches = liveCatches
        List {
            Section {
                if catches.isEmpty {
                    Text("None left on this trip.")
                        .foregroundStyle(.secondary)
                        .frame(minHeight: settings.buttonSize.minTapSize, alignment: .leading)
                } else {
                    ForEach(catches) { fishCatch in
                        // A value link, so the editor stays open when its catch leaves this list
                        // (a new species, say). A destination link would pop with its row.
                        NavigationLink(value: fishCatch) {
                            TodaySpeciesCatchRow(fishCatch: fishCatch)
                        }
                        .accessibilityHint("Opens the catch details")
                    }
                }
            } header: {
                Text("This trip")
            } footer: {
                if !catches.isEmpty {
                    Text("Tap a catch to add notes, size and more.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(for: FishCatch.self) { fishCatch in
            CatchEditorView(fishCatch: fishCatch)
        }
        .navigationTitle(species.commonName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    /// Read fresh on every render, so a catch deleted or moved to another species in the editor
    /// drops out of the list. Reading a deleted model can crash, so those are skipped first.
    private var liveCatches: [FishCatch] {
        guard !trip.isDeleted, trip.modelContext != nil else { return [] }
        let speciesID = species.id
        return trip.catches
            .filter { !$0.isDeleted && $0.modelContext != nil && $0.speciesID == speciesID }
            .sorted { $0.timestamp > $1.timestamp }
    }
}

/// Time and count on the first line, then the size if there is one, then the start of the notes.
private struct TodaySpeciesCatchRow: View {
    let fishCatch: FishCatch

    @Environment(AppSettings.self) private var settings

    init(fishCatch: FishCatch) {
        self.fishCatch = fishCatch
    }

    var body: some View {
        let time = timeText
        let countText = "\(fishCatch.count) fish"
        let size = sizeText
        let notes = notesPreview

        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(time)
                    .font(.body)
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                Text(countText)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            if let size {
                Text(size)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(notes ?? "No notes")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
        .frame(minHeight: settings.buttonSize.minTapSize, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenSummary(time: time, countText: countText, size: size, notes: notes))
    }

    /// The time, with the day in front for a catch from before today on a trip that ran overnight.
    private var timeText: String {
        let timestamp = fishCatch.timestamp
        if Calendar.current.isDateInToday(timestamp) {
            return timestamp.formatted(date: .omitted, time: .shortened)
        }
        return timestamp.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }

    /// Measured length and weight, or the size class. Nil when neither is set.
    private var sizeText: String? {
        var parts: [String] = []
        if let length = fishCatch.lengthCm { parts.append(settings.length(length)) }
        if let weight = fishCatch.weightKg { parts.append(settings.weight(weight)) }
        if !parts.isEmpty { return parts.joined(separator: ", ") }
        return fishCatch.sizeClass?.label
    }

    /// The notes on one line. Nil when there are none.
    private var notesPreview: String? {
        let trimmed = fishCatch.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed.components(separatedBy: .newlines).filter { !$0.isEmpty }.joined(separator: " ")
    }

    private func spokenSummary(time: String, countText: String, size: String?, notes: String?) -> String {
        var parts = [time, countText]
        if let size { parts.append(size) }
        if let notes {
            parts.append("Notes: \(notes)")
        } else {
            parts.append("No notes")
        }
        return parts.joined(separator: ", ")
    }
}
