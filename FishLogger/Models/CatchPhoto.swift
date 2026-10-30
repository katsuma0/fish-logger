import Foundation
import SwiftData
import UIKit

@Model
final class CatchPhoto {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    /// Stored outside the database file so the store stays small and fast.
    @Attribute(.externalStorage) var imageData: Data = Data()
    /// Small JPEG for lists and grids, so scrolling never decodes full photos.
    @Attribute(.externalStorage) var thumbnailData: Data?
    var fishCatch: FishCatch?

    init(imageData: Data, thumbnailData: Data?, createdAt: Date = .now) {
        self.id = UUID()
        self.createdAt = createdAt
        self.imageData = imageData
        self.thumbnailData = thumbnailData
    }
}

extension CatchPhoto {
    /// Builds a photo with storage-sized and thumbnail JPEGs from any image.
    convenience init?(image: UIImage, createdAt: Date = .now) {
        guard let full = ImageProcessing.storageJPEG(from: image) else { return nil }
        self.init(imageData: full, thumbnailData: ImageProcessing.thumbnailJPEG(from: image), createdAt: createdAt)
    }

    var thumbnailImage: UIImage? {
        if let thumbnailData, let image = UIImage(data: thumbnailData) { return image }
        return UIImage(data: imageData)
    }

    var fullImage: UIImage? { UIImage(data: imageData) }
}
