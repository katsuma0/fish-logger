import SwiftUI
import UIKit

/// Last step before logging: check the species, optionally pick a size and count, then log.
/// Pushed inside IdentifyView's NavigationStack. Logging itself happens in IdentifyView so it can
/// dismiss the whole sheet.
struct IdentifyConfirmView: View {
    let species: Species
    let photo: UIImage?
    let source: IdentificationSource
    let onLog: (SizeClass?, Int) -> Void

    @Environment(AppSettings.self) private var settings
    @State private var sizeClass: SizeClass? = nil
    @State private var count = 1

    init(species: Species, photo: UIImage?, source: IdentificationSource, onLog: @escaping (SizeClass?, Int) -> Void) {
        self.species = species
        self.photo = photo
        self.source = source
        self.onLog = onLog
    }

    private var isUnknown: Bool { species.id == SpeciesCatalog.unknownID }

    private var logTitle: String {
        isUnknown ? "Log as unknown fish" : "Log \(species.commonName)"
    }

    var body: some View {
        List {
            Section {
                header
            }

            if !species.idTips.isEmpty {
                Section("Check before you log") {
                    ForEach(Array(species.idTips.prefix(3).enumerated()), id: \.offset) { entry in
                        Label(entry.element, systemImage: "checkmark.circle")
                            .font(.subheadline)
                    }
                }
            }

            Section {
                SizeClassPicker(selection: $sizeClass, species: isUnknown ? nil : species)
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            } header: {
                Text("Size")
            } footer: {
                Text("Optional. Tap again to clear.")
            }

            Section {
                Stepper(value: $count, in: 1...99) {
                    HStack {
                        Text("How many")
                        Spacer()
                        Text("\(count)")
                            .font(.body.monospacedDigit().weight(.semibold))
                    }
                }
                .frame(minHeight: settings.buttonSize.minTapSize)
            }

            Section {
                Button {
                    onLog(sizeClass, count)
                } label: {
                    Label(logTitle, systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(PrimaryActionButtonStyle(tint: isUnknown ? Color.gray : species.color))
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(isUnknown ? "Unknown fish" : species.commonName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 14) {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityHidden(true)
            } else {
                SpeciesIcon(species: species, size: 56)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(isUnknown ? "Unknown fish" : species.commonName)
                    .font(.title3.weight(.semibold))
                if !species.scientificName.isEmpty {
                    Text(species.scientificName)
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.secondary)
                }
                Text(source.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
