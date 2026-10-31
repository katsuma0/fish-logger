import Foundation

/// Broad fishing regions of Canada and the United States. Coarse on purpose: anglers think in
/// "Ontario" or "the Gulf states", not watersheds, and species ranges rarely follow borders.
enum FishingRegion: String, CaseIterable, Codable, Identifiable {
    // Canada
    case britishColumbia, prairies, ontario, quebec, atlanticCanada, northernCanada
    // United States
    case alaska, pacificNorthwest, california, mountainWest, southwest, northernPlains, southernPlains,
         upperMidwest, ohioValley, northeast, midAtlantic, southeast, florida

    enum Country: String, CaseIterable, Identifiable {
        case canada, unitedStates
        var id: String { rawValue }
        var label: String { self == .canada ? "Canada" : "United States" }
    }

    var id: String { rawValue }

    var country: Country {
        switch self {
        case .britishColumbia, .prairies, .ontario, .quebec, .atlanticCanada, .northernCanada: .canada
        default: .unitedStates
        }
    }

    var label: String {
        switch self {
        case .britishColumbia: "British Columbia"
        case .prairies: "Prairies"
        case .ontario: "Ontario"
        case .quebec: "Quebec"
        case .atlanticCanada: "Atlantic Canada"
        case .northernCanada: "The North"
        case .alaska: "Alaska"
        case .pacificNorthwest: "Pacific Northwest"
        case .california: "California and Nevada"
        case .mountainWest: "Mountain West"
        case .southwest: "Southwest"
        case .northernPlains: "Northern Plains"
        case .southernPlains: "Texas and Oklahoma"
        case .upperMidwest: "Upper Midwest"
        case .ohioValley: "Ohio Valley"
        case .northeast: "Northeast"
        case .midAtlantic: "Mid-Atlantic"
        case .southeast: "Southeast"
        case .florida: "Florida"
        }
    }

    /// The provinces or states it covers, for the picker subtitle.
    var detail: String {
        switch self {
        case .britishColumbia: "BC"
        case .prairies: "Alberta, Saskatchewan, Manitoba"
        case .ontario: "Ontario"
        case .quebec: "Quebec"
        case .atlanticCanada: "New Brunswick, Nova Scotia, PEI, Newfoundland and Labrador"
        case .northernCanada: "Yukon, Northwest Territories, Nunavut"
        case .alaska: "Alaska"
        case .pacificNorthwest: "Washington, Oregon, Idaho"
        case .california: "California, Nevada"
        case .mountainWest: "Montana, Wyoming, Colorado, Utah"
        case .southwest: "Arizona, New Mexico"
        case .northernPlains: "North Dakota, South Dakota, Nebraska, Kansas"
        case .southernPlains: "Texas, Oklahoma"
        case .upperMidwest: "Minnesota, Wisconsin, Michigan, Iowa"
        case .ohioValley: "Illinois, Indiana, Ohio, Missouri, Kentucky"
        case .northeast: "New England, New York, Pennsylvania, New Jersey"
        case .midAtlantic: "Maryland, Delaware, Virginia, West Virginia"
        case .southeast: "Carolinas, Georgia, Tennessee, Alabama, Mississippi, Arkansas, Louisiana"
        case .florida: "Florida"
        }
    }

    static func regions(in country: Country) -> [FishingRegion] {
        allCases.filter { $0.country == country }
    }
}
