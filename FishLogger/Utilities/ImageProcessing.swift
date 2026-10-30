import UIKit

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
