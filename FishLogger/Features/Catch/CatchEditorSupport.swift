import SwiftData
import SwiftUI

/// Which field has the keyboard, so the keyboard toolbar can put it away.
enum CatchEditorField: Hashable {
    case customName, length, weight, lure, depth, waterTemp, notes
}

extension FishCatch {
    /// The context the catch lives in, or nil once it is deleted. Reading attributes after a delete can
    /// crash, so every delayed step in the editor checks this before touching the model.
    var catchEditorLiveContext: ModelContext? {
        isDeleted ? nil : modelContext
    }

    var catchEditorIsGone: Bool { catchEditorLiveContext == nil }
}

enum CatchEditorQueries {
    /// Recent catches for lure suggestions. Capped so a long history does not load on every keystroke.
    static var recentCatches: FetchDescriptor<FishCatch> {
        var descriptor = FetchDescriptor<FishCatch>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        descriptor.fetchLimit = 300
        return descriptor
    }
}
