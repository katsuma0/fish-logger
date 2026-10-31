import SwiftUI
import UIKit

/// Multi-select list of fishing regions, grouped by country, with a "use my location" shortcut.
/// Used in first-launch setup and in Settings, so it renders as List sections.
struct RegionPickerSections: View {
    @Binding var selection: Set<FishingRegion>

    @Environment(AppSettings.self) private var settings
    @State private var isLocating = false
    @State private var locateFailed = false
    /// The region the last "Use my location" ticked. Its row can be far down the list, so the
    /// footer says what happened.
    @State private var addedRegion: FishingRegion?

    var body: some View {
        Section {
            Button {
                Task { await useMyLocation() }
            } label: {
                HStack {
                    Label("Use my location", systemImage: "location.fill")
                    Spacer()
                    if isLocating { ProgressView() }
                }
                .frame(minHeight: settings.buttonSize.minTapSize)
                .contentShape(Rectangle())
            }
            .disabled(isLocating)
        } footer: {
            if let addedRegion, selection.contains(addedRegion) {
                Text("Added \(addedRegion.label). It's ticked in the list below.")
            } else if locateFailed {
                Text(Self.failedMessage)
            }
        }

        ForEach(FishingRegion.Country.allCases) { country in
            Section(country.label) {
                ForEach(FishingRegion.regions(in: country)) { region in
                    row(region)
                }
            }
        }
    }

    private func row(_ region: FishingRegion) -> some View {
        let isSelected = selection.contains(region)
        return Button {
            if isSelected { selection.remove(region) } else { selection.insert(region) }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(region.label)
                        .foregroundStyle(.primary)
                    Text(region.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .frame(minHeight: settings.buttonSize.minTapSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private static let failedMessage = "Couldn't tell where you are. Pick from the list instead."

    private func useMyLocation() async {
        isLocating = true
        locateFailed = false
        addedRegion = nil
        let region = await LocationService.shared.currentRegion()
        isLocating = false
        if let region {
            selection.insert(region)
            addedRegion = region
            // Focus stays on the button, so VoiceOver users hear which row was ticked.
            UIAccessibility.post(notification: .announcement, argument: "Added \(region.label).")
        } else {
            Haptics.warning()
            locateFailed = true
            UIAccessibility.post(notification: .announcement, argument: Self.failedMessage)
        }
    }
}

/// Grid of the kinds of fish people go after. Multi-select; none picked means everything.
struct TargetFishGrid: View {
    @Binding var selection: Set<SpeciesGroup>
    /// Kinds of fish nobody can catch in these regions are left off, so a Prairies angler is not
    /// asked about offshore fishing. Empty means all of North America.
    var regions: Set<FishingRegion> = []

    @Environment(AppSettings.self) private var settings
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(choices) { group in
                tile(group)
            }
        }
    }

    /// A group already picked stays, so it can still be turned off after the regions change.
    private var choices: [SpeciesGroup] {
        let present = Set(SpeciesCatalog.available(in: regions).map(\.group))
        return SpeciesGroup.targetChoices.filter { present.contains($0) || selection.contains($0) }
    }

    /// One column at accessibility text sizes, so labels wrap instead of shrinking.
    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: 10)]
        }
        return [GridItem(.adaptive(minimum: max(150, settings.buttonSize.tileMinWidth * 1.4)), spacing: 10)]
    }

    private func tile(_ group: SpeciesGroup) -> some View {
        let isSelected = selection.contains(group)
        let species = SpeciesCatalog.species(id: group.representativeSpeciesID)
        return Button {
            if isSelected { selection.remove(group) } else { selection.insert(group) }
        } label: {
            HStack(spacing: 10) {
                SpeciesIcon(species: species, size: 34)
                Text(group.targetLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize + 12, alignment: .leading)
            .cardBackground(tint: isSelected ? Color.accentColor : nil)
            .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Settings screen for changing where and what you fish after setup.
struct FishingProfileView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        List {
            Section {
                NavigationLink {
                    List {
                        RegionPickerSections(selection: $settings.homeRegions)
                    }
                    .listStyle(.insetGrouped)
                    .navigationTitle("Where you fish")
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    LabeledContent("Where you fish", value: settings.homeRegionsSummary)
                }
                NavigationLink {
                    ScrollView {
                        TargetFishGrid(selection: $settings.targetGroups, regions: settings.homeRegions)
                            .padding(16)
                    }
                    .background(Theme.screenBackground)
                    .navigationTitle("What you fish for")
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    LabeledContent("What you fish for", value: targetSummary)
                }
            } footer: {
                Text("Species lists, the quick log, and Photo ID start with fish from these regions. Search always finds every fish.")
            }
            Section {
                LabeledContent("Species in your regions", value: "\(settings.regionalSpecies.count)")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Your fishing")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var targetSummary: String {
        let picked = SpeciesGroup.targetChoices.filter { settings.targetGroups.contains($0) }
        switch picked.count {
        case 0: return "Everything"
        case 1: return picked[0].targetLabel
        default: return "\(picked[0].targetLabel) and \(picked.count - 1) more"
        }
    }
}
