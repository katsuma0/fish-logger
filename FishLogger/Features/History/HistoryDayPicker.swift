import SwiftData
import SwiftUI

/// Calendar for finding one day of fishing. Under the calendar it lists that day's trips, or the nearest
/// days that have trips, so a blank day is never a dead end. Done filters the Trips list to the day.
struct HistoryDayPickerSheet: View {
    let trips: [Trip]
    let onPick: (Date) -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var day: Date
    /// Trips by the start of their day, worked out once when the sheet opens rather than per render.
    @State private var tripsByDay: [Date: [Trip]] = [:]
    /// Days with trips, oldest first.
    @State private var tripDays: [Date] = []
    @State private var isIndexed = false

    /// - Parameter trips: every trip, newest first, as the Trips tab queries them.
    init(trips: [Trip], initialDay: Date, onPick: @escaping (Date) -> Void) {
        self.trips = trips
        self.onPick = onPick
        _day = State(initialValue: initialDay)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker("Day", selection: $day, in: ...latestDay, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                if isIndexed {
                    daySection
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Pick a day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onPick(day)
                        dismiss()
                    }
                }
            }
            .task { buildIndex() }
        }
    }

    /// Newest trip or today, whichever is later, so no trip is ever out of reach.
    private var latestDay: Date {
        max(Date.now, trips.first?.startDate ?? Date.now)
    }

    @ViewBuilder
    private var daySection: some View {
        let start = Calendar.current.startOfDay(for: day)
        let dayTrips = (tripsByDay[start] ?? []).filter { !$0.historyIsGone }
        if dayTrips.isEmpty {
            Section {
                Text("No trips on this day.")
                    .foregroundStyle(.secondary)
            }
            let earlier = tripDays.last(where: { $0 < start })
            let later = tripDays.first(where: { $0 > start })
            if earlier != nil || later != nil {
                Section("Nearest days with trips") {
                    if let earlier {
                        jumpButton(to: earlier, direction: "Earlier")
                    }
                    if let later {
                        jumpButton(to: later, direction: "Later")
                    }
                }
            }
        } else {
            Section("Trips this day") {
                ForEach(dayTrips) { trip in
                    HistoryDayPickerTripRow(trip: trip)
                }
            }
        }
    }

    private func jumpButton(to target: Date, direction: String) -> some View {
        Button {
            day = target
        } label: {
            HStack(spacing: 8) {
                Text(HistoryText.dayTitle(target))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                Text(direction)
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: settings.buttonSize.minTapSize)
            .contentShape(Rectangle())
        }
        .accessibilityHint("Shows this day in the calendar")
    }

    private func buildIndex() {
        guard !isIndexed else { return }
        let calendar = Calendar.current
        var byDay: [Date: [Trip]] = [:]
        for trip in trips where !trip.historyIsGone {
            byDay[calendar.startOfDay(for: trip.startDate), default: []].append(trip)
        }
        tripsByDay = byDay
        tripDays = byDay.keys.sorted()
        isIndexed = true
    }
}

/// A trip under the calendar: where, when, and how many fish. Plain text, since Done is what acts.
private struct HistoryDayPickerTripRow: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(trip.displayName)
                .font(.body)
                .foregroundStyle(.primary)
            Text("\(trip.historyTimeRange), \(HistoryText.fish(trip.totalFish))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
