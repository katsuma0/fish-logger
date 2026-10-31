import SwiftUI

/// Multi-select list of fishing regions, grouped by country, with a "use my location" shortcut.
/// Used in first-launch setup and in Settings, so it renders as List sections.
struct RegionPickerSections: View {
    @Binding var selection: Set<FishingRegion>

    @Environment(AppSettings.self) private var settings
    @State private var isLocating = false
    @State private var locateFailed = false

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
            if locateFailed {
                Text("Couldn't tell where you are. Pick from the list instead.")
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
            Haptics.tap()
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

    private func useMyLocation() async {
        isLocating = true
        locateFailed = false
        let region = await LocationService.shared.currentRegion()
        isLocating = false
        if let region {
            Haptics.logged()
            selection.insert(region)
        } else {
            Haptics.warning()
            locateFailed = true
        }
    }
}

/// Grid of the kinds of fish people go after. Multi-select; none picked means everything.
struct TargetFishGrid: View {
    @Binding var selection: Set<SpeciesGroup>

    @Environment(AppSettings.self) private var settings

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: max(150, settings.buttonSize.tileMinWidth * 1.4)), spacing: 10)],
            spacing: 10
        ) {
            ForEach(SpeciesGroup.targetChoices) { group in
                tile(group)
            }
        }
    }

    private func tile(_ group: SpeciesGroup) -> some View {
        let isSelected = selection.contains(group)
        let species = SpeciesCatalog.species(id: group.representativeSpeciesID)
        return Button {
            Haptics.tap()
            if isSelected { selection.remove(group) } else { selection.insert(group) }
        } label: {
            HStack(spacing: 10) {
                SpeciesIcon(species: species, size: 34)
                Text(group.targetLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
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
                        TargetFishGrid(selection: $settings.targetGroups)
                            .padding(16)
                    }
                    .background(Theme.screenBackground)
                    .navigationTitle("What you fish for")
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    LabeledContent("What you fish for", value: targetSummary)
                }
            } footer: {
                Text("Species lists, the quick log, and photo ID stick to these regions. Any fish can still be found under Show all species.")
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
