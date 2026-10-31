import SwiftUI

/// One guess from photo ID: species, how sure, why, and the quickest way to double-check it.
struct IdentifyCandidateRow: View {
    let candidate: IdentificationCandidate

    @Environment(AppSettings.self) private var settings
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(candidate: IdentificationCandidate) {
        self.candidate = candidate
    }

    var body: some View {
        let species = candidate.species
        HStack(alignment: .top, spacing: 12) {
            SpeciesIcon(species: species, size: 44)
            VStack(alignment: .leading, spacing: 5) {
                // At accessibility sizes the percentage goes under the name, so the name is never squeezed.
                if dynamicTypeSize.isAccessibilitySize {
                    Text(species.commonName)
                        .font(.headline)
                    percentLabel
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(species.commonName)
                            .font(.headline)
                        Spacer(minLength: 8)
                        percentLabel
                    }
                }
                ProgressView(value: candidate.confidence)
                    .tint(species.color)
                if !candidate.reason.isEmpty {
                    Text(candidate.reason)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let tip = species.idTips.first {
                    Label(tip, systemImage: "lightbulb")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 4)
        .frame(minHeight: settings.buttonSize.minTapSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenSummary(for: species))
        .accessibilityHint("Opens the log screen for this species")
    }

    private var percentLabel: some View {
        Text(candidate.percentText)
            .font(.subheadline.monospacedDigit().weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func spokenSummary(for species: Species) -> String {
        var parts = ["\(species.commonName), \(candidate.percentText) likely"]
        if !candidate.reason.isEmpty { parts.append(candidate.reason) }
        return parts.joined(separator: ". ")
    }
}
