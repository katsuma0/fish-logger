import CoreLocation
import MapKit
import SwiftData
import SwiftUI

/// What the Trips map camera fits to. The camera only jumps back to show every pin when one of these
/// changes, never while someone is typing a search or has panned to a spot.
struct HistoryMapFitKey: Hashable {
    var speciesID: String?
    var time: HistoryTimeFilter
    var day: Date?

    init(speciesID: String?, time: HistoryTimeFilter, day: Date?) {
        self.speciesID = speciesID
        self.time = time
        self.day = day
    }
}

/// Everything the pins depend on. Pins are rebuilt in `.task(id:)` when it changes, never in `body`.
private struct HistoryMapPinsKey: Equatable {
    let contentVersion: Int
    let tripCount: Int
    let speciesID: String?
    let fitKey: HistoryMapFitKey
}

/// Every geotagged catch in the filtered log, plus a marker for trips that only know where they started.
/// Pins are MapKit markers, which stay smooth with hundreds on screen; past `HistoryMapPins.groupingThreshold`
/// catches they are grouped into one marker per trip.
struct HistoryMapView: View {
    let trips: [Trip]
    let speciesID: String?
    /// Goes up when the trips or their catches change, so the pins are rebuilt.
    let contentVersion: Int
    let fitKey: HistoryMapFitKey
    let onSelect: (Trip) -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedPinID: UUID? = nil
    @State private var catchPins: [HistoryMapPin] = []
    @State private var spotPins: [HistoryMapPin] = []
    /// False until the first pins are in, so the empty card does not flash on open.
    @State private var pinsReady = false
    @State private var fittedKey: HistoryMapFitKey? = nil
    /// The key the pins on screen were built for. `.task(id:)` runs again each time the map comes back
    /// from a trip's page or another tab, and with nothing changed the pins it has are still right.
    @State private var builtKey: HistoryMapPinsKey? = nil

    init(
        trips: [Trip],
        speciesID: String?,
        contentVersion: Int = 0,
        fitKey: HistoryMapFitKey? = nil,
        onSelect: @escaping (Trip) -> Void
    ) {
        self.trips = trips
        self.speciesID = speciesID
        self.contentVersion = contentVersion
        self.fitKey = fitKey ?? HistoryMapFitKey(speciesID: speciesID, time: .allTime, day: nil)
        self.onSelect = onSelect
    }

    var body: some View {
        Map(position: $position, selection: $selectedPinID) {
            ForEach(spotPins) { pin in
                Marker(pin.title, systemImage: "figure.fishing", coordinate: pin.coordinate)
                    .tint(Color.orange)
                    .tag(pin.id)
            }
            ForEach(catchPins) { pin in
                Marker(pin.title, systemImage: "fish.fill", coordinate: pin.coordinate)
                    .tint(pin.species?.color ?? Color.gray)
                    .tag(pin.id)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .overlay(alignment: .bottom) {
            if pinsReady && catchPins.isEmpty && spotPins.isEmpty {
                emptyCard
            }
        }
        .onChange(of: selectedPinID) { _, newValue in
            guard let newValue else { return }
            // A marker opens its trip straight away, so the selection is only ever a tap.
            selectedPinID = nil
            let pin = catchPins.first(where: { $0.id == newValue }) ?? spotPins.first(where: { $0.id == newValue })
            if let trip = pin?.trip, !trip.historyIsGone {
                onSelect(trip)
            }
        }
        .task(id: pinsKey) {
            let key = pinsKey
            guard builtKey != key else { return }
            builtKey = key
            updatePins()
        }
    }

    private var pinsKey: HistoryMapPinsKey {
        HistoryMapPinsKey(
            contentVersion: contentVersion,
            tripCount: trips.count,
            speciesID: speciesID,
            fitKey: fitKey
        )
    }

    private func updatePins() {
        let pins = HistoryMapPins.mapPins(for: trips, speciesID: speciesID)
        catchPins = pins.catches
        spotPins = pins.spots
        pinsReady = true
        // Refit only for a new species, time range or day, after the new pins are in place.
        if fittedKey != fitKey {
            fittedKey = fitKey
            position = .automatic
        }
    }

    private var emptyCard: some View {
        let strong = settings.usesStrongContrast(colorSchemeContrast)
        return VStack(spacing: 4) {
            Text("Nothing to map yet")
                .font(.headline)
            Text("Catches and trips show up here once they have a location.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(strong ? Color.primary : Color.clear, lineWidth: strong ? 2 : 0)
        )
        .padding(16)
        .accessibilityElement(children: .combine)
    }
}

/// Small map for one trip: the trip spot and every geotagged catch. It does not pan or zoom, because it
/// sits in a scrolling list and a drag on it should scroll the page. The trip's page wraps it in a
/// button that opens `HistoryTripMapPage`.
struct HistoryTripMapSnippet: View {
    let catchPins: [HistoryMapPin]
    let spotPins: [HistoryMapPin]

    init(catchPins: [HistoryMapPin], spotPins: [HistoryMapPin]) {
        self.catchPins = catchPins
        self.spotPins = spotPins
    }

    var body: some View {
        Map(initialPosition: .automatic, interactionModes: []) {
            ForEach(spotPins) { pin in
                Marker(pin.title, systemImage: "figure.fishing", coordinate: pin.coordinate)
                    .tint(Color.orange)
            }
            ForEach(catchPins) { pin in
                Annotation(pin.title, coordinate: pin.coordinate) {
                    SpeciesIcon(species: pin.species, size: 22)
                }
                .annotationTitles(.hidden)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenSummary)
    }

    private var spokenSummary: String {
        let count = catchPins.count
        if count == 0 { return "Map of the trip spot" }
        return count == 1 ? "Map of the trip, 1 catch with a location" : "Map of the trip, \(count) catches with a location"
    }
}

/// Full map of one trip that pans and zooms, pushed from the small map on the trip's page.
struct HistoryTripMapPage: View {
    let title: String
    let catchPins: [HistoryMapPin]
    let spotPins: [HistoryMapPin]

    init(title: String, catchPins: [HistoryMapPin], spotPins: [HistoryMapPin]) {
        self.title = title
        self.catchPins = catchPins
        self.spotPins = spotPins
    }

    var body: some View {
        Map(initialPosition: .automatic) {
            ForEach(spotPins) { pin in
                Marker(pin.title, systemImage: "figure.fishing", coordinate: pin.coordinate)
                    .tint(Color.orange)
            }
            ForEach(catchPins) { pin in
                Marker(pin.title, systemImage: "fish.fill", coordinate: pin.coordinate)
                    .tint(pin.species?.color ?? Color.gray)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
