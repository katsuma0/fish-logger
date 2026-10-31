import SwiftUI
import UIKit

/// Square, rounded photo for lists and grids. Uses the small stored thumbnail, never the full photo.
/// Decoding happens off the main thread, so opening a trip full of photos never stalls the push.
struct PhotoThumbnail: View {
    let photo: CatchPhoto
    let size: CGFloat

    /// Held here as well as in the cache, so a cache eviction never turns a visible thumbnail grey.
    @State private var loaded: LoadedThumbnail?

    init(photo: CatchPhoto, size: CGFloat) {
        self.photo = photo
        self.size = size
    }

    var body: some View {
        let id = photo.id
        // A cache hit shows on the first frame, so rows scrolled back into view never flash grey.
        let image = loaded?.id == id ? loaded?.image : CatchPhotoThumbnailCache.cachedImage(for: id)
        content(image)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Photo")
            .accessibilityAddTraits(.isImage)
            .task(id: id) { await load(id) }
    }

    @ViewBuilder
    private func content(_ image: UIImage?) -> some View {
        if let image {
            // A photo, so Smart Invert leaves its colours alone. The grey placeholder still inverts.
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .accessibilityIgnoresInvertColors()
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

    private func load(_ id: UUID) async {
        if loaded?.id == id { return }
        guard let image = await CatchPhotoThumbnailCache.thumbnail(for: photo) else { return }
        guard !Task.isCancelled else { return }
        loaded = LoadedThumbnail(id: id, image: image)
    }
}

/// The photo id travels with the image, so a reused view never shows the previous photo.
private struct LoadedThumbnail {
    let id: UUID
    let image: UIImage
}

/// Decoded thumbnails by photo id, shared by rows, grids, and the photo viewer's share preview.
/// Small on purpose: a 320 px thumbnail is about 400 KB once decoded.
enum CatchPhotoThumbnailCache {
    private static let images: NSCache<NSUUID, UIImage> = {
        let cache = NSCache<NSUUID, UIImage>()
        cache.countLimit = 120
        cache.totalCostLimit = 48 * 1024 * 1024
        return cache
    }()

    /// A lookup only. Never decodes, so it is safe to call from `body`.
    static func cachedImage(for id: UUID) -> UIImage? {
        images.object(forKey: id as NSUUID)
    }

    static func store(_ image: UIImage, for id: UUID) {
        let pixels = image.size.width * image.scale * image.size.height * image.scale
        images.setObject(image, forKey: id as NSUUID, cost: Int(pixels) * 4)
    }

    /// Reads the bytes on the main actor, where the model lives, then decodes in the background and
    /// caches the result. Nil when the photo is gone or cannot be decoded.
    @MainActor
    static func thumbnail(for photo: CatchPhoto) async -> UIImage? {
        // Reading attributes of a deleted photo can crash, so check before touching it.
        guard !photo.isDeleted, photo.modelContext != nil else { return nil }
        let id = photo.id
        if let cached = cachedImage(for: id) { return cached }

        let decoded: UIImage?
        if let data = photo.thumbnailData {
            decoded = await Task.detached(priority: .userInitiated) {
                UIImage(data: data)?.preparingForDisplay()
            }.value
        } else {
            // Older photos have no thumbnail. Shrink the full photo once and keep only the small copy.
            let data = photo.imageData
            let maxDimension = ImageProcessing.thumbnailMaxDimension
            decoded = await Task.detached(priority: .userInitiated) {
                CatchPhotoThumbnailCache.downsized(data, maxDimension: maxDimension)
            }.value
        }
        guard let decoded else { return nil }
        store(decoded, for: id)
        return decoded
    }

    /// Thread safe: UIImage decoding and `preparingThumbnail(of:)` work on any thread.
    private static func downsized(_ data: Data, maxDimension: CGFloat) -> UIImage? {
        guard let full = UIImage(data: data) else { return nil }
        let longEdge = max(full.size.width, full.size.height)
        guard longEdge > 0 else { return nil }
        let factor = min(1, maxDimension / longEdge)
        let target = CGSize(
            width: max(1, (full.size.width * factor).rounded()),
            height: max(1, (full.size.height * factor).rounded())
        )
        return full.preparingThumbnail(of: target)
    }
}
