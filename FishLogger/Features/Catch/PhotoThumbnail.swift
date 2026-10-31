import SwiftUI
import UIKit

/// Square, rounded photo for lists and grids. Uses the small stored thumbnail, never the full photo.
struct PhotoThumbnail: View {
    let photo: CatchPhoto
    let size: CGFloat

    init(photo: CatchPhoto, size: CGFloat) {
        self.photo = photo
        self.size = size
    }

    var body: some View {
        content
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Photo")
            .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder
    private var content: some View {
        if let image = CatchPhotoThumbnailCache.image(for: photo) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
        } else {
            Rectangle()
                .fill(Color(uiColor: .systemGray5))
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: size * 0.36))
                        .foregroundStyle(.secondary)
                )
        }
    }
}

/// Body runs often while a list scrolls, so decoded thumbnails are kept instead of decoding JPEG each time.
private enum CatchPhotoThumbnailCache {
    static let images: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 300
        return cache
    }()

    static func image(for photo: CatchPhoto) -> UIImage? {
        let key = photo.id.uuidString as NSString
        if let cached = images.object(forKey: key) { return cached }
        guard let decoded = photo.thumbnailImage else { return nil }
        // Older photos without a thumbnail fall back to the full image; shrink it so the cache stays small.
        let image = photo.thumbnailData == nil
            ? ImageProcessing.resized(decoded, maxDimension: ImageProcessing.thumbnailMaxDimension)
            : decoded
        images.setObject(image, forKey: key)
        return image
    }
}
