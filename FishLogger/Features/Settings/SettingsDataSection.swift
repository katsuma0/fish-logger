import SwiftData
import SwiftUI

/// Counts, CSV export, sample trips, and the delete-everything button.
struct SettingsDataSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.startDate) private var trips: [Trip]
    @Query private var catches: [FishCatch]
    @Query private var photos: [CatchPhoto]

    @State private var exportURL: URL?
    @State private var exportFailed = false
    @State private var confirmingDeleteAll = false

    var body: some View {
        Section {
            LabeledContent("Trips", value: trips.count.formatted())
                // ShareLink needs a finished file before it is tapped, so the CSV is written
                // whenever this section shows up or the log changes size.
                .onAppear { prepareExport() }
                .onChange(of: exportSignature) { prepareExport() }
            LabeledContent("Catches", value: catches.count.formatted())
            LabeledContent("Photos", value: photos.count.formatted())

            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
            } else {
                Button {
                    prepareExport()
                } label: {
                    Label("Prepare export", systemImage: "doc.text")
                }
            }
        } header: {
            Text("Your log")
        } footer: {
            Text(exportFooter)
        }

        Section {
            Button {
                SampleData.addSampleTrips(in: modelContext)
                Haptics.logged()
            } label: {
                Label("Add sample trips", systemImage: "plus.square.on.square")
            }
            Button(role: .destructive) {
                SampleData.deleteSampleTrips(in: modelContext)
                Haptics.warning()
            } label: {
                Label("Delete sample trips", systemImage: "minus.square")
            }
            .disabled(sampleTripCount == 0)
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
            .disabled(trips.isEmpty && catches.isEmpty)
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

    // MARK: Export

    private var exportSignature: String {
        "\(trips.count)-\(catches.count)"
    }

    private var exportFooter: String {
        if exportFailed {
            return "Could not write the export file. Tap Prepare export to try again."
        }
        return "One row per catch, with the trip's place and conditions on every row. Opens in Numbers, Excel, or Google Sheets."
    }

    private func prepareExport() {
        let csv = CSVExporter.csv(trips: trips)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(Self.exportFileName(on: .now))
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            exportURL = url
            exportFailed = false
        } catch {
            exportURL = nil
            exportFailed = true
        }
    }

    /// fish-log-2026-10-31.csv. POSIX locale so the digits and calendar never change with region settings.
    private static func exportFileName(on date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return "fish-log-\(formatter.string(from: date)).csv"
    }

    // MARK: Delete

    private var sampleTripCount: Int {
        trips.filter { SampleData.isSample($0) }.count
    }

    private var deleteButtonTitle: String {
        trips.isEmpty ? "Delete all catches" : "Delete \(Self.counted(trips.count, "trip", "trips"))"
    }

    private var deleteMessage: String {
        let tripsText = Self.counted(trips.count, "trip", "trips")
        let catchesText = Self.counted(catches.count, "catch", "catches")
        let photosText = Self.counted(photos.count, "photo", "photos")
        return "This removes \(tripsText), \(catchesText), and \(photosText) from this iPhone. It cannot be undone."
    }

    private func deleteEverything() {
        let allTrips = trips
        for trip in allTrips {
            CatchLogger.delete(trip, in: modelContext)
        }
        // Catches whose trip is already gone would otherwise linger in the counts.
        let leftovers = (try? modelContext.fetch(FetchDescriptor<FishCatch>())) ?? []
        for fishCatch in leftovers where fishCatch.trip == nil {
            CatchLogger.delete(fishCatch, in: modelContext)
        }
        exportURL = nil
        Haptics.warning()
    }

    private static func counted(_ count: Int, _ singular: String, _ plural: String) -> String {
        "\(count.formatted()) \(count == 1 ? singular : plural)"
    }
}
