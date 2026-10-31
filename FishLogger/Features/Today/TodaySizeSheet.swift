import SwiftData
import SwiftUI

/// The size of a fish just logged, in a small sheet opened from the logged confirmation. Picking a
/// size saves it and closes the sheet, so it costs one extra tap.
struct TodaySizeSheet: View {
    let fishCatch: FishCatch
    let onChange: (SizeClass?) -> Void
    let onDetails: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .body) private var sheetHeight: CGFloat = 260
    @State private var selection: SizeClass?

    init(fishCatch: FishCatch, onChange: @escaping (SizeClass?) -> Void, onDetails: @escaping () -> Void) {
        self.fishCatch = fishCatch
        self.onChange = onChange
        self.onDetails = onDetails
        _selection = State(initialValue: fishCatch.sizeClass)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SizeClassPicker(selection: selectionBinding, species: fishCatch.species)
                    Button(action: onDetails) {
                        Label("More details", systemImage: "square.and.pencil")
                            .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityHint("Opens everything for this catch")
                }
                .padding(16)
            }
            .navigationTitle("\(fishCatch.speciesName) size")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(sheetHeight), .large])
        .presentationDragIndicator(.visible)
    }

    private var selectionBinding: Binding<SizeClass?> {
        Binding<SizeClass?>(
            get: { selection },
            set: { newValue in
                selection = newValue
                fishCatch.sizeClass = newValue
                CatchLogger.save(modelContext)
                onChange(newValue)
                // Tapping the picked size again clears it; keep the sheet open for another pick then.
                if newValue != nil {
                    dismiss()
                }
            }
        )
    }
}
