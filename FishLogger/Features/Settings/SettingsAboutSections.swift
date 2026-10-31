import CoreLocation
import SwiftUI
import UIKit

/// Location access, with a way to ask for it or change it in iPhone Settings.
struct SettingsPermissionsView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        let location = LocationService.shared
        List {
            Section {
                LabeledContent("Location", value: locationStatus(location))
                if location.authorizationStatus == .notDetermined {
                    Button("Allow location") {
                        location.requestPermission()
                    }
                }
            } footer: {
                Text("Location fills in the spot name, the weather, and where each fish came from.")
            }

            Section {
                Button("Open iPhone Settings") {
                    openSettings()
                }
            } footer: {
                Text("Change what this app can use in iPhone Settings.")
            }
        }
        .settingsListStyle()
        .navigationTitle("Permissions")
        .navigationBarTitleDisplayMode(.inline)
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

/// Version, weather credit, and where to find the fishing rules.
struct SettingsAboutView: View {
    @Environment(AppSettings.self) private var settings

    private static let openMeteoURL = URL(string: "https://open-meteo.com")!
    private static let regulationsURL = URL(string: "https://www.ontario.ca/document/ontario-fishing-regulations-summary")!

    var body: some View {
        // Ontario's summary is the one link worth hard-coding; everywhere else gets a plain reminder.
        let showsOntarioRules = settings.homeRegions.isEmpty || settings.homeRegions.contains(.ontario)
        List {
            Section {
                LabeledContent("Version", value: Self.appVersion)
            }

            Section {
                Link("Weather data by Open-Meteo.com, CC BY 4.0", destination: Self.openMeteoURL)
            } header: {
                Text("Weather")
            }

            Section {
                if showsOntarioRules {
                    Link("Ontario Fishing Regulations Summary", destination: Self.regulationsURL)
                } else {
                    Text("Check your province or state's fishing rules before keeping fish.")
                }
            } header: {
                Text("Fishing rules")
            } footer: {
                if showsOntarioRules {
                    Text("Check the rules before keeping fish.")
                }
            }
        }
        .settingsListStyle()
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
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

#Preview("About") {
    NavigationStack {
        SettingsAboutView()
    }
    .environment(AppSettings.shared)
}
