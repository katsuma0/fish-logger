import Foundation
import SwiftUI

enum SpeciesGroup: String, CaseIterable, Identifiable {
    case pike, perch, blackBass, sunfish, temperateBass, troutChar, salmon, whitefish, catfish, ancient, carpSuckers, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pike: "Pike, muskie and pickerel"
        case .perch: "Walleye and perch"
        case .blackBass: "Black bass"
        case .sunfish: "Sunfish and crappie"
        case .temperateBass: "White bass and stripers"
        case .troutChar: "Trout and char"
        case .salmon: "Salmon"
        case .whitefish: "Whitefish and grayling"
        case .catfish: "Catfish and bullheads"
        case .ancient: "Sturgeon, gar and bowfin"
        case .carpSuckers: "Carp, suckers and buffalo"
        case .other: "Everything else"
        }
    }

    /// How an angler would say it when asked what they fish for.
    var targetLabel: String {
        switch self {
        case .pike: "Pike and muskie"
        case .perch: "Walleye and perch"
        case .blackBass: "Bass"
        case .sunfish: "Panfish"
        case .temperateBass: "Stripers and white bass"
        case .troutChar: "Trout"
        case .salmon: "Salmon"
        case .whitefish: "Whitefish"
        case .catfish: "Catfish"
        case .ancient: "Sturgeon and gar"
        case .carpSuckers: "Carp"
        case .other: "Whatever bites"
        }
    }

    /// Groups offered in the "what do you fish for" step. "Everything else" is implied by skipping.
    static var targetChoices: [SpeciesGroup] { allCases.filter { $0 != .other } }

    /// The fish that stands for the group in pickers.
    var representativeSpeciesID: String {
        switch self {
        case .pike: "northern_pike"
        case .perch: "walleye"
        case .blackBass: "largemouth_bass"
        case .sunfish: "bluegill"
        case .temperateBass: "striped_bass"
        case .troutChar: "rainbow_trout"
        case .salmon: "chinook_salmon"
        case .whitefish: "lake_whitefish"
        case .catfish: "channel_catfish"
        case .ancient: "lake_sturgeon"
        case .carpSuckers: "common_carp"
        case .other: "freshwater_drum"
        }
    }
}

/// Visible features used by the offline "what am I looking at" checklist.
enum FishTrait: String, CaseIterable, Identifiable {
    // Shape
    case torpedoBody, deepFlatBody, duckbillSnout, longToothySnout, largeMouth, smallMouth
    // Fins and tail
    case adiposeFin, spinyDorsal, twoSeparateDorsals, longDorsalFin, forkedTail, squareTail, roundedTail
    // Head and skin
    case barbels, bonyPlates, smoothSkin, earFlap, glassyEye
    // Markings and colour
    case verticalBars, darkSpotsLightBody, lightSpotsDarkBody, pinkOrRedStripe, whiteFinEdges,
         whiteTailTip, goldenColor, silverColor, darkMottling

    var id: String { rawValue }

    enum Category: String, CaseIterable, Identifiable {
        case shape, fins, head, markings
        var id: String { rawValue }
        var label: String {
            switch self {
            case .shape: "Body shape"
            case .fins: "Fins and tail"
            case .head: "Head and skin"
            case .markings: "Markings and colour"
            }
        }
    }

    var category: Category {
        switch self {
        case .torpedoBody, .deepFlatBody, .duckbillSnout, .longToothySnout, .largeMouth, .smallMouth: .shape
        case .adiposeFin, .spinyDorsal, .twoSeparateDorsals, .longDorsalFin, .forkedTail, .squareTail, .roundedTail: .fins
        case .barbels, .bonyPlates, .smoothSkin, .earFlap, .glassyEye: .head
        case .verticalBars, .darkSpotsLightBody, .lightSpotsDarkBody, .pinkOrRedStripe, .whiteFinEdges,
             .whiteTailTip, .goldenColor, .silverColor, .darkMottling: .markings
        }
    }

    var label: String {
        switch self {
        case .torpedoBody: "Long, round body"
        case .deepFlatBody: "Tall, flat body"
        case .duckbillSnout: "Flat duckbill jaw"
        case .longToothySnout: "Long beak with teeth"
        case .largeMouth: "Big mouth"
        case .smallMouth: "Small mouth"
        case .adiposeFin: "Little fin near tail"
        case .spinyDorsal: "Spiny back fin"
        case .twoSeparateDorsals: "Two back fins"
        case .longDorsalFin: "Very long back fin"
        case .forkedTail: "Forked tail"
        case .squareTail: "Square tail"
        case .roundedTail: "Rounded tail"
        case .barbels: "Whiskers"
        case .bonyPlates: "Bony plates"
        case .smoothSkin: "Smooth, slimy skin"
        case .earFlap: "Dark ear flap"
        case .glassyEye: "Big glassy eye"
        case .verticalBars: "Vertical bars"
        case .darkSpotsLightBody: "Dark spots"
        case .lightSpotsDarkBody: "Light spots"
        case .pinkOrRedStripe: "Pink or red stripe"
        case .whiteFinEdges: "White fin edges"
        case .whiteTailTip: "White tip on tail"
        case .goldenColor: "Gold or bronze"
        case .silverColor: "Bright silver"
        case .darkMottling: "Blotchy pattern"
        }
    }

    var detail: String {
        switch self {
        case .torpedoBody: "Body is long and fairly round, built for speed."
        case .deepFlatBody: "Body is tall and thin from the side, like a dinner plate."
        case .duckbillSnout: "Long, flat snout shaped like a duck's bill, full of teeth."
        case .longToothySnout: "Narrow beak-like snout lined with needle teeth."
        case .largeMouth: "Jaw reaches back past the eye."
        case .smallMouth: "Jaw stops well before the eye."
        case .adiposeFin: "Small fleshy fin with no rays on the back, just ahead of the tail."
        case .spinyDorsal: "Front of the back fin has stiff, sharp spines."
        case .twoSeparateDorsals: "Two distinct back fins with a gap between them."
        case .longDorsalFin: "Back fin runs most of the length of the body."
        case .forkedTail: "Tail splits into two clear points."
        case .squareTail: "Tail edge is nearly straight."
        case .roundedTail: "Tail edge curves outward."
        case .barbels: "Whisker-like feelers around the mouth or chin."
        case .bonyPlates: "Rows of hard, armour-like plates along the body."
        case .smoothSkin: "No obvious scales, skin feels slick."
        case .earFlap: "Dark flap at the back of the gill cover."
        case .glassyEye: "Large, cloudy, reflective eye."
        case .verticalBars: "Dark bands running top to bottom."
        case .darkSpotsLightBody: "Dark spots on a lighter body."
        case .lightSpotsDarkBody: "Pale or coloured spots on a darker body."
        case .pinkOrRedStripe: "Pink, red, or rosy band along the side."
        case .whiteFinEdges: "Lower fins have a bright white front edge."
        case .whiteTailTip: "White patch on the bottom tip of the tail."
        case .goldenColor: "Gold, brassy, or bronze colouring."
        case .silverColor: "Mostly bright, plain silver."
        case .darkMottling: "Irregular dark blotches or marbling."
        }
    }
}

struct Species: Identifiable, Hashable {
    let id: String
    let commonName: String
    let otherNames: [String]
    let scientificName: String
    let group: SpeciesGroup
    /// One or two plain sentences about the fish.
    let summary: String
    /// How to tell it apart, most useful first.
    let idTips: [String]
    /// Ids of species it gets confused with.
    let lookalikes: [String]
    let traits: Set<FishTrait>
    /// Upper bounds in cm for dink, small, medium and large, ascending. At or above the last value is trophy.
    let sizeCutoffsCm: [Double]
    /// Standard weight equation: log10(weight g) = weightA + weightB * log10(total length mm).
    let weightA: Double?
    let weightB: Double?
    /// Tile colour, 0xRRGGBB.
    let colorHex: UInt32
    let habitat: String
    /// Where it lives, in plain words.
    let range: String
    /// Broad regions where anglers catch it. Empty means unknown, and the fish then shows everywhere.
    var regions: Set<FishingRegion> = []

    static func == (lhs: Species, rhs: Species) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension Species {
    var color: Color { Color(hex: colorHex) }

    func sizeClass(forLengthCm length: Double) -> SizeClass {
        let cutoffs = sizeCutoffsCm
        guard cutoffs.count == 4 else { return .medium }
        if length < cutoffs[0] { return .dink }
        if length < cutoffs[1] { return .small }
        if length < cutoffs[2] { return .medium }
        if length < cutoffs[3] { return .large }
        return .trophy
    }

    /// Length range in cm for a size class. Dink has no lower bound, trophy has no upper bound.
    func lengthRange(for sizeClass: SizeClass) -> (lower: Double?, upper: Double?) {
        let cutoffs = sizeCutoffsCm
        guard cutoffs.count == 4 else { return (nil, nil) }
        switch sizeClass {
        case .dink: return (nil, cutoffs[0])
        case .small: return (cutoffs[0], cutoffs[1])
        case .medium: return (cutoffs[1], cutoffs[2])
        case .large: return (cutoffs[2], cutoffs[3])
        case .trophy: return (cutoffs[3], nil)
        }
    }

    /// A typical length for the class, used when a fish was bucketed instead of measured.
    func representativeLengthCm(for sizeClass: SizeClass) -> Double {
        let range = lengthRange(for: sizeClass)
        switch (range.lower, range.upper) {
        case let (lower?, upper?): return (lower + upper) / 2
        case let (nil, upper?): return upper * 0.8
        case let (lower?, nil): return lower * 1.1
        default: return 30
        }
    }

    /// Weight from the standard weight equation. Returns nil for species without one.
    func estimatedWeightKg(lengthCm: Double) -> Double? {
        guard let weightA, let weightB, lengthCm > 0 else { return nil }
        let grams = pow(10, weightA + weightB * log10(lengthCm * 10))
        return grams / 1000
    }

    /// True when the fish is caught in any of the given regions. No selection means everywhere.
    func lives(in selected: Set<FishingRegion>) -> Bool {
        selected.isEmpty || regions.isEmpty || !regions.isDisjoint(with: selected)
    }

    /// Every name a person might type, lowercased, for search.
    var searchableNames: [String] {
        ([commonName, scientificName] + otherNames).map { $0.lowercased() }
    }
}
