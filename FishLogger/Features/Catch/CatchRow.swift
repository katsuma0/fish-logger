import SwiftData
import SwiftUI
import UIKit

/// List row content for one catch. No NavigationLink inside; the caller decides what a tap does.
struct CatchRow: View {
    let fishCatch: FishCatch
    /// Shows the day above the time. Lists that mix days pass true; a catch from another day shows
    /// its date anyway, so a column of times never hides which outing a fish came from.
    var showsDate: Bool = false
    /// Shows the species icon when the catch has no photo. The Today screen passes false and shows
    /// names only; a photo still shows either way.
    var showsIcon: Bool = true

    @Environment(AppSettings.self) private var settings
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @ScaledMetric(relativeTo: .headline) private var scaledImageSize: CGFloat = 44

    init(fishCatch: FishCatch, showsDate: Bool = false, showsIcon: Bool = true) {
        self.fishCatch = fishCatch
        self.showsDate = showsDate
        self.showsIcon = showsIcon
    }

    var body: some View {
        let isLargeText = dynamicTypeSize.isAccessibilitySize
        let dateText = self.dateText
        HStack(spacing: 12) {
            leadingImage

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(fishCatch.speciesName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if fishCatch.count > 1 {
                        Text("\(fishCatch.count) fish")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(detailLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(isLargeText ? 3 : 2)
                // Large text has no room for a second column, so when and kept go underneath.
                if isLargeText {
                    whenAndKept(dateText: dateText, alignment: .leading)
                }
            }

            Spacer(minLength: 8)

            if !isLargeText {
                whenAndKept(dateText: dateText, alignment: .trailing)
            }
        }
        .frame(minHeight: settings.buttonSize.minTapSize)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(spokenSummary(dateText: dateText))
    }

    @ViewBuilder
    private var leadingImage: some View {
        // Capped so the photo does not crowd out the text at the largest sizes.
        let imageSize = min(scaledImageSize, 64)
        // The oldest photo is the cover. min avoids sorting every photo on each render.
        if let cover = fishCatch.photos.min(by: { $0.createdAt < $1.createdAt }) {
            PhotoThumbnail(photo: cover, size: imageSize)
        } else if showsIcon {
            SpeciesIcon(species: fishCatch.species, size: imageSize)
        }
    }

    private func whenAndKept(dateText: String?, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            VStack(alignment: alignment, spacing: 0) {
                if let dateText {
                    Text(dateText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(timeText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !fishCatch.released {
                keptBadge
            }
        }
    }

    private var keptBadge: some View {
        Text("Kept")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color(uiColor: .tertiarySystemFill)))
            .overlay(
                Capsule()
                    .strokeBorder(settings.usesStrongContrast(colorSchemeContrast) ? Color.primary : Color.clear, lineWidth: 1)
            )
    }

    private var timeText: String {
        fishCatch.timestamp.formatted(date: .omitted, time: .shortened)
    }

    /// "Oct 3", or "Oct 3, 2025" for another year. Nil for today's catches unless asked for.
    private var dateText: String? {
        let timestamp = fishCatch.timestamp
        let calendar = Calendar.current
        guard showsDate || !calendar.isDateInToday(timestamp) else { return nil }
        if calendar.isDate(timestamp, equalTo: .now, toGranularity: .year) {
            return timestamp.formatted(.dateTime.month(.abbreviated).day())
        }
        return timestamp.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private var trimmedLure: String {
        fishCatch.lure.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var measuredText: String? {
        var parts: [String] = []
        if let length = fishCatch.lengthCm { parts.append(settings.length(length)) }
        if let weight = fishCatch.weightKg { parts.append(settings.weight(weight)) }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private var sizeText: String {
        if let measured = measuredText { return measured }
        if let sizeClass = fishCatch.sizeClass { return sizeClass.label }
        return "No size"
    }

    private var detailLine: String {
        let lure = trimmedLure
        return lure.isEmpty ? sizeText : "\(sizeText) · \(lure)"
    }

    /// Reads as one sentence: "Walleye, large, Oct 3, 7:42 PM, released".
    private func spokenSummary(dateText: String?) -> String {
        var parts: [String] = [fishCatch.speciesName]
        if fishCatch.count > 1 { parts.append("\(fishCatch.count) fish") }
        if let measured = measuredText {
            parts.append(measured)
        } else if let sizeClass = fishCatch.sizeClass {
            parts.append(sizeClass.label.lowercased())
        }
        if let dateText { parts.append(dateText) }
        parts.append(timeText)
        parts.append(fishCatch.released ? "released" : "kept")
        let lure = trimmedLure
        if !lure.isEmpty { parts.append("caught on \(lure)") }
        let photoCount = fishCatch.photos.count
        if photoCount == 1 {
            parts.append("1 photo")
        } else if photoCount > 1 {
            parts.append("\(photoCount) photos")
        }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    let container = AppModelContainer.inMemory()
    let fishCatch = CatchLogger.logCatch(speciesID: "walleye", count: 3, sizeClass: .large, in: container.mainContext)
    List {
        CatchRow(fishCatch: fishCatch)
        CatchRow(fishCatch: fishCatch, showsDate: true)
    }
    .modelContainer(container)
    .environment(AppSettings.shared)
}
