import Combine
import SwiftData
import SwiftUI
import UIKit

/// Stats tab root. The numbers are worked out off the main thread into `snapshot` whenever the
/// filters or the log change, never in `body`, so scrolling, filtering, and logging on other tabs
/// stay smooth however long the log gets.
struct StatsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.displayScale) private var displayScale

    @State private var range: StatsRange = .allTime
    @State private var speciesFilter: String? = nil
    /// What the screen shows. The old one stays up while a new one is worked out, so changing a
    /// filter never blanks the screen.
    @State private var snapshot: StatsSnapshot? = nil
    /// Nil until the tab first appears, so nothing is worked out for a tab nobody has opened.
    @State private var dataVersion: StatsDataVersion? = nil
    /// The record catch opened from Personal bests.
    @State private var openCatch: FishCatch? = nil
    @State private var cache = StatsCache()
    /// Menus only draw plain images, so species icons are rendered once and reused.
    @State private var menuIcons: [String: UIImage] = [:]

    init() {}

    var body: some View {
        NavigationStack {
            // This ZStack keeps one view on screen while `content` swaps between loading, empty,
            // and the stats, so appear and disappear only fire for real visibility changes.
            ZStack {
                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.screenBackground)
            .safeAreaInset(edge: .top, spacing: 0) {
                if hasActiveFilters {
                    filterChips
                }
            }
            .navigationTitle("Stats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if hasTrips {
                        filterMenu
                    }
                }
            }
            .sheet(item: $openCatch, onDismiss: { catchEditorClosed() }) { fishCatch in
                NavigationStack {
                    CatchEditorView(fishCatch: fishCatch)
                }
            }
            // On the root, not the stack, so a pushed page counts as Stats being out of sight.
            .onAppear { appeared() }
            .onDisappear { cache.isVisible = false }
        }
        .task(id: statsKey) {
            await recompute()
        }
        .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave).receive(on: DispatchQueue.main)) { _ in
            modelSaved()
        }
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        if let snapshot {
            if snapshot.totalTripCount == 0 {
                ContentUnavailableView(
                    "No trips yet",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Start a trip from the Today tab and tap a species for each fish.")
                )
            } else if snapshot.stats.catches.isEmpty {
                noFish(snapshot.stats)
            } else {
                sections(snapshot)
            }
        } else {
            ProgressView()
        }
    }

    /// Lazy, so the condition charts and lists further down are only built when scrolled to.
    private func sections(_ snapshot: StatsSnapshot) -> some View {
        let stats = snapshot.stats
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                StatsSummaryGrid(stats: stats)
                if stats.speciesID == nil {
                    StatsSpeciesChart(items: stats.bySpecies, onSelect: { speciesID in
                        speciesFilter = speciesID
                    })
                }
                StatsTopLuresSection(lures: stats.topLures)
                StatsHourChart(items: stats.byHourOfDay)
                // One bar says nothing, so This month skips the month chart.
                if stats.range != .thisMonth {
                    StatsMonthChart(items: stats.byMonth)
                }
                StatsSizeChart(items: stats.sizeClassCounts)
                StatsConditionsSection(
                    groups: snapshot.conditionGroups,
                    hiddenTitles: snapshot.hiddenConditionTitles
                )
                if !stats.personalBests.isEmpty {
                    StatsPersonalBestsSection(bests: stats.personalBests, onOpenCatch: { catchID in
                        openRecord(catchID)
                    })
                }
                if !stats.topSpots.isEmpty {
                    StatsTopSpotsSection(spots: stats.topSpots, scopeLabel: stats.range.label)
                }
            }
            .padding()
        }
    }

    /// Reads the filters the snapshot was made with, so the message matches what is on screen.
    @ViewBuilder
    private func noFish(_ stats: StatsCalculator) -> some View {
        if stats.range != .allTime || stats.speciesID != nil {
            ContentUnavailableView {
                Label("No fish for these filters", systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text(filteredHint(stats))
            } actions: {
                Button("Clear filters") { clearFilters() }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accentFill)
            }
        } else {
            ContentUnavailableView(
                "No fish logged yet",
                systemImage: "chart.bar.xaxis",
                description: Text("Your trips have no catches yet. Tap a species on the Today tab when you land one.")
            )
        }
    }

    private func filteredHint(_ stats: StatsCalculator) -> String {
        if stats.speciesID == nil && stats.tripCount > 0 {
            return "\(StatsFormat.trips(stats.tripCount)) in this range with no fish logged. Pick a wider range to see more."
        }
        return "Nothing in the log fits these filters. Clear them to see everything."
    }

    // MARK: Filters

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let speciesID = speciesFilter {
                    StatsFilterChip(
                        title: StatsCalculator.speciesName(for: speciesID),
                        species: SpeciesCatalog.species(id: speciesID) ?? SpeciesCatalog.unknown,
                        systemImage: nil
                    ) {
                        speciesFilter = nil
                    }
                }
                if range != .allTime {
                    StatsFilterChip(title: range.label, species: nil, systemImage: "calendar") {
                        range = .allTime
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 4)
        .background(Theme.screenBackground)
    }

    private var filterMenu: some View {
        let speciesIDs = snapshot?.loggedSpeciesIDs ?? []
        return Menu {
            Picker(selection: $speciesFilter) {
                Text("All species").tag(String?.none)
                ForEach(speciesIDs, id: \.self) { speciesID in
                    Label {
                        Text(StatsCalculator.speciesName(for: speciesID))
                    } icon: {
                        menuIcon(for: speciesID)
                    }
                    .tag(Optional(speciesID))
                }
            } label: {
                Label("Species", systemImage: "fish")
            }
            .pickerStyle(.menu)

            Picker(selection: $range) {
                ForEach(StatsRange.allCases) { option in
                    Text(option.label).tag(option)
                }
            } label: {
                Label("Time", systemImage: "calendar")
            }
            .pickerStyle(.menu)

            if hasActiveFilters {
                Divider()
                Button {
                    clearFilters()
                } label: {
                    Label("Clear filters", systemImage: "xmark.circle")
                }
            }
        } label: {
            Label(
                "Filter",
                systemImage: hasActiveFilters
                    ? "line.3.horizontal.decrease.circle.fill"
                    : "line.3.horizontal.decrease.circle"
            )
        }
        .accessibilityValue(filterSummary)
    }

    private func menuIcon(for speciesID: String) -> Image {
        if let image = menuIcons[speciesID] {
            return Image(uiImage: image).renderingMode(.original)
        }
        return Image(systemName: "fish.fill")
    }

    private var hasActiveFilters: Bool {
        speciesFilter != nil || range != .allTime
    }

    private var hasTrips: Bool {
        (snapshot?.totalTripCount ?? 0) > 0
    }

    private var filterSummary: String {
        var parts: [String] = []
        if let speciesID = speciesFilter {
            parts.append(StatsCalculator.speciesName(for: speciesID))
        }
        if range != .allTime {
            parts.append(range.label)
        }
        return parts.isEmpty ? "No filters" : parts.joined(separator: ", ")
    }

    private func clearFilters() {
        speciesFilter = nil
        range = .allTime
    }

    // MARK: Opening a record

    private func openRecord(_ catchID: UUID) {
        if let fishCatch = StatsStore.fishCatch(id: catchID, in: modelContext) {
            openCatch = fishCatch
        } else {
            // Deleted since these numbers were worked out, so bring them up to date instead.
            refreshDataVersion(afterSave: true)
        }
    }

    /// The editor writes straight to the model, so count it as an edit even if nothing was saved yet.
    private func catchEditorClosed() {
        refreshDataVersion(afterSave: true)
    }

    // MARK: Keeping the numbers current

    private var statsKey: StatsKey {
        StatsKey(range: range, speciesID: speciesFilter, pressureUnit: settings.pressureUnit, version: dataVersion)
    }

    private func appeared() {
        cache.isVisible = true
        refreshDataVersion(afterSave: cache.hasUnseenSaves)
    }

    /// Saves while Stats is out of sight, or behind the catch editor, only leave a note. The work
    /// happens once, when the screen is back.
    private func modelSaved() {
        if cache.isVisible && openCatch == nil {
            refreshDataVersion(afterSave: true)
        } else {
            cache.hasUnseenSaves = true
        }
    }

    private func refreshDataVersion(afterSave: Bool) {
        cache.hasUnseenSaves = false
        let edits = (dataVersion?.edits ?? 0) + (afterSave ? 1 : 0)
        let next = StatsStore.dataVersion(in: modelContext, edits: edits)
        if next != dataVersion {
            dataVersion = next
        }
    }

    /// Copies the log once per data version on the main actor, then works out the numbers on a
    /// background thread. A newer key cancels this run, and a cancelled run never touches the screen.
    private func recompute() async {
        let key = statsKey
        guard let version = key.version else { return }
        // Coming back to the tab restarts this task with the same key. Nothing to do then.
        if snapshot != nil, cache.shownKey == key { return }

        let input: StatsInput
        if let cached = cache.input, cache.inputVersion == version {
            input = cached
        } else {
            input = StatsStore.input(in: modelContext)
            cache.input = input
            cache.inputVersion = version
        }

        let range = key.range
        let speciesID = key.speciesID
        let pressureUnit = key.pressureUnit
        let now = Date.now
        let calendar = Calendar.current
        let next = await Task.detached(priority: .userInitiated) {
            StatsSnapshot(
                input: input,
                range: range,
                speciesID: speciesID,
                pressureUnit: pressureUnit,
                now: now,
                calendar: calendar
            )
        }.value
        guard !Task.isCancelled else { return }

        snapshot = next
        cache.shownKey = key
        // A species whose last catch was deleted cannot stay picked, or the screen would be stuck empty.
        if let speciesFilter, !next.loggedSpeciesIDs.contains(speciesFilter) {
            self.speciesFilter = nil
        }
        renderMenuIcons(for: next.loggedSpeciesIDs)
    }

    private func renderMenuIcons(for speciesIDs: [String]) {
        var icons = menuIcons
        var changed = false
        for speciesID in speciesIDs where icons[speciesID] == nil {
            let renderer = ImageRenderer(content: SpeciesIcon(species: SpeciesCatalog.species(id: speciesID), size: 22))
            renderer.scale = displayScale
            if let image = renderer.uiImage {
                icons[speciesID] = image.withRenderingMode(.alwaysOriginal)
                changed = true
            }
        }
        if changed {
            menuIcons = icons
        }
    }
}

/// Everything the snapshot depends on. When it changes, `.task(id:)` works the numbers out again.
private struct StatsKey: Hashable {
    let range: StatsRange
    let speciesID: String?
    let pressureUnit: PressureUnit
    let version: StatsDataVersion?
}

/// Bookkeeping that never changes what is drawn. A class, so writing to it does not redraw the view.
private final class StatsCache {
    /// The last copy of the log, reused when only the filters change.
    var input: StatsInput?
    var inputVersion: StatsDataVersion?
    /// The key of the snapshot on screen.
    var shownKey: StatsKey?
    var isVisible = false
    /// A save landed while Stats was out of sight or behind a sheet.
    var hasUnseenSaves = false
}

#Preview {
    StatsView()
        .modelContainer(AppModelContainer.inMemory())
        .environment(AppSettings.shared)
}
