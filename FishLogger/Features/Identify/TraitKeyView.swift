import SwiftUI

/// Offline "what am I looking at" checklist. Tap the features you can see; the best matches stay
/// pinned at the bottom and update as you go, with the full list at the end. Pushed inside
/// IdentifyView's NavigationStack, so it has none of its own.
struct TraitKeyView: View {
    let onPick: (Species) -> Void
    let onPickByName: (() -> Void)?

    @Environment(AppSettings.self) private var settings
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @State private var selected: Set<FishTrait> = []
    @State private var infoTrait: FishTrait? = nil
    /// Off by default: only fish from the person's regions are offered.
    @State private var showsAllRegions = false
    /// Worked out in `.task(id:)` when the picks or the region choice change, never in `body`.
    @State private var matches: [TraitKeyMatch] = []

    private static let maxResults = 8

    init(onPick: @escaping (Species) -> Void, onPickByName: (() -> Void)? = nil) {
        self.onPick = onPick
        self.onPickByName = onPickByName
    }

    var body: some View {
        let homeRegions = settings.homeRegions
        let strongContrast = settings.usesStrongContrast(colorSchemeContrast)
        List {
            Section {
                Text("Tap what you can see on the fish. The best matches show at the bottom. Works with no signal.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(FishTrait.Category.allCases) { category in
                Section(category.label) {
                    FlowLayout(spacing: 8, lineSpacing: 8) {
                        ForEach(traits(in: category)) { trait in
                            chip(for: trait, strongContrast: strongContrast)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                resultRows
                if let onPickByName {
                    Button {
                        onPickByName()
                    } label: {
                        Label("Pick from the full list", systemImage: "list.bullet")
                            .frame(minHeight: settings.buttonSize.minTapSize)
                    }
                }
            } header: {
                Text(resultsHeader)
            }

            if !homeRegions.isEmpty {
                Section {
                    Toggle("Include fish from other regions", isOn: $showsAllRegions)
                        .frame(minHeight: settings.buttonSize.minTapSize)
                } footer: {
                    Text("Your regions: \(settings.homeRegionsSummary). Change them in Settings.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Checklist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear") {
                    selected.removeAll()
                }
                .disabled(selected.isEmpty)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !selected.isEmpty {
                TraitKeyMatchBar(matches: matches, total: selected.count, onPick: onPick)
            }
        }
        .task(id: TraitKeyMatchKey(selected: selected, regions: homeRegions, showsAllRegions: showsAllRegions)) {
            let previousTop = matches.first
            matches = Self.topMatches(
                for: selected,
                regions: showsAllRegions ? [] : homeRegions
            )
            announceTopMatch(ifChangedFrom: previousTop)
        }
    }

    /// The match bar changes without a sound, so VoiceOver hears the new best match. Only when it
    /// changes, not on every tap, so the chip's own "Selected" readout is not talked over each time.
    private func announceTopMatch(ifChangedFrom previousTop: TraitKeyMatch?) {
        guard !selected.isEmpty else { return }
        let top = matches.first
        guard top?.species.id != previousTop?.species.id else { return }
        if let top {
            IdentifyAnnouncement.post("Best match: \(top.species.commonName), \(top.matches) of \(selected.count).")
        } else {
            IdentifyAnnouncement.post("No match yet. Try unticking a feature.")
        }
    }

    // MARK: Results

    private var resultsHeader: String {
        selected.isEmpty ? "Likely species" : "Likely species, \(selected.count) picked"
    }

    @ViewBuilder
    private var resultRows: some View {
        if selected.isEmpty {
            Text("Pick a few features above to see likely species.")
                .foregroundStyle(.secondary)
        } else if matches.isEmpty {
            Text(noMatchMessage)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            ForEach(matches) { match in
                resultRow(match)
            }
        }
    }

    private var noMatchMessage: String {
        if !showsAllRegions, !settings.homeRegions.isEmpty {
            return "No fish in your regions has those features. Try unticking one, or include other regions."
        }
        return "No species in the guide has those features. Try unticking one."
    }

    /// Ranked by how many picked features match, limited to the regions (empty means everywhere).
    private static func topMatches(for traits: Set<FishTrait>, regions: Set<FishingRegion>) -> [TraitKeyMatch] {
        SpeciesCatalog.matching(traits: traits)
            .filter { $0.species.lives(in: regions) }
            .prefix(maxResults)
            .map { TraitKeyMatch(species: $0.species, matches: $0.matches) }
    }

    /// No haptic: the confirm screen that opens is the feedback.
    private func resultRow(_ match: TraitKeyMatch) -> some View {
        let total = selected.count
        let summary = TraitKeyMatch.summary(match.matches, of: total)
        return Button {
            onPick(match.species)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                SpeciesIcon(species: match.species, size: 40)
                VStack(alignment: .leading, spacing: 3) {
                    Text(match.species.commonName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(match.matches == total ? Color.accentColor : Color.secondary)
                    if let tip = match.species.idTips.first {
                        Text(tip)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .frame(minHeight: settings.buttonSize.minTapSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(match.species.commonName), \(summary)")
        .accessibilityHint("Opens the log screen for this species")
    }

    // MARK: Chips

    private func traits(in category: FishTrait.Category) -> [FishTrait] {
        FishTrait.allCases.filter { $0.category == category }
    }

    /// No haptic on chip taps; the checkmark and the match bar change right away.
    private func chip(for trait: FishTrait, strongContrast: Bool) -> some View {
        let isOn = selected.contains(trait)
        return HStack(spacing: 0) {
            Button {
                if isOn {
                    selected.remove(trait)
                } else {
                    selected.insert(trait)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isOn ? "checkmark" : "plus")
                        .font(.caption.weight(.bold))
                    Text(trait.label)
                        .font(.subheadline.weight(.medium))
                        .multilineTextAlignment(.leading)
                }
                .padding(.leading, 12)
                .padding(.trailing, 4)
                .frame(minHeight: settings.buttonSize.minTapSize)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(trait.label)
            .accessibilityHint(trait.detail)
            .accessibilityAddTraits(isOn ? .isSelected : [])

            Button {
                infoTrait = trait
            } label: {
                Image(systemName: "info.circle")
                    .font(.subheadline)
                    .frame(width: 36)
                    .frame(minHeight: settings.buttonSize.minTapSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)
            .popover(isPresented: infoBinding(for: trait)) {
                TraitKeyInfoCard(trait: trait)
                    .presentationCompactAdaptation(.popover)
            }
        }
        .foregroundStyle(isOn ? Color.white : Color.primary)
        .background(
            Capsule(style: .continuous)
                // AccentFill, not AccentColor, so the white label stays readable in dark mode.
                .fill(isOn ? Theme.accentFill : Color(uiColor: .tertiarySystemFill))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(strongContrast ? Color.primary : Color.clear, lineWidth: 1.5)
        )
    }

    private func infoBinding(for trait: FishTrait) -> Binding<Bool> {
        Binding(
            get: { infoTrait == trait },
            set: { isPresented in
                if !isPresented, infoTrait == trait { infoTrait = nil }
            }
        )
    }
}

/// What the match list depends on, so `.task(id:)` reruns only when one of these changes.
private struct TraitKeyMatchKey: Equatable {
    let selected: Set<FishTrait>
    let regions: Set<FishingRegion>
    let showsAllRegions: Bool
}

private struct TraitKeyMatch: Identifiable, Equatable {
    let species: Species
    let matches: Int
    var id: String { species.id }

    static func summary(_ matches: Int, of total: Int) -> String {
        "\(matches) of \(total) features match"
    }
}

/// The best few matches, pinned above the home indicator so they stay in view while the person
/// works through the features. Tapping one opens the confirm screen, like the rows in the list.
private struct TraitKeyMatchBar: View {
    let matches: [TraitKeyMatch]
    let total: Int
    let onPick: (Species) -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let isLarge = dynamicTypeSize.isAccessibilitySize
        // Big text gets fewer, stacked matches so the bar never covers most of the screen.
        let shown = Array(matches.prefix(isLarge ? 2 : 3))
        VStack(alignment: .leading, spacing: 8) {
            Text("Best matches")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            if shown.isEmpty {
                Text("No match yet. Try unticking a feature.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if isLarge {
                VStack(spacing: 8) {
                    ForEach(shown) { match in
                        button(for: match)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    ForEach(shown) { match in
                        button(for: match)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func button(for match: TraitKeyMatch) -> some View {
        let summary = TraitKeyMatch.summary(match.matches, of: total)
        return Button {
            onPick(match.species)
        } label: {
            HStack(spacing: 8) {
                SpeciesIcon(species: match.species, size: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text(match.species.commonName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    Text("\(match.matches) of \(total)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize, alignment: .leading)
            .cardBackground(tint: match.species.color)
            .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(match.species.commonName), \(summary)")
        .accessibilityHint("Opens the log screen for this species")
        .accessibilityAddTraits(.isButton)
    }
}

private struct TraitKeyInfoCard: View {
    let trait: FishTrait

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(trait.label)
                .font(.headline)
            Text(trait.detail)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: 300, alignment: .leading)
    }
}
