import CoreLocation
import Foundation
import SwiftData

/// One log entry. Usually one fish; `count` is there for a school of perch you do not want to tap 14 times.
@Model
final class FishCatch {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    /// Matches `Species.id` in `SpeciesCatalog`, or `SpeciesCatalog.unknownID`.
    var speciesID: String = SpeciesCatalog.unknownID
    /// Free text name when the fish is not in the catalog.
    var customSpeciesName: String?
    var count: Int = 1
    var lengthCm: Double?
    var weightKg: Double?
    var sizeClassRaw: String?
    var released: Bool = true
    var lure: String = ""
    var depthM: Double?
    var waterTempC: Double?
    /// Sea-level pressure snapshot from the barometer when the fish was logged.
    var pressureHPa: Double?
    var latitude: Double?
    var longitude: Double?
    var notes: String = ""
    var identifiedByRaw: String?
    var trip: Trip?

    @Relationship(deleteRule: .cascade, inverse: \CatchPhoto.fishCatch)
    var photos: [CatchPhoto] = []

    init(
        speciesID: String,
        timestamp: Date = .now,
        count: Int = 1,
        sizeClass: SizeClass? = nil,
        lengthCm: Double? = nil,
        weightKg: Double? = nil
    ) {
        self.id = UUID()
        self.speciesID = speciesID
        self.timestamp = timestamp
        self.count = max(1, count)
        self.sizeClassRaw = sizeClass?.rawValue
        self.lengthCm = lengthCm
        self.weightKg = weightKg
    }
}

extension FishCatch {
    var species: Species? { SpeciesCatalog.species(id: speciesID) }

    var speciesName: String {
        if let custom = customSpeciesName?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
            return custom
        }
        return species?.commonName ?? "Unknown fish"
    }

    var sizeClass: SizeClass? {
        get { sizeClassRaw.flatMap(SizeClass.init(rawValue:)) }
        set { sizeClassRaw = newValue?.rawValue }
    }

    var identifiedBy: IdentificationSource? {
        get { identifiedByRaw.flatMap(IdentificationSource.init(rawValue:)) }
        set { identifiedByRaw = newValue?.rawValue }
    }

    /// The size class you picked, or one worked out from the measured length.
    var effectiveSizeClass: SizeClass? {
        if let sizeClass { return sizeClass }
        guard let lengthCm, let species else { return nil }
        return species.sizeClass(forLengthCm: lengthCm)
    }

    /// Measured length, or a typical length for the size class. Good enough for averages, not for records.
    var estimatedLengthCm: Double? {
        if let lengthCm { return lengthCm }
        guard let sizeClass, let species else { return nil }
        return species.representativeLengthCm(for: sizeClass)
    }

    /// Weighed value, or the species length-weight curve applied to the (estimated) length.
    var estimatedWeightKg: Double? {
        if let weightKg { return weightKg }
        guard let length = estimatedLengthCm, let species else { return nil }
        return species.estimatedWeightKg(lengthCm: length)
    }

    var hasMeasurement: Bool { lengthCm != nil || weightKg != nil }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Photos oldest first, so the first photo stays the cover.
    var sortedPhotos: [CatchPhoto] { photos.sorted { $0.createdAt < $1.createdAt } }
}
