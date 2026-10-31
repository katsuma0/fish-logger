import ImageIO
import UIKit

/// A photo picked or taken in Photo ID: the original for identifying and saving, and a small,
/// already decoded copy for the screen.
struct IdentifyPreparedPhoto {
    let full: UIImage
    let display: UIImage
}

/// Display copies for the Photo ID screens. A camera photo is about 12 MP, and drawing it in a
/// 280 pt preview decodes all of it on the main thread the first time it shows. Everything here
/// does that work in the background instead.
enum IdentifyDisplayImage {
    /// Long edge in pixels. Sharp at 280 pt on a 3x screen, a fraction of the original's memory.
    static let maxPixelSize: CGFloat = 1200

    /// Small decoded copy of a camera image. Falls back to a plain redraw when UIKit cannot
    /// prepare a thumbnail, for example for an image with no bitmap behind it.
    static func make(from image: UIImage) async -> UIImage {
        let target = targetSize(for: image.size)
        if let prepared = await image.byPreparingThumbnail(ofSize: target) {
            return prepared
        }
        let maxSize = maxPixelSize
        let task = Task.detached(priority: .userInitiated) { () -> UIImage in
            ImageProcessing.resized(image, maxDimension: maxSize)
        }
        return await task.value
    }

    /// Both images from photo library file data. ImageIO downsamples while it decodes, so the
    /// display copy never needs the full bitmap. Nil when the data is not an image.
    static func prepare(fileData data: Data) async -> IdentifyPreparedPhoto? {
        let maxSize = maxPixelSize
        let task = Task.detached(priority: .userInitiated) { () -> IdentifyPreparedPhoto? in
            guard let full = UIImage(data: data),
                  let source = CGImageSourceCreateWithData(data as CFData, nil)
            else { return nil }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: maxSize
            ]
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                return nil
            }
            // The transform option already turned the pixels upright, so this copy is .up at scale 1.
            return IdentifyPreparedPhoto(full: full, display: UIImage(cgImage: cgImage))
        }
        return await task.value
    }

    /// Same aspect ratio, long edge at most `maxPixelSize`. Never upscales.
    static func targetSize(for size: CGSize) -> CGSize {
        let longEdge = max(size.width, size.height)
        guard longEdge > 0 else { return CGSize(width: maxPixelSize, height: maxPixelSize) }
        let factor = min(1, maxPixelSize / longEdge)
        return CGSize(width: (size.width * factor).rounded(), height: (size.height * factor).rounded())
    }
}
