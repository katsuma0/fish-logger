import Foundation
import SwiftData
import Testing
@testable import FishLogger

/// RFC 4180 escaping and the header row. Pure string work, so no store is needed.
struct ExportTests {
    @Test func plainFieldIsLeftAlone() {
        #expect(CSVExporter.escape("Jig") == "Jig")
        #expect(CSVExporter.escape("") == "")
    }

    @Test func fieldWithACommaIsQuoted() {
        #expect(CSVExporter.escape("Lake Simcoe, north shore") == "\"Lake Simcoe, north shore\"")
    }

    @Test func quotesAreDoubledInsideQuotes() {
        #expect(CSVExporter.escape(#"The "big" one"#) == #""The ""big"" one""#)
    }

    @Test func newlinesAreQuoted() {
        #expect(CSVExporter.escape("Line one\nline two") == "\"Line one\nline two\"")
        #expect(CSVExporter.escape("Line one\rline two") == "\"Line one\rline two\"")
        // "\r\n" is one Character in Swift, so this checks the scalar test, not a Character test.
        #expect(CSVExporter.escape("Line one\r\nline two") == "\"Line one\r\nline two\"")
    }

    @Test func emptyLogIsJustTheHeaderRow() {
        let csv = CSVExporter.csv(records: [])
        #expect(csv == CSVExporter.columns.joined(separator: ","))
        #expect(!csv.contains("\r\n"))
    }

    @Test func headerRowStartsWithTripColumnsAndEndsWithNotes() {
        let header = CSVExporter.csv(records: [])
        #expect(header.hasPrefix("trip_start,trip_end,location,"))
        #expect(header.hasSuffix(",catch_pressure_hpa,notes"))
        #expect(CSVExporter.columns == CSVExporter.tripColumns + CSVExporter.catchColumns)
    }

    @Test func headerNamesAreUnique() {
        #expect(Set(CSVExporter.columns).count == CSVExporter.columns.count)
    }

    @Test func exportFileNameIsTheLocalDay() throws {
        // Gregorian in the current time zone, which is what the file name uses.
        let calendar = Calendar(identifier: .gregorian)
        let day = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 31, hour: 12)))
        #expect(CSVExporter.exportFileName(on: day) == "fish-log-2026-10-31.csv")
    }
}

/// Whole rows built from models in a throwaway store.
@MainActor
struct ExportRowTests {
    /// Held by the suite so it outlives every model a test touches.
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() {
        container = AppModelContainer.inMemory()
    }

    private static let start = Date(timeIntervalSince1970: 1_781_000_000)

    private func makeTrip(at spot: String) -> Trip {
        let trip = Trip(startDate: Self.start, locationName: spot)
        context.insert(trip)
        return trip
    }

    @discardableResult
    private func addCatch(_ speciesID: String, to trip: Trip, minutesIn: Double) -> FishCatch {
        let fishCatch = FishCatch(speciesID: speciesID, timestamp: Self.start.addingTimeInterval(minutesIn * 60))
        context.insert(fishCatch)
        fishCatch.trip = trip
        return fishCatch
    }

    @Test func skunkedTripStillGetsOneRow() throws {
        let trip = makeTrip(at: "Bass Pond")
        let lines = CSVExporter.csv(trips: [trip]).components(separatedBy: "\r\n")
        try #require(lines.count == 2)
        // Nothing in this row needs quotes, so a plain split finds every column.
        #expect(lines[1].components(separatedBy: ",").count == CSVExporter.columns.count)
        #expect(lines[1].contains(",Bass Pond,"))
    }

    @Test func eachCatchGetsARowOldestFirst() throws {
        let trip = makeTrip(at: "Lake Simcoe")
        addCatch("yellow_perch", to: trip, minutesIn: 40)
        addCatch("walleye", to: trip, minutesIn: 10)
        let lines = CSVExporter.csv(trips: [trip]).components(separatedBy: "\r\n")
        try #require(lines.count == 3)
        #expect(lines[1].contains(",walleye,Walleye,"))
        #expect(lines[2].contains(",yellow_perch,Yellow perch,"))
    }

    @Test func commasQuotesAndNewlinesAreEscapedInsideRows() throws {
        let trip = makeTrip(at: "Lake Simcoe, north shore")
        let fishCatch = addCatch("walleye", to: trip, minutesIn: 10)
        fishCatch.lure = #"Husky "Jerk" 12"#
        fishCatch.notes = "Big one\nright by the weeds"
        let csv = CSVExporter.csv(trips: [trip])
        #expect(csv.contains(#","Lake Simcoe, north shore","#))
        #expect(csv.contains(#","Husky ""Jerk"" 12","#))
        #expect(csv.hasSuffix("\"Big one\nright by the weeds\""))
        // The newline sits inside quotes, so there is still one header and one row.
        #expect(csv.components(separatedBy: "\r\n").count == 2)
    }
}
