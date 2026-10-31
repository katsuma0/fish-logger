import SwiftData
import SwiftUI
import UIKit

/// Summary card for the running trip: where, how long, how many, and the conditions.
struct TodayTripHeader: View {
    let trip: Trip
    let isFetchingWeather: Bool
    let onEdit: () -> Void
    let onGetWeather: () -> Void

    @Environment(AppSettings.self) private var settings

    init(trip: Trip, isFetchingWeather: Bool, onEdit: @escaping () -> Void, onGetWeather: @escaping () -> Void) {
        self.trip = trip
        self.isFetchingWeather = isFetchingWeather
        self.onEdit = onEdit
        self.onGetWeather = onGetWeather
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onEdit) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: trip.waterBody.symbolName)
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(minWidth: 32)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trip.displayName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: settings.buttonSize.minTapSize)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Edit the spot and conditions")

            HStack(alignment: .top, spacing: 12) {
                statBlock(
                    value: "\(trip.totalFish)",
                    caption: "fish",
                    spoken: trip.totalFish == 1 ? "1 fish" : "\(trip.totalFish) fish",
                    prominent: true
                )
                statBlock(
                    value: "\(speciesCount)",
                    caption: "species",
                    spoken: "\(speciesCount) species",
                    prominent: false
                )
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    statBlock(
                        value: Self.elapsedText(from: trip.startDate, to: context.date),
                        caption: "on the water",
                        spoken: Self.elapsedSpoken(from: trip.startDate, to: context.date),
                        prominent: false
                    )
                }
            }

            ConditionsSummaryView(trip: trip)

            if showsWeatherButton {
                weatherButton
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }

    private var subtitle: String {
        let start = trip.startDate.formatted(date: .omitted, time: .shortened)
        return "\(trip.method.label), \(trip.waterBody.label.lowercased()). Started \(start)."
    }

    private var speciesCount: Int {
        trip.speciesTally.filter { $0.speciesID != SpeciesCatalog.unknownID }.count
    }

    private var showsWeatherButton: Bool {
        settings.autoFetchWeather && trip.coordinate != nil && trip.weather == nil && trip.weatherFetchedAt == nil
    }

    private var weatherButton: some View {
        Button(action: onGetWeather) {
            HStack(spacing: 8) {
                if isFetchingWeather {
                    ProgressView()
                } else {
                    Image(systemName: "cloud.sun")
                }
                Text(isFetchingWeather ? "Getting weather" : "Get weather")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 14)
            .frame(minHeight: settings.buttonSize.minTapSize)
            .background(Capsule().fill(Color(uiColor: .tertiarySystemFill)))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isFetchingWeather)
    }

    private func statBlock(value: String, caption: String, spoken: String, prominent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(prominent ? Font.largeTitle.bold() : Font.title2.bold())
                .fontDesign(.rounded)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private static func elapsedText(from start: Date, to now: Date) -> String {
        let minutes = max(0, Int(now.timeIntervalSince(start) / 60))
        let hours = minutes / 60
        let rest = minutes % 60
        if hours == 0 { return "\(rest) min" }
        if rest == 0 { return "\(hours) h" }
        return "\(hours) h \(rest) min"
    }

    private static func elapsedSpoken(from start: Date, to now: Date) -> String {
        let minutes = max(0, Int(now.timeIntervalSince(start) / 60))
        let hours = minutes / 60
        let rest = minutes % 60
        let hourText = hours == 1 ? "1 hour" : "\(hours) hours"
        let minuteText = rest == 1 ? "1 minute" : "\(rest) minutes"
        if hours == 0 { return "On the water for \(minuteText)" }
        if rest == 0 { return "On the water for \(hourText)" }
        return "On the water for \(hourText) \(minuteText)"
    }
}

/// Status card shown when no trip is running.
struct TodayIdleCard: View {
    let trips: [Trip]

    init(trips: [Trip]) {
        self.trips = trips
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Not fishing right now.")
                .font(.title3.weight(.semibold))
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if LocationService.shared.isDenied {
                Label("Location is off, so trips get no spot name or weather. You can turn it on in the Settings app.", systemImage: "location.slash")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardBackground()
        .accessibilityElement(children: .combine)
    }

    private var summary: String {
        let calendar = Calendar.current
        let today = trips.filter { calendar.isDateInToday($0.startDate) }
        if !today.isEmpty {
            let fish = today.reduce(0) { $0 + $1.totalFish }
            let tripWord = today.count == 1 ? "trip" : "trips"
            return "Today: \(today.count) \(tripWord), \(fish) fish"
        }
        if let last = trips.first {
            let date = last.startDate.formatted(date: .abbreviated, time: .omitted)
            return "Last trip: \(date), \(last.displayName)"
        }
        return "No trips yet. Start one below, or just tap a fish."
    }
}
