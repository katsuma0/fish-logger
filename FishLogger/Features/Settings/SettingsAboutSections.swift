import CoreLocation
import SwiftUI
import UIKit

struct SettingsPermissionsSection: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        let location = LocationService.shared
        Section {
            LabeledContent("Location", value: locationStatus(location))
            if location.authorizationStatus == .notDetermined {
                Button("Allow location") {
                    location.requestPermission()
                }
            }
            Button("Open iPhone Settings") {
                openSettings()
            }
        } header: {
            Text("Permissions")
        } footer: {
            Text("Location fills in the spot name, the weather, and where each fish came from.")
        }
    }

    private func locationStatus(_ location: LocationService) -> String {
        if location.isAuthorized { return "Allowed" }
        if location.isDenied { return "Not allowed" }
        return "Not asked yet"
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

struct SettingsAboutSection: View {
    @Environment(AppSettings.self) private var settings

    private static let openMeteoURL = URL(string: "https://open-meteo.com")!
    private static let regulationsURL = URL(string: "https://www.ontario.ca/document/ontario-fishing-regulations-summary")!

    var body: some View {
        Section {
            LabeledContent("Version", value: Self.appVersion)
            Link(destination: Self.openMeteoURL) {
                Label("Weather data by Open-Meteo.com, CC BY 4.0", systemImage: "cloud.sun")
            }
            // Ontario's summary is the one link worth hard-coding; everywhere else gets a plain reminder.
            if settings.homeRegions.isEmpty || settings.homeRegions.contains(.ontario) {
                Link(destination: Self.regulationsURL) {
                    Label("Check the Ontario Fishing Regulations Summary before keeping fish.", systemImage: "book.closed")
                }
            } else {
                Label("Check your province or state's fishing rules before keeping fish.", systemImage: "book.closed")
            }
            Text("Made in Markham, Ontario.")
                .foregroundStyle(.secondary)
        } header: {
            Text("About")
        }
    }

    private static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = (info?["CFBundleShortVersionString"] as? String) ?? "1.0"
        guard let build = info?["CFBundleVersion"] as? String, !build.isEmpty, build != version else {
            return version
        }
        return "\(version) (\(build))"
    }
}
