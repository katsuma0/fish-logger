import SwiftData
import SwiftUI

/// Compact chips for whichever conditions a trip has. Shows nothing when none are set.
struct ConditionsSummaryView: View {
    let trip: Trip

    @Environment(AppSettings.self) private var settings

    init(trip: Trip) {
        self.trip = trip
    }

    var body: some View {
        let items = conditionItems()
        if items.isEmpty {
            EmptyView()
        } else {
            FlowLayout(spacing: 6, lineSpacing: 6) {
                ForEach(items) { item in
                    ConditionChip(systemImage: item.symbol, text: item.text, accessibilityLabel: item.spoken)
                }
            }
        }
    }

    /// True when the view would show at least one chip. Cheap nil checks, so a card around the chips
    /// can hide itself without building them.
    static func hasConditions(_ trip: Trip) -> Bool {
        trip.weather != nil || trip.airTempC != nil || trip.waterTempC != nil || trip.pressureHPa != nil
            || trip.windSpeedKmh != nil || trip.moonPhase != nil || trip.sunrise != nil || trip.sunset != nil
    }

    /// VoiceOver spells "NW" letter by letter, so wind directions get read as words.
    private static let spokenCompass: [String: String] = [
        "N": "north", "NE": "northeast", "E": "east", "SE": "southeast",
        "S": "south", "SW": "southwest", "W": "west", "NW": "northwest"
    ]

    private func conditionItems() -> [TodayConditionItem] {
        var items: [TodayConditionItem] = []

        if let weather = trip.weather {
            items.append(TodayConditionItem(
                id: "weather",
                symbol: weather.symbolName,
                text: weather.label,
                spoken: "Weather: \(weather.label)"
            ))
        }
        if let air = trip.airTempC {
            let value = settings.temperature(air)
            items.append(TodayConditionItem(
                id: "air",
                symbol: "thermometer.medium",
                text: "Air \(value)",
                spoken: "Air temperature \(value)"
            ))
        }
        if let water = trip.waterTempC {
            let value = settings.temperature(water)
            items.append(TodayConditionItem(
                id: "water",
                symbol: "water.waves",
                text: "Water \(value)",
                spoken: "Water temperature \(value)"
            ))
        }
        if let pressure = trip.pressureHPa {
            var value = settings.pressure(pressure)
            if let trend = trip.pressureTrend {
                value += ", \(trend.label.lowercased())"
            }
            items.append(TodayConditionItem(
                id: "pressure",
                symbol: "barometer",
                text: value,
                spoken: "Pressure \(value)"
            ))
        }
        if let wind = trip.windSpeedKmh {
            let speed = settings.speed(wind)
            var text = speed
            var spoken = "Wind \(speed)"
            if let direction = trip.windDirectionDeg {
                let point = Compass.label(forDegrees: direction)
                text += " \(point)"
                spoken += " from the \(Self.spokenCompass[point] ?? point)"
            }
            items.append(TodayConditionItem(id: "wind", symbol: "wind", text: text, spoken: spoken))
        }
        if let phase = trip.moonPhase {
            let name = MoonInfo.name(forPhase: phase)
            items.append(TodayConditionItem(
                id: "moon",
                symbol: name.symbolName,
                text: name.label,
                spoken: "Moon: \(name.label)"
            ))
        }
        if let sunrise = trip.sunrise {
            let time = sunrise.formatted(date: .omitted, time: .shortened)
            items.append(TodayConditionItem(id: "sunrise", symbol: "sunrise.fill", text: time, spoken: "Sunrise \(time)"))
        }
        if let sunset = trip.sunset {
            let time = sunset.formatted(date: .omitted, time: .shortened)
            items.append(TodayConditionItem(id: "sunset", symbol: "sunset.fill", text: time, spoken: "Sunset \(time)"))
        }
        return items
    }
}

private struct TodayConditionItem: Identifiable {
    let id: String
    let symbol: String
    let text: String
    let spoken: String
}
