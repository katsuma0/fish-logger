import CoreLocation
import MapKit
import SwiftData
import SwiftUI

/// Every geotagged catch in the filtered log, plus a marker for trips that only know where they started.
struct HistoryMapView: View {
    let trips: [Trip]
    let speciesID: String?
    let onSelect: (Trip) -> Void

    @Environment(AppSettings.self) private var settings
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedSpotID: UUID? = nil

    init(trips: [Trip], speciesID: String?, onSelect: @escaping (Trip) -> Void) {
        self.trips = trips
        self.speciesID = speciesID
        self.onSelect = onSelect
    }

    var body: some View {
        let catchPins = HistoryMapPins.catchPins(for: trips, speciesID: speciesID)
        let tripsWithCatchPins = Set(catchPins.compactMap { $0.trip?.id })
        let spotPins = HistoryMapPins.spotPins(for: trips, skipping: tripsWithCatchPins)
        Map(position: $position, selection: $selectedSpotID) {
            ForEach(spotPins) { pin in
                Marker(pin.title, systemImage: "figure.fishing", coordinate: pin.coordinate)
                    .tint(Color.orange)
                    .tag(pin.id)
            }
            ForEach(catchPins) { pin in
                Annotation(pin.title, coordinate: pin.coordinate) {
                    Button {
                        if let trip = pin.trip {
                            onSelect(trip)
                        }
                    } label: {
                        SpeciesIcon(species: pin.species, size: 26)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .frame(width: settings.buttonSize.minTapSize, height: settings.buttonSize.minTapSize)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(pin.spokenLabel)
                    .accessibilityHint("Opens the trip")
                }
                .annotationTitles(.hidden)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .overlay(alignment: .bottom) {
            if catchPins.isEmpty && spotPins.isEmpty {
                emptyCard
            }
        }
        .onChange(of: selectedSpotID) { _, newValue in
            guard let newValue else { return }
            // Markers cannot hold a button, so a selected trip marker opens its trip and clears itself.
            selectedSpotID = nil
            if let trip = trips.first(where: { $0.id == newValue }) {
                onSelect(trip)
            }
        }
        .onChange(of: trips.map(\.id)) {
            position = .automatic
        }
        .onChange(of: speciesID) {
            position = .automatic
        }
    }

    private var emptyCard: some View {
        VStack(spacing: 4) {
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
                .strokeBorder(
                    settings.highContrast ? Color.primary : Color.clear,
                    lineWidth: settings.highContrast ? 2 : 0
                )
        )
        .padding(16)
        .accessibilityElement(children: .combine)
    }
}

/// Small map for one trip: the trip spot and every geotagged catch.
struct HistoryTripMapSnippet: View {
    let catchPins: [HistoryMapPin]
    let spotPins: [HistoryMapPin]

    init(catchPins: [HistoryMapPin], spotPins: [HistoryMapPin]) {
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
                Annotation(pin.title, coordinate: pin.coordinate) {
                    SpeciesIcon(species: pin.species, size: 22)
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
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
