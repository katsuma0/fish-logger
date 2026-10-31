import CoreML
import Foundation
import ImageIO
import UIKit
import Vision

/// Offline photo ID with a Create ML image classifier, when one is bundled as FishClassifier.
/// The app ships without it, so everything here checks `isAvailable` first.
enum OnDeviceIdentifier {
    static let modelName = "FishClassifier"

    static var modelURL: URL? {
        Bundle.main.url(forResource: modelName, withExtension: "mlmodelc")
    }

    static var isAvailable: Bool { modelURL != nil }

    static func identify(image: UIImage) async throws -> IdentificationResult {
        guard let url = modelURL else { throw IdentificationError.modelUnavailable }

        let cgImage: CGImage
        let orientation: CGImagePropertyOrientation
        if let original = image.cgImage {
            cgImage = original
            orientation = CGImagePropertyOrientation(identifyImageOrientation: image.imageOrientation)
        } else if let redrawn = ImageProcessing.resized(image, maxDimension: 1024).cgImage {
            // Redrawing bakes the orientation in.
            cgImage = redrawn
            orientation = .up
        } else {
            throw IdentificationError.imageUnreadable
        }

        // Vision blocks while it runs, so keep it off the main thread.
        let task = Task.detached(priority: .userInitiated) { () throws -> IdentificationResult in
            try OnDeviceIdentifier.classify(cgImage: cgImage, orientation: orientation, modelURL: url)
        }
        return try await task.value
    }

    /// Maps a classifier label to a catalog id. Labels can be ids, common names, or other names,
    /// in any case, with spaces or hyphens.
    static func speciesID(forLabel label: String) -> String? {
        let key = normalised(label)
        guard !key.isEmpty else { return nil }
        if key == SpeciesCatalog.unknownID { return SpeciesCatalog.unknownID }
        return labelLookup[key]
    }

    static func normalised(_ label: String) -> String {
        label
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }

    /// Ids win over common names, and common names win over nicknames, because nicknames like
    /// "pickerel" are shared between species.
    private static let labelLookup: [String: String] = {
        var map: [String: String] = [:]
        for species in SpeciesCatalog.all {
            for name in species.otherNames {
                map[OnDeviceIdentifier.normalised(name)] = species.id
            }
        }
        for species in SpeciesCatalog.all {
            map[OnDeviceIdentifier.normalised(species.scientificName)] = species.id
            map[OnDeviceIdentifier.normalised(species.commonName)] = species.id
        }
        for species in SpeciesCatalog.all {
            map[species.id] = species.id
        }
        map.removeValue(forKey: "")
        return map
    }()

    private static func classify(
        cgImage: CGImage,
        orientation: CGImagePropertyOrientation,
        modelURL: URL
    ) throws -> IdentificationResult {
        // Loaded per photo rather than cached: one ID per photo, and no shared state across threads.
        let model = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .centerCrop
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        try handler.perform([request])

        let observations: [VNClassificationObservation] = (request.results ?? []).compactMap { observation in
            observation as? VNClassificationObservation
        }
        let ranked = observations.sorted { $0.confidence > $1.confidence }

        var seen = Set<String>()
        var candidates: [IdentificationCandidate] = []
        for observation in ranked {
            guard let id = speciesID(forLabel: observation.identifier) else { continue }
            guard seen.insert(id).inserted else { continue }
            let confidence = min(max(Double(observation.confidence), 0), 1)
            candidates.append(IdentificationCandidate(speciesID: id, confidence: confidence))
            if candidates.count == 3 { break }
        }
        return IdentificationResult(isFish: !candidates.isEmpty, candidates: candidates, source: .onDevice)
    }
}

extension CGImagePropertyOrientation {
    /// Vision needs the EXIF-style orientation, not UIKit's.
    init(identifyImageOrientation orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
