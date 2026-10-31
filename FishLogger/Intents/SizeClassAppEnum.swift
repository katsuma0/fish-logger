import AppIntents
import Foundation

/// `SizeClass` for Siri and Shortcuts. Kept separate so the model enum does not depend on App Intents.
enum SizeClassAppEnum: String, AppEnum {
    case dink, small, medium, large, trophy

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Size"

    static var caseDisplayRepresentations: [SizeClassAppEnum: DisplayRepresentation] = [
        .dink: "Dink",
        .small: "Small",
        .medium: "Medium",
        .large: "Large",
        .trophy: "Trophy"
    ]

    var sizeClass: SizeClass {
        switch self {
        case .dink: return .dink
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .trophy: return .trophy
        }
    }
}
