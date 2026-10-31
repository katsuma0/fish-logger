import SwiftData
import SwiftUI
import UIKit

/// Counts, CSV export, sample trips, and the delete-everything button.
/// Nothing here watches the whole log: the counts come from `fetchCount` when the section shows
/// up or after an action here, and the CSV is only built when Export is tapped, off the main thread.
struct SettingsDataSection: View {
    @Environment(\.modelContext) private var modelContext

    @State private var counts = SettingsLogCounts()
    @State private var isExporting = false
    @State private var exportFile: SettingsExportFile?
    @State private var exportFailed = false
    @State private var confirmingDeleteAll = false

    var body: some View {
        Section {
            LabeledContent("Trips", value: counts.trips.formatted())
                // Counting is cheap, so it runs each time the section comes into view, which
                // includes coming back to Settings after logging on Today.
                .onAppear { refreshCounts() }
            LabeledContent("Catches", value: counts.catches.formatted())
            LabeledContent("Photos", value: counts.photos.formatted())

            Button {
                export()
            } label: {
                HStack(spacing: 12) {
                    Label(isExporting ? "Preparing export" : "Export CSV", systemImage: "square.and.arrow.up")
                    if isExporting {
                        Spacer(minLength: 8)
                        ProgressView()
                    }
                }
            }
            .disabled(isExporting || counts.trips == 0)
            .sheet(item: $exportFile) { file in
                SettingsShareSheet(items: [file.url], onFinish: { exportFile = nil })
                    .presentationDetents([.medium, .large])
                    .ignoresSafeArea()
            }
        } header: {
            Text("Your data")
        } footer: {
            Text(exportFooter)
        }

        Section {
            Button {
                SampleData.addSampleTrips(in: modelContext)
                refreshCounts()
            } label: {
                Label("Add sample trips", systemImage: "plus.square.on.square")
            }
            Button(role: .destructive) {
                SampleData.deleteSampleTrips(in: modelContext)
                Haptics.warning()
                refreshCounts()
            } label: {
                Label("Delete sample trips", systemImage: "minus.square")
            }
            .disabled(counts.sampleTrips == 0)
        } header: {
            Text("Sample data")
        } footer: {
            Text("Adds 20 made-up trips from the last 60 days so you can try the stats. Remove them with Delete sample trips.")
        }

        Section {
            Button(role: .destructive) {
                confirmingDeleteAll = true
            } label: {
                Label("Delete everything", systemImage: "trash")
            }
            .disabled(counts.isEmpty)
            .confirmationDialog("Delete everything?", isPresented: $confirmingDeleteAll, titleVisibility: .visible) {
                Button(deleteButtonTitle, role: .destructive) {
                    deleteEverything()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(deleteMessage)
            }
        } footer: {
            Text("Export a CSV first if you want a copy.")
        }
    }

    // MARK: Counts

    private func refreshCounts() {
        counts = SettingsLogCounts(
            trips: (try? modelContext.fetchCount(FetchDescriptor<Trip>())) ?? 0,
            catches: (try? modelContext.fetchCount(FetchDescriptor<FishCatch>())) ?? 0,
            photos: (try? modelContext.fetchCount(FetchDescriptor<CatchPhoto>())) ?? 0,
            sampleTrips: SampleData.sampleTripCount(in: modelContext)
        )
    }

    // MARK: Export

    private var exportFooter: String {
        if exportFailed {
            return "Could not write the export file. Try again."
        }
        return "One row per catch, with the trip's place, conditions, and notes on every row. Opens in Numbers, Excel, or Google Sheets."
    }

    /// The fetch, the copy out of the models, and the file all happen in a detached task on its own
    /// context, so a season of catches never holds up the screen. The main actor only saves,
    /// flips `isExporting`, and shows the file.
    private func export() {
        guard !isExporting else { return }
        isExporting = true
        exportFailed = false
        // A background context only sees saved rows, so edits still waiting for autosave go first.
        if modelContext.hasChanges {
            CatchLogger.save(modelContext)
        }
        // The environment's container, not AppModelContainer.shared, so previews and tests export
        // their own store.
        let container = modelContext.container
        let now = Date.now
        Task {
            let written = Task.detached(priority: .userInitiated) { () -> URL? in
                let context = ModelContext(container)
                var descriptor = FetchDescriptor<Trip>(sortBy: [SortDescriptor(\.startDate)])
                descriptor.relationshipKeyPathsForPrefetching = [\.catches]
                let trips = (try? context.fetch(descriptor)) ?? []
                let records = CSVExporter.records(from: trips)
                return try? CSVExporter.writeFile(records: records, on: now)
            }
            let url = await written.value
            isExporting = false
            if let url {
                exportFile = SettingsExportFile(url: url)
            } else {
                exportFailed = true
                Haptics.error()
            }
        }
    }

    // MARK: Delete

    private var deleteButtonTitle: String {
        counts.trips == 0 ? "Delete all catches" : "Delete \(Self.counted(counts.trips, "trip", "trips"))"
    }

    private var deleteMessage: String {
        let tripsText = Self.counted(counts.trips, "trip", "trips")
        let catchesText = Self.counted(counts.catches, "catch", "catches")
        let photosText = Self.counted(counts.photos, "photo", "photos")
        return "This removes \(tripsText), \(catchesText), and \(photosText) from this iPhone. It cannot be undone."
    }

    /// One save for everything, so the other tabs redraw once instead of once per trip.
    private func deleteEverything() {
        let trips = (try? modelContext.fetch(FetchDescriptor<Trip>())) ?? []
        // Catches with no trip and photos with no catch would otherwise linger in the counts.
        let strayCatches = (try? modelContext.fetch(FetchDescriptor<FishCatch>(predicate: #Predicate<FishCatch> { $0.trip == nil }))) ?? []
        let strayPhotos = (try? modelContext.fetch(FetchDescriptor<CatchPhoto>(predicate: #Predicate<CatchPhoto> { $0.fishCatch == nil }))) ?? []
        for photo in strayPhotos {
            modelContext.delete(photo)
        }
        for fishCatch in strayCatches {
            for photo in fishCatch.photos { modelContext.delete(photo) }
            modelContext.delete(fishCatch)
        }
        if trips.isEmpty {
            CatchLogger.save(modelContext)
        } else {
            // Saves once, including the stray deletes above.
            CatchLogger.deleteAll(trips, in: modelContext)
        }
        exportFile = nil
        Haptics.warning()
        refreshCounts()
    }

    private static func counted(_ count: Int, _ singular: String, _ plural: String) -> String {
        "\(count.formatted()) \(count == 1 ? singular : plural)"
    }
}

/// What the section shows, read with `fetchCount` instead of live queries over every row.
private struct SettingsLogCounts {
    var trips = 0
    var catches = 0
    var photos = 0
    var sampleTrips = 0

    var isEmpty: Bool { trips == 0 && catches == 0 && photos == 0 }
}

/// The finished export, as a sheet item.
private struct SettingsExportFile: Identifiable {
    let url: URL
    var id: URL { url }
}

/// The system share sheet. SwiftUI's ShareLink needs the file before it is tapped, which is what
/// made the old export rebuild the CSV in the background of every visit.
private struct SettingsShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    /// Runs when the person shares, saves, or closes the sheet, so the hosting sheet closes with it.
    let onFinish: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onFinish()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
