import SwiftUI

/// Offline "what am I looking at" checklist. Tap the features you can see and the likely species
/// update underneath. Pushed inside IdentifyView's NavigationStack, so it has none of its own.
struct TraitKeyView: View {
    let onPick: (Species) -> Void
    let onPickByName: (() -> Void)?

    @Environment(AppSettings.self) private var settings
    @State private var selected: Set<FishTrait> = []
    @State private var infoTrait: FishTrait? = nil

    private static let maxResults = 8

    init(onPick: @escaping (Species) -> Void, onPickByName: (() -> Void)? = nil) {
        self.onPick = onPick
        self.onPickByName = onPickByName
    }

    var body: some View {
        List {
            Section {
                Text("Tap what you can see on the fish. The list below updates as you go.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(FishTrait.Category.allCases) { category in
                Section(category.label) {
                    FlowLayout(spacing: 8, lineSpacing: 8) {
                        ForEach(traits(in: category)) { trait in
                            chip(for: trait)
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
            } footer: {
                if !OnDeviceIdentifier.isAvailable {
                    Text("Drop a FishClassifier.mlmodel trained in Create ML into the project for offline photo ID.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Checklist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear") {
                    Haptics.tap()
                    selected.removeAll()
                }
                .disabled(selected.isEmpty)
            }
        }
    }

    // MARK: Results

    private var resultsHeader: String {
        selected.isEmpty ? "Likely species" : "Likely species, \(selected.count) picked"
    }

    @ViewBuilder
    private var resultRows: some View {
        let matches = topMatches
        if selected.isEmpty {
            Text("Pick a few features above to see likely species.")
                .foregroundStyle(.secondary)
        } else if matches.isEmpty {
            Text("No species in the guide has those features. Try unticking one.")
                .foregroundStyle(.secondary)
        } else {
            ForEach(matches) { match in
                resultRow(match)
            }
        }
    }

    private var topMatches: [TraitKeyMatch] {
        SpeciesCatalog.matching(traits: selected)
            .prefix(Self.maxResults)
            .map { TraitKeyMatch(species: $0.species, matches: $0.matches) }
    }

    private func resultRow(_ match: TraitKeyMatch) -> some View {
        let total = selected.count
        let summary = "\(match.matches) of \(total) features match"
        return Button {
            Haptics.tap()
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

    private func chip(for trait: FishTrait) -> some View {
        let isOn = selected.contains(trait)
        return HStack(spacing: 0) {
            Button {
                Haptics.tap()
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
                .fill(isOn ? Color.accentColor : Color(uiColor: .tertiarySystemFill))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(settings.highContrast ? Color.primary : Color.clear, lineWidth: 1.5)
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

private struct TraitKeyMatch: Identifiable {
    let species: Species
    let matches: Int
    var id: String { species.id }
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
