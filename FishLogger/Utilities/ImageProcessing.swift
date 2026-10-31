import ImageIO
import UIKit

/// Storage-sized and thumbnail JPEGs for one catch photo, ready to become a `CatchPhoto`.
struct EncodedPhoto {
    let imageData: Data
    let thumbnailData: Data?
}

/// Everything here is safe to call off the main thread: `UIGraphicsImageRenderer`, `jpegData` and
/// ImageIO are all thread safe.
enum ImageProcessing {
    /// Long edge for stored photos. Plenty for a phone screen, about 500 KB per photo.
    static let storageMaxDimension: CGFloat = 2048
    static let thumbnailMaxDimension: CGFloat = 320
    /// Long edge sent to Claude. Larger images get downscaled server side anyway, so this saves upload time.
    static let identificationMaxDimension: CGFloat = 1568

    static func storageJPEG(from image: UIImage) -> Data? {
        resized(image, maxDimension: storageMaxDimension).jpegData(compressionQuality: 0.8)
    }

    static func thumbnailJPEG(from image: UIImage) -> Data? {
        resized(image, maxDimension: thumbnailMaxDimension).jpegData(compressionQuality: 0.7)
    }

    static func identificationJPEG(from image: UIImage) -> Data? {
        resized(image, maxDimension: identificationMaxDimension).jpegData(compressionQuality: 0.8)
    }

    /// Both JPEGs for a stored photo. The thumbnail is drawn from the 2048 px copy, not the original,
    /// so a 12 MP camera photo is decoded and redrawn once instead of twice.
    static func encodedPhoto(from image: UIImage) -> EncodedPhoto? {
        let stored = resized(image, maxDimension: storageMaxDimension)
        guard let full = stored.jpegData(compressionQuality: 0.8) else { return nil }
        return EncodedPhoto(imageData: full, thumbnailData: thumbnailJPEG(from: stored))
    }

    /// Both JPEGs from photo library file data (HEIC, JPEG, PNG). ImageIO downsamples while it
    /// decodes, so the full 12 MP bitmap never sits in memory.
    static func encodedPhoto(fromFileData data: Data) -> EncodedPhoto? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: storageMaxDimension
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        // The transform option already baked in orientation, so this image is upright at scale 1.
        let stored = UIImage(cgImage: cgImage)
        guard let full = stored.jpegData(compressionQuality: 0.8) else { return nil }
        return EncodedPhoto(imageData: full, thumbnailData: thumbnailJPEG(from: stored))
    }

    /// Redraws at scale 1 so the pixel size is predictable, and bakes in orientation.
    static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longEdge = max(size.width, size.height)
        let factor = longEdge > maxDimension ? maxDimension / longEdge : 1
        let target = CGSize(width: (size.width * factor).rounded(), height: (size.height * factor).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

/// Encodes catch photos off the main thread, one at a time. One at a time keeps memory flat when
/// ten library photos arrive together, and an actor keeps the work off the main thread.
actor PhotoEncoder {
    static let shared = PhotoEncoder()

    func encode(_ image: UIImage) -> EncodedPhoto? {
        ImageProcessing.encodedPhoto(from: image)
    }

    func encode(fileData data: Data) -> EncodedPhoto? {
        ImageProcessing.encodedPhoto(fromFileData: data)
    }
}
