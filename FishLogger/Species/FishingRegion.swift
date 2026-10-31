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

    /// Region for a province or state as the geocoder reports it, either "ON" or "Ontario".
    static func from(administrativeArea area: String) -> FishingRegion? {
        let key = area.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return areaLookup[key]
    }

    private static let areaLookup: [String: FishingRegion] = {
        let table: [FishingRegion: [String]] = [
            .britishColumbia: ["bc", "british columbia"],
            .prairies: ["ab", "alberta", "sk", "saskatchewan", "mb", "manitoba"],
            .ontario: ["on", "ontario"],
            .quebec: ["qc", "quebec", "québec"],
            .atlanticCanada: ["nb", "new brunswick", "ns", "nova scotia", "pe", "pei", "prince edward island",
                              "nl", "newfoundland and labrador", "newfoundland"],
            .northernCanada: ["yt", "yukon", "nt", "northwest territories", "nu", "nunavut"],
            .alaska: ["ak", "alaska"],
            .pacificNorthwest: ["wa", "washington", "or", "oregon", "id", "idaho"],
            .california: ["ca", "california", "nv", "nevada"],
            .mountainWest: ["mt", "montana", "wy", "wyoming", "co", "colorado", "ut", "utah"],
            .southwest: ["az", "arizona", "nm", "new mexico"],
            .northernPlains: ["nd", "north dakota", "sd", "south dakota", "ne", "nebraska", "ks", "kansas"],
            .southernPlains: ["tx", "texas", "ok", "oklahoma"],
            .upperMidwest: ["mn", "minnesota", "wi", "wisconsin", "mi", "michigan", "ia", "iowa"],
            .ohioValley: ["il", "illinois", "in", "indiana", "oh", "ohio", "mo", "missouri", "ky", "kentucky"],
            .northeast: ["me", "maine", "nh", "new hampshire", "vt", "vermont", "ma", "massachusetts",
                         "ri", "rhode island", "ct", "connecticut", "ny", "new york", "pa", "pennsylvania",
                         "nj", "new jersey"],
            .midAtlantic: ["md", "maryland", "de", "delaware", "va", "virginia", "wv", "west virginia",
                           "dc", "district of columbia"],
            .southeast: ["nc", "north carolina", "sc", "south carolina", "ga", "georgia", "tn", "tennessee",
                         "al", "alabama", "ms", "mississippi", "ar", "arkansas", "la", "louisiana"],
            .florida: ["fl", "florida"]
        ]
        var lookup: [String: FishingRegion] = [:]
        for (region, names) in table {
            for name in names { lookup[name] = region }
        }
        return lookup
    }()
}
