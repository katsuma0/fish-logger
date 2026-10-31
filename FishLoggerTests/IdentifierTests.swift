import Foundation
import Testing
@testable import FishLogger

/// Pins the Messages API wire format and the reply parser without a network.
struct IdentifierTests {
    private static let model = "claude-opus-5-5"

    /// What Claude writes into its text block for a clear walleye photo.
    private static let answer = #"""
    {"is_fish": true, "candidates": [{"species_id": "walleye", "confidence": 0.8, "reason": "White tip on the lower tail lobe."}, {"species_id": "sauger", "confidence": 0.15, "reason": "Body looks a little spotted."}], "photo_notes": "Tail is partly hidden."}
    """#

    /// A Messages API reply with these content blocks.
    private static func reply(_ content: [[String: Any]], stopReason: String = "end_turn") throws -> Data {
        let root: [String: Any] = [
            "id": "msg_test",
            "type": "message",
            "role": "assistant",
            "content": content,
            "stop_reason": stopReason
        ]
        return try JSONSerialization.data(withJSONObject: root)
    }

    private static func parse(_ data: Data) throws -> IdentificationResult {
        try ClaudeIdentifier.parseResponse(data: data, statusCode: 200)
    }

    // MARK: Request

    @Test func requestBodyNamesTheModelAndTokenLimit() {
        let body = ClaudeIdentifier.makeRequestBody(imageBase64: "abc", model: Self.model)
        #expect(body["model"] as? String == Self.model)
        #expect(body["max_tokens"] as? Int == ClaudeIdentifier.maxTokens)
    }

    @Test func blankModelFallsBackToTheDefault() {
        let body = ClaudeIdentifier.makeRequestBody(imageBase64: "abc", model: "  ")
        #expect(body["model"] as? String == AppSettings.defaultClaudeModel)
    }

    @Test func requestBodyAsksForJSONSchemaOutput() throws {
        let body = ClaudeIdentifier.makeRequestBody(imageBase64: "abc", model: Self.model)
        let outputConfig = try #require(body["output_config"] as? [String: Any])
        let format = try #require(outputConfig["format"] as? [String: Any])
        #expect(format["type"] as? String == "json_schema")
        let schema = try #require(format["schema"] as? [String: Any])
        #expect(schema["type"] as? String == "object")
        let properties = try #require(schema["properties"] as? [String: Any])
        #expect(properties.keys.contains("candidates"))
    }

    @Test func requestBodyHasNoSamplingSettings() {
        let body = ClaudeIdentifier.makeRequestBody(imageBase64: "abc", model: Self.model)
        for key in ["temperature", "top_p", "top_k"] {
            #expect(!body.keys.contains(key), "\(key) is rejected by this API version")
        }
    }

    @Test func urlRequestSendsTheKeyVersionAndAJSONBody() throws {
        let request = try ClaudeIdentifier.makeURLRequest(imageBase64: "abc", apiKey: "sk-test", model: Self.model)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "x-api-key") == "sk-test")
        #expect(request.value(forHTTPHeaderField: "anthropic-version") == ClaudeIdentifier.apiVersion)
        let data = try #require(request.httpBody)
        let object = try JSONSerialization.jsonObject(with: data)
        let decoded = try #require(object as? [String: Any])
        #expect(decoded["model"] as? String == Self.model)
        #expect(!decoded.keys.contains("temperature"))
    }

    // MARK: Response

    @Test func parsesANormalAnswer() throws {
        let result = try Self.parse(Self.reply([["type": "text", "text": Self.answer]]))
        #expect(result.isFish)
        #expect(result.candidates.map(\.speciesID) == ["walleye", "sauger"])
        #expect(result.best?.confidence == 0.8)
        #expect(result.best?.reason == "White tip on the lower tail lobe.")
        #expect(result.photoNotes == "Tail is partly hidden.")
        #expect(result.source == .claude)
    }

    @Test func skipsThinkingBlocks() throws {
        // The stray text field makes sure the parser goes by block type, not by which keys are there.
        let result = try Self.parse(Self.reply([
            ["type": "thinking", "thinking": "White tail tip, so walleye.", "text": "Not the answer", "signature": "sig"],
            ["type": "text", "text": Self.answer]
        ]))
        #expect(result.candidates.first?.speciesID == "walleye")
    }

    @Test func refusalStopReasonIsReported() throws {
        let data = try Self.reply([], stopReason: "refusal")
        #expect(throws: IdentificationError.refused) {
            try Self.parse(data)
        }
    }

    @Test func refusalWinsOverPartialText() throws {
        let data = try Self.reply([["type": "text", "text": Self.answer]], stopReason: "refusal")
        #expect(throws: IdentificationError.refused) {
            try Self.parse(data)
        }
    }

    @Test func textThatIsNotJSONIsABadResponse() throws {
        let data = try Self.reply([["type": "text", "text": "It looks like a walleye to me."]])
        #expect(throws: IdentificationError.badResponse) {
            try Self.parse(data)
        }
    }

    @Test func dropsUnknownIDsAndRepeatedSpecies() throws {
        let text = #"""
        {"is_fish": true, "candidates": [{"species_id": "walleye", "confidence": 0.5, "reason": "a"}, {"species_id": "not_a_fish", "confidence": 0.3, "reason": "b"}, {"species_id": "walleye", "confidence": 0.2, "reason": "c"}], "photo_notes": ""}
        """#
        let result = try Self.parse(Self.reply([["type": "text", "text": text]]))
        #expect(result.candidates.map(\.speciesID) == ["walleye"])
        #expect(result.best?.confidence == 0.5)
    }

    @Test func confidenceIsClampedToOne() throws {
        let text = #"{"is_fish": true, "candidates": [{"species_id": "walleye", "confidence": 1.7, "reason": ""}], "photo_notes": ""}"#
        let result = try Self.parse(Self.reply([["type": "text", "text": text]]))
        #expect(result.best?.confidence == 1)
    }

    @Test func httpErrorsMapToFriendlyErrors() {
        #expect(throws: IdentificationError.invalidAPIKey) {
            try ClaudeIdentifier.parseResponse(data: Data(), statusCode: 401)
        }
        #expect(throws: IdentificationError.rateLimited) {
            try ClaudeIdentifier.parseResponse(data: Data(), statusCode: 429)
        }
        #expect(throws: IdentificationError.busy) {
            try ClaudeIdentifier.parseResponse(data: Data(), statusCode: 529)
        }
    }
}
