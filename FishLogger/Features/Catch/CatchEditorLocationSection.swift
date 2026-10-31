import CoreLocation
import MapKit
import SwiftData
import SwiftUI

/// Where the fish came from, plus the pressure reading taken when it was logged.
struct CatchEditorLocationSection: View {
    let fishCatch: FishCatch

    @Environment(AppSettings.self) private var settings
    /// Grows with text size so the map keeps its share of the row, capped so it never fills the screen.
    @ScaledMetric(relativeTo: .body) private var mapHeight: CGFloat = 160
    @State private var isLocating = false
    @State private var failureMessage: String?

    init(fishCatch: FishCatch) {
        self.fishCatch = fishCatch
    }

    var body: some View {
        Section {
            if let coordinate = fishCatch.coordinate {
                map(for: coordinate)
                LabeledContent("Coordinates") {
                    Text(coordinateText(coordinate))
                        .textSelection(.enabled)
                }
            }

            Button {
                Task { await useCurrentLocation() }
            } label: {
                HStack {
                    Label("Use current location", systemImage: "location.fill")
                    Spacer()
                    if isLocating {
                        ProgressView()
                    }
                }
                .frame(minHeight: settings.buttonSize.minTapSize)
                .contentShape(Rectangle())
            }
            .disabled(isLocating)

            if fishCatch.coordinate != nil {
                Button(role: .destructive) {
                    removeLocation()
                } label: {
                    Label("Remove location", systemImage: "location.slash")
                        .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize, alignment: .leading)
                        .contentShape(Rectangle())
                }
            }

            if let pressure = fishCatch.pressureHPa {
                LabeledContent("Pressure when logged", value: settings.pressure(pressure))
            }
        } header: {
            Text("Where")
        } footer: {
            if let text = footerText {
                Text(text)
            }
        }
    }

    private func map(for coordinate: CLLocationCoordinate2D) -> some View {
        Map(
            initialPosition: .region(
                MKCoordinateRegion(center: coordinate, latitudinalMeters: 800, longitudinalMeters: 800)
            ),
            interactionModes: []
        ) {
            Marker(fishCatch.speciesName, coordinate: coordinate)
        }
        .frame(height: min(mapHeight, 260))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        // The initial position is read once, so a new spot needs a fresh map.
        .id("\(coordinate.latitude),\(coordinate.longitude)")
        .accessibilityLabel("Map of where this fish was caught")
    }

    private var footerText: String? {
        if let message = failureMessage { return message }
        if LocationService.shared.isDenied {
            return "Location access is off. Turn it on in the Settings app to tag catches."
        }
        if fishCatch.coordinate == nil {
            return "No location saved. Use your current location if you are still at the spot."
        }
        return nil
    }

    private func coordinateText(_ coordinate: CLLocationCoordinate2D) -> String {
        let latitude = coordinate.latitude.formatted(.number.precision(.fractionLength(5)))
        let longitude = coordinate.longitude.formatted(.number.precision(.fractionLength(5)))
        return "\(latitude), \(longitude)"
    }

    private func useCurrentLocation() async {
        failureMessage = nil
        isLocating = true
        let location = await LocationService.shared.currentLocation()
        isLocating = false
        // The GPS wait can be long; do not touch a catch that was deleted meanwhile.
        guard let context = fishCatch.catchEditorLiveContext else { return }
        guard let location else {
            failureMessage = "Could not get a location fix. Try again, or check location access in the Settings app."
            Haptics.warning()
            return
        }
        fishCatch.latitude = location.coordinate.latitude
        fishCatch.longitude = location.coordinate.longitude
        CatchLogger.save(context)
        Haptics.tap()
    }

    private func removeLocation() {
        guard let context = fishCatch.catchEditorLiveContext else { return }
        failureMessage = nil
        fishCatch.latitude = nil
        fishCatch.longitude = nil
        CatchLogger.save(context)
    }
}
