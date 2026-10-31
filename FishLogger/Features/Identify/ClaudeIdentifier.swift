import Foundation
import UIKit

/// Species ID from a photo through the Claude Messages API. There is no official Swift SDK, so this
/// is plain HTTPS. The request builders and the parser are static and pure so tests can pin the
/// exact wire format without a network.
struct ClaudeIdentifier {
    static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    static let apiVersion = "2026-10-21"
    /// Lets the API rerun a declined request on a fallback model chosen per refusal category,
    /// instead of handing the refusal back to us.
    static let betaHeader = "server-side-fallback-2026-07-01"
    static let maxTokens = 16000
    static let timeout: TimeInterval = 60

    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: Network

    func identify(image: UIImage, apiKey: String, model: String) async throws -> IdentificationResult {
        try await Self.identify(image: image, apiKey: apiKey, model: model, session: session)
    }

    static func identify(
        image: UIImage,
        apiKey: String,
        model: String,
        session: URLSession = .shared
    ) async throws -> IdentificationResult {
        guard let jpeg = ImageProcessing.identificationJPEG(from: image) else {
            throw IdentificationError.imageUnreadable
        }
        try Task.checkCancellation()
        let request = try makeURLRequest(
            imageBase64: jpeg.base64EncodedString(),
            apiKey: apiKey,
            model: model
        )

        let reply: (Data, URLResponse)
        do {
            reply = try await session.data(for: request)
        } catch let error as URLError {
            if error.code == .cancelled { throw CancellationError() }
            throw IdentificationError.offline
        }
        try Task.checkCancellation()

        guard let http = reply.1 as? HTTPURLResponse else { throw IdentificationError.badResponse }
        return try parseResponse(data: reply.0, statusCode: http.statusCode)
    }

    // MARK: Request

    static func makeURLRequest(imageBase64: String, apiKey: String, model: String) throws -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(betaHeader, forHTTPHeaderField: "anthropic-beta")
        let body = makeRequestBody(imageBase64: imageBase64, model: model)
        // Sorted keys keep the schema byte-identical between calls, so the server reuses its compiled copy.
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys, .withoutEscapingSlashes])
        return request
    }

    /// The JSON body. No temperature, top_p, top_k, or thinking settings: this API version rejects them.
    static func makeRequestBody(imageBase64: String, model: String) -> [String: Any] {
        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        let imageSource: [String: Any] = [
            "type": "base64",
            "media_type": "image/jpeg",
            "data": imageBase64
        ]
        let imageBlock: [String: Any] = ["type": "image", "source": imageSource]
        let textBlock: [String: Any] = ["type": "text", "text": userPrompt]
        let content: [[String: Any]] = [imageBlock, textBlock]
        let message: [String: Any] = ["role": "user", "content": content]
        let messages: [[String: Any]] = [message]
        let format: [String: Any] = ["type": "json_schema", "schema": responseSchema]
        let outputConfig: [String: Any] = ["effort": "low", "format": format]

        var body: [String: Any] = [:]
        body["model"] = trimmedModel.isEmpty ? AppSettings.defaultClaudeModel : trimmedModel
        body["max_tokens"] = maxTokens
        body["fallbacks"] = "default"
        body["output_config"] = outputConfig
        body["system"] = systemPrompt
        body["messages"] = messages
        return body
    }

    /// Every catalog id plus "unknown", so the answer always maps to something we can log.
    static var allowedSpeciesIDs: [String] {
        SpeciesCatalog.all.map(\.id) + [SpeciesCatalog.unknownID]
    }

    /// Structured output schema. Range keywords like minimum and maxLength are left out because the
    /// API does not accept them; confidences are clamped after parsing instead.
    static var responseSchema: [String: Any] {
        let speciesIDProperty: [String: Any] = ["type": "string", "enum": allowedSpeciesIDs]
        let confidenceProperty: [String: Any] = ["type": "number"]
        let reasonProperty: [String: Any] = ["type": "string"]
        let candidateProperties: [String: Any] = [
            "species_id": speciesIDProperty,
            "confidence": confidenceProperty,
            "reason": reasonProperty
        ]
        let candidateRequired: [String] = ["species_id", "confidence", "reason"]
        let candidate: [String: Any] = [
            "type": "object",
            "properties": candidateProperties,
            "required": candidateRequired,
            "additionalProperties": false
        ]
        let candidatesProperty: [String: Any] = ["type": "array", "items": candidate]
        let isFishProperty: [String: Any] = ["type": "boolean"]
        let notesProperty: [String: Any] = ["type": "string"]
        let properties: [String: Any] = [
            "is_fish": isFishProperty,
            "candidates": candidatesProperty,
            "photo_notes": notesProperty
        ]
        let required: [String] = ["is_fish", "candidates", "photo_notes"]
        let schema: [String: Any] = [
            "type": "object",
            "properties": properties,
            "required": required,
            "additionalProperties": false
        ]
        return schema
    }

    static let systemPrompt = """
    You identify freshwater fish in photos taken by an angler in Canada, mostly in Ontario. \
    Choose only from the species ids provided. \
    Give up to 3 candidates, most likely first, each with a confidence from 0 to 1. \
    The confidences together must add up to 1 or less. \
    Each reason is one short sentence naming the visible feature that decided it, \
    for example the white tip on the lower lobe of a walleye's tail. \
    Weigh common lookalikes carefully: walleye and sauger; northern pike, muskellunge, tiger muskie, \
    and chain pickerel; smallmouth and largemouth bass; black and white crappie; bluegill and pumpkinseed; \
    brook trout, splake, and lake trout; chinook and coho salmon; white bass, white perch, and striped bass. \
    If the photo shows no fish, set is_fish to false and return no candidates. \
    In photo_notes, say briefly what limited the identification, such as blur or a fish that is partly \
    hidden. Leave photo_notes empty if nothing did.
    """

    static let userPrompt: String = {
        let lines: [String] = SpeciesCatalog.all.map { species in
            if species.scientificName.isEmpty {
                return "\(species.id): \(species.commonName)"
            }
            return "\(species.id): \(species.commonName) (\(species.scientificName))"
        }
        let unknownLine = "\(SpeciesCatalog.unknownID): Not in this list, or cannot tell"
        return (["Which species is this? Options:"] + lines + [unknownLine]).joined(separator: "\n")
    }()

    // MARK: Response

    static func parseResponse(data: Data, statusCode: Int) throws -> IdentificationResult {
        guard (200..<300).contains(statusCode) else {
            throw statusError(statusCode: statusCode, data: data)
        }
        guard let root = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else {
            throw IdentificationError.badResponse
        }
        if let stopReason = root["stop_reason"] as? String, stopReason == "refusal" {
            throw IdentificationError.refused
        }

        // Only text blocks carry the answer. Thinking and fallback markers are skipped.
        let blocks = (root["content"] as? [[String: Any]]) ?? []
        var text = ""
        for block in blocks {
            guard let blockType = block["type"] as? String, blockType == "text" else { continue }
            if let part = block["text"] as? String { text += part }
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let payloadData = trimmed.data(using: .utf8) else {
            throw IdentificationError.badResponse
        }

        let payload: ClaudeIdentificationPayload
        do {
            payload = try JSONDecoder().decode(ClaudeIdentificationPayload.self, from: payloadData)
        } catch {
            throw IdentificationError.badResponse
        }

        let cleaned: [IdentificationCandidate] = payload.candidates.compactMap { item in
            let id = item.speciesID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard SpeciesCatalog.species(id: id) != nil else { return nil }
            let confidence = min(max(item.confidence, 0), 1)
            let reason = item.reason.trimmingCharacters(in: .whitespacesAndNewlines)
            return IdentificationCandidate(speciesID: id, confidence: confidence, reason: reason)
        }
        let sorted = cleaned.sorted { $0.confidence > $1.confidence }

        // A repeated species would break list identity, so keep only its strongest entry.
        var seen = Set<String>()
        var candidates: [IdentificationCandidate] = []
        for candidate in sorted {
            guard seen.insert(candidate.speciesID).inserted else { continue }
            candidates.append(candidate)
        }

        return IdentificationResult(
            isFish: payload.isFish,
            candidates: candidates,
            photoNotes: payload.photoNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            source: .claude
        )
    }

    static func statusError(statusCode: Int, data: Data) -> IdentificationError {
        switch statusCode {
        case 401:
            return .invalidAPIKey
        case 429:
            return .rateLimited
        case 500...599:
            // Includes 529, the API's overloaded status.
            return .busy
        default:
            let message = apiErrorMessage(from: data) ?? "Claude could not handle that request (error \(statusCode))."
            return .api(statusCode: statusCode, message: message)
        }
    }

    /// Reads `{"type": "error", "error": {"type": ..., "message": ...}}`.
    static func apiErrorMessage(from data: Data) -> String? {
        guard let root = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any],
              let error = root["error"] as? [String: Any],
              let message = error["message"] as? String
        else { return nil }
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

/// The schema JSON Claude writes into its text block. Lenient on optional pieces so a terse answer
/// still parses.
private struct ClaudeIdentificationPayload: Decodable {
    struct Candidate: Decodable {
        let speciesID: String
        let confidence: Double
        let reason: String

        enum CodingKeys: String, CodingKey {
            case speciesID = "species_id"
            case confidence
            case reason
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            speciesID = try container.decode(String.self, forKey: .speciesID)
            confidence = try container.decodeIfPresent(Double.self, forKey: .confidence) ?? 0
            reason = try container.decodeIfPresent(String.self, forKey: .reason) ?? ""
        }
    }

    let isFish: Bool
    let candidates: [Candidate]
    let photoNotes: String

    enum CodingKeys: String, CodingKey {
        case isFish = "is_fish"
        case candidates
        case photoNotes = "photo_notes"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedCandidates = try container.decodeIfPresent([Candidate].self, forKey: .candidates) ?? []
        candidates = decodedCandidates
        isFish = try container.decodeIfPresent(Bool.self, forKey: .isFish) ?? !decodedCandidates.isEmpty
        photoNotes = try container.decodeIfPresent(String.self, forKey: .photoNotes) ?? ""
    }
}
