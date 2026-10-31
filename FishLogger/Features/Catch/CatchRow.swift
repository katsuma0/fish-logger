import SwiftData
import SwiftUI
import UIKit

/// List row content for one catch. No NavigationLink inside; the caller decides what a tap does.
struct CatchRow: View {
    let fishCatch: FishCatch

    @Environment(AppSettings.self) private var settings

    init(fishCatch: FishCatch) {
        self.fishCatch = fishCatch
    }

    var body: some View {
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
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(timeText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !fishCatch.released {
                    keptBadge
                }
            }
        }
        .frame(minHeight: settings.buttonSize.minTapSize)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(spokenSummary)
    }

    @ViewBuilder
    private var leadingImage: some View {
        if let cover = fishCatch.sortedPhotos.first {
            PhotoThumbnail(photo: cover, size: 44)
        } else {
            SpeciesIcon(species: fishCatch.species, size: 44)
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
                    .strokeBorder(settings.highContrast ? Color.primary : Color.clear, lineWidth: 1)
            )
    }

    private var timeText: String {
        fishCatch.timestamp.formatted(date: .omitted, time: .shortened)
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

    /// Reads as one sentence: "Walleye, large, 7:42 PM, released".
    private var spokenSummary: String {
        var parts: [String] = [fishCatch.speciesName]
        if fishCatch.count > 1 { parts.append("\(fishCatch.count) fish") }
        if let measured = measuredText {
            parts.append(measured)
        } else if let sizeClass = fishCatch.sizeClass {
            parts.append(sizeClass.label.lowercased())
        }
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
    }
    .modelContainer(container)
    .environment(AppSettings.shared)
}
