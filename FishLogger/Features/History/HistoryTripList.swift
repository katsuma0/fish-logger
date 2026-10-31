import SwiftData
import SwiftUI

/// Trips grouped by calendar day, newest day first, with a fish total per day.
struct HistoryTripList: View {
    let trips: [Trip]

    @Environment(\.modelContext) private var modelContext
    @State private var pendingDelete: HistoryTripDeleteRequest? = nil

    init(trips: [Trip]) {
        self.trips = trips
    }

    var body: some View {
        let groups = HistoryTripFilter.groupedByDay(trips)
        List {
            ForEach(groups) { group in
                Section {
                    ForEach(group.trips) { trip in
                        NavigationLink {
                            TripDetailView(trip: trip)
                        } label: {
                            HistoryTripRow(trip: trip)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            // Not a destructive role: that removes the row before the angler confirms.
                            Button {
                                pendingDelete = HistoryTripDeleteRequest(
                                    trip: trip,
                                    message: HistoryText.deleteMessage(for: trip)
                                )
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                } header: {
                    HistoryDayHeader(group: group)
                }
            }
        }
        .listStyle(.insetGrouped)
        .confirmationDialog(
            "Delete this trip?",
            isPresented: isConfirmingDelete,
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { request in
            Button("Delete trip", role: .destructive) {
                delete(request.trip)
            }
            Button("Cancel", role: .cancel) {}
        } message: { request in
            Text(request.message)
        }
    }

    private var isConfirmingDelete: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { isPresented in
                if !isPresented { pendingDelete = nil }
            }
        )
    }

    private func delete(_ trip: Trip) {
        // Clear the request first so nothing reads the trip after it is gone.
        pendingDelete = nil
        CatchLogger.delete(trip, in: modelContext)
        Haptics.warning()
    }
}

/// The message is worked out up front so the dialog never reads a trip that was just deleted.
private struct HistoryTripDeleteRequest {
    let trip: Trip
    let message: String
}

private struct HistoryDayHeader: View {
    let group: HistoryDayGroup

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(group.title)
            Spacer(minLength: 8)
            Text(HistoryText.fish(group.totalFish))
                .monospacedDigit()
        }
        .font(.subheadline.weight(.semibold))
        .textCase(nil)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
