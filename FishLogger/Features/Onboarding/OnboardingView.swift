import SwiftUI

/// First launch: where you fish, what you fish for, done. Every step can be skipped, and
/// skipping leaves the whole continent's species in play.
struct OnboardingView: View {
    let onFinish: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var step: Step = .welcome
    @State private var regions: Set<FishingRegion> = []
    @State private var groups: Set<SpeciesGroup> = []
    /// Steps swap in place, so nothing tells VoiceOver the screen changed. Focus moves to the new
    /// step's heading instead of staying on the bottom button, whose label just changed.
    @AccessibilityFocusState private var headingFocused: Bool
    /// False until the first move, so the welcome screen opens the way VoiceOver normally starts.
    @State private var hasMoved = false

    enum Step: Int, CaseIterable {
        case welcome, regions, targets, done
    }

    var body: some View {
        NavigationStack {
            content
                .task(id: step) { await focusHeading() }
                // The two-finger scrub goes back a step, like it does on a pushed screen.
                .accessibilityAction(.escape) {
                    if step != .welcome { move(by: -1) }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if step != .welcome {
                            Button { move(by: -1) } label: {
                                Label("Back", systemImage: "chevron.backward")
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        if step != .done {
                            Button("Skip") { skip() }
                        }
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomBar
                }
        }
        .interactiveDismissDisabled()
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:
            welcome
        case .regions:
            List {
                Section {
                    stepHeader(
                        title: "Where do you fish?",
                        detail: "Pick one or more. Species lists start with fish from these places. Change it any time in Settings."
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 0, trailing: 4))
                RegionPickerSections(selection: $regions)
            }
            .listStyle(.insetGrouped)
        case .targets:
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    stepHeader(
                        title: "What do you fish for?",
                        detail: "These go first on your quick log. Pick none for a bit of everything."
                    )
                    TargetFishGrid(selection: $groups)
                }
                .padding(16)
            }
            .background(Theme.screenBackground)
        case .done:
            doneStep
        }
    }

    private var welcome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Image(systemName: "fish.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 32)
                    .accessibilityHidden(true)
                Text("Fish Logger")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($headingFocused)
                VStack(alignment: .leading, spacing: 18) {
                    point("hand.tap.fill", "Tap a fish to log it. That's the whole job on the water.")
                    point("cloud.sun.fill", "Weather, pressure, and the moon fill in on their own.")
                    point("antenna.radiowaves.left.and.right.slash", "Works with no signal. Everything stays on your phone.")
                }
                Text("Two quick questions so the app shows the fish where you live.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.screenBackground)
    }

    private var doneStep: some View {
        let suggested = SpeciesCatalog.suggested(regions: regions, groups: groups, limit: 8)
        let count = SpeciesCatalog.available(in: regions).count
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepHeader(title: "You're set", detail: doneDetail(count: count))
                Text("Your quick log starts with")
                    .font(.headline)
                LazyVGrid(columns: suggestionColumns, spacing: 10) {
                    ForEach(suggested) { species in
                        HStack(spacing: 10) {
                            SpeciesIcon(species: species, size: 30)
                            Text(species.commonName)
                                .font(.subheadline)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardBackground(tint: species.color)
                        .accessibilityElement(children: .combine)
                    }
                }
                Text("Fish you catch move to the front on their own. Long-press a tile to make it a favourite.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        }
        .background(Theme.screenBackground)
    }

    /// Two or more columns normally, one at accessibility text sizes so names do not break mid-word.
    private var suggestionColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: 10)]
        }
        return [GridItem(.adaptive(minimum: 140), spacing: 10)]
    }

    private var bottomBar: some View {
        Button {
            if step == .done { finish() } else { move(by: 1) }
        } label: {
            Text(primaryTitle)
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.bar)
    }

    private var primaryTitle: String {
        switch step {
        case .welcome: "Get started"
        case .regions: regions.isEmpty ? "Skip this step" : "Next"
        case .targets: groups.isEmpty ? "Skip this step" : "Next"
        case .done: "Done"
        }
    }

    private func doneDetail(count: Int) -> String {
        let place = regions.isEmpty ? "across North America" : "in \(regionList)"
        return "\(count) species \(place). Change this any time in Settings, Your fishing."
    }

    private var regionList: String {
        let names = FishingRegion.allCases.filter { regions.contains($0) }.map(\.label)
        if names.count <= 2 { return names.joined(separator: " and ") }
        return "\(names[0]), \(names[1]) and \(names.count - 2) more"
    }

    private func stepHeader(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title.bold())
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($headingFocused)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func point(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 30)
                .accessibilityHidden(true)
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Waits for the step change to finish, so the new heading is on screen before focus moves.
    /// Only one step shows at a time, so one flag covers every heading.
    private func focusHeading() async {
        guard hasMoved else { return }
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }
        headingFocused = true
    }

    private func move(by offset: Int) {
        guard let next = Step(rawValue: step.rawValue + offset) else { return }
        hasMoved = true
        headingFocused = false
        if reduceMotion {
            step = next
        } else {
            withAnimation(.easeInOut(duration: 0.25)) { step = next }
        }
    }

    private func skip() {
        // Skipping keeps whatever was already picked, so "pick a region, skip the rest" works.
        settings.homeRegions = regions
        settings.targetGroups = groups
        settings.hasSeenWelcome = true
        onFinish()
    }

    /// Setup only saves choices. It never starts a trip, because people often set up at home.
    private func finish() {
        skip()
    }
}
