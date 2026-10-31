import SwiftData
import SwiftUI

/// Catches on the running trip, newest first. The plus button repeats a catch, which is most of a good day.
struct TodayCatchList: View {
    let catches: [FishCatch]
    let onOpen: (FishCatch) -> Void
    let onAnother: (FishCatch) -> Void
    let onDelete: (FishCatch) -> Void

    @Environment(AppSettings.self) private var settings
    /// Delete asks first: a stray tap in a rocking boat should not lose a fish.
    @State private var pendingDelete: FishCatch?

    init(
        catches: [FishCatch],
        onOpen: @escaping (FishCatch) -> Void,
        onAnother: @escaping (FishCatch) -> Void,
        onDelete: @escaping (FishCatch) -> Void
    ) {
        self.catches = catches
        self.onOpen = onOpen
        self.onAnother = onAnother
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This trip")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            LazyVStack(spacing: 8) {
                ForEach(catches) { fishCatch in
                    row(for: fishCatch)
                }
            }
        }
        .confirmationDialog(
            "Delete this catch?",
            isPresented: deleteDialogBinding,
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { fishCatch in
            Button("Delete", role: .destructive) {
                pendingDelete = nil
                onDelete(fishCatch)
            }
            Button("Cancel", role: .cancel) {
                pendingDelete = nil
            }
        } message: { fishCatch in
            Text("\(fishCatch.speciesName), \(fishCatch.timestamp.formatted(date: .omitted, time: .shortened))")
        }
    }

    private var deleteDialogBinding: Binding<Bool> {
        Binding<Bool>(
            get: { pendingDelete != nil },
            set: { isShown in
                if !isShown { pendingDelete = nil }
            }
        )
    }

    private func row(for fishCatch: FishCatch) -> some View {
        let anotherLabel = "Log another \(fishCatch.speciesName.lowercased())"
        return HStack(spacing: 4) {
            Button {
                onOpen(fishCatch)
            } label: {
                CatchRow(fishCatch: fishCatch)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the catch details")
            .accessibilityAction(named: Text("Delete")) { pendingDelete = fishCatch }

            Button {
                onAnother(fishCatch)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: settings.buttonSize.minTapSize, height: settings.buttonSize.minTapSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(anotherLabel)
            .accessibilityHint("Logs one more of the same species and size")
        }
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .padding(.vertical, 6)
        .frame(minHeight: settings.buttonSize.minTapSize)
        .cardBackground()
        .contextMenu {
            Button {
                onAnother(fishCatch)
            } label: {
                Label("Another one", systemImage: "plus.circle")
            }
            Button {
                onOpen(fishCatch)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
                pendingDelete = fishCatch
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
