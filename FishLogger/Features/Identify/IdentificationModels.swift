import Foundation

/// One possible species for a photo, with how sure the engine was.
struct IdentificationCandidate: Identifiable, Hashable {
    let speciesID: String
    /// 0 to 1.
    let confidence: Double
    /// The visible feature that decided it. Empty when the engine gives no reason.
    let reason: String

    init(speciesID: String, confidence: Double, reason: String = "") {
        self.speciesID = speciesID
        self.confidence = confidence
        self.reason = reason
    }

    var id: String { speciesID }

    var species: Species { SpeciesCatalog.species(id: speciesID) ?? SpeciesCatalog.unknown }

    var percentText: String { "\(Int((confidence * 100).rounded()))%" }
}

/// What an engine made of a photo. Candidates are sorted most likely first.
struct IdentificationResult: Equatable {
    let isFish: Bool
    let candidates: [IdentificationCandidate]
    /// What limited the ID, such as blur. Empty when nothing did.
    let photoNotes: String
    let source: IdentificationSource

    init(isFish: Bool, candidates: [IdentificationCandidate], photoNotes: String = "", source: IdentificationSource) {
        self.isFish = isFish
        self.candidates = candidates
        self.photoNotes = photoNotes
        self.source = source
    }

    var best: IdentificationCandidate? { candidates.first }
}

/// Every way Photo ID can fail, with a message fit to show as is. Most point at the checklist,
/// because it works with no network and no key.
enum IdentificationError: LocalizedError, Equatable {
    case notConfigured
    case photoIDDisabled
    case invalidAPIKey
    case rateLimited
    case busy
    case offline
    case refused
    case api(statusCode: Int, message: String)
    case badResponse
    case imageUnreadable
    case modelUnavailable
    case failed(String)

    var message: String {
        switch self {
        case .notConfigured:
            return "To use Photo ID, add an Anthropic API key in Settings under Photo ID. The checklist works offline."
        case .photoIDDisabled:
            return "Photo ID is turned off in Settings. The checklist works offline."
        case .invalidAPIKey:
            return "That API key did not work. Check it in Settings."
        case .rateLimited:
            return "Too many requests right now. Try again in a minute."
        case .busy:
            return "Claude is busy. Try again shortly, or use the checklist."
        case .offline:
            return "No connection, so Photo ID cannot run. The checklist works offline."
        case .refused:
            return "Claude would not identify this photo. Try another photo, or use the checklist."
        case .api(_, let message):
            return message
        case .badResponse:
            return "Claude sent back something unexpected. Try again, or use the checklist."
        case .imageUnreadable:
            return "Could not read that photo. Try another one."
        case .modelUnavailable:
            return "The on-device model is not installed. Use the checklist instead."
        case .failed(let message):
            return message
        }
    }

    var errorDescription: String? { message }

    /// Sending the same photo again can work. A bad key, a refusal, or a missing model fails the same
    /// way every time, and a refused photo would only be sent and billed again.
    var isRetryable: Bool {
        switch self {
        case .rateLimited, .busy, .offline, .badResponse, .failed:
            return true
        case .api(let statusCode, _):
            return statusCode >= 500
        default:
            return false
        }
    }

    /// Fixed on the Photo ID settings page: the switch, the key, or the model name.
    var needsSetup: Bool {
        switch self {
        case .notConfigured, .photoIDDisabled, .invalidAPIKey:
            return true
        case .api(let statusCode, _):
            return (400..<500).contains(statusCode)
        default:
            return false
        }
    }
}
