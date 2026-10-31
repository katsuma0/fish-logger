import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Full-screen photo pager. Present with `.fullScreenCover`.
struct PhotoViewer: View {
    let photos: [CatchPhoto]
    let startIndex: Int

    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Int
    /// JPEG bytes each page already read, by photo id. Share uses these, so swiping never reads a
    /// photo file on the main thread just to build the share button.
    @State private var loadedData: [UUID: Data] = [:]

    init(photos: [CatchPhoto], startIndex: Int) {
        self.photos = photos
        self.startIndex = startIndex
        let lastIndex = max(photos.count - 1, 0)
        _selection = State(initialValue: min(max(startIndex, 0), lastIndex))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .ignoresSafeArea()

            if photos.isEmpty {
                Text("No photos.")
                    .font(.headline)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView(selection: $selection) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        let photoID = photo.id
                        CatchPhotoViewerPage(
                            photo: photo,
                            position: index + 1,
                            total: photos.count,
                            onLoad: { data in
                                if loadedData[photoID] == nil { loadedData[photoID] = data }
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: indexDisplayMode))
            }

            controls
        }
        .statusBarHidden()
        .accessibilityAction(.escape) { dismiss() }
    }

    private var indexDisplayMode: PageTabViewStyle.IndexDisplayMode {
        photos.count > 1 ? .always : .never
    }

    private var currentPhoto: CatchPhoto? {
        photos.indices.contains(selection) ? photos[selection] : nil
    }

    private var controls: some View {
        HStack(spacing: 12) {
            if let photo = currentPhoto {
                let photoID = photo.id
                if let data = loadedData[photoID] {
                    ShareLink(
                        item: CatchPhotoShareItem(data: data),
                        preview: SharePreview("Catch photo", image: previewImage(for: photoID))
                    ) {
                        controlIcon("square.and.arrow.up.circle.fill")
                    }
                    .accessibilityLabel("Share photo")
                } else {
                    // Holds the spot until the page has read its photo, so Close never jumps.
                    controlIcon("square.and.arrow.up.circle.fill")
                        .opacity(0.4)
                        .accessibilityHidden(true)
                }
            }

            Button {
                dismiss()
            } label: {
                controlIcon("xmark.circle.fill")
            }
            .accessibilityLabel("Close")
        }
        .padding()
    }

    private func controlIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.title)
            .symbolRenderingMode(.palette)
            .foregroundStyle(Color.white, Color.black.opacity(0.5))
            .frame(minWidth: settings.buttonSize.minTapSize, minHeight: settings.buttonSize.minTapSize)
            .contentShape(Rectangle())
    }

    /// Cached thumbnail only. Decoding here would run on every swipe.
    private func previewImage(for photoID: UUID) -> Image {
        if let thumbnail = CatchPhotoThumbnailCache.cachedImage(for: photoID) {
            return Image(uiImage: thumbnail)
        }
        return Image(systemName: "photo")
    }
}

/// One page. Reads its photo once, decodes it off the main thread, and keeps it, so pinching and
/// swiping never decode on the main thread.
private struct CatchPhotoViewerPage: View {
    let photo: CatchPhoto
    let position: Int
    let total: Int
    /// Hands the bytes to the viewer for sharing.
    let onLoad: (Data) -> Void

    @State private var image: UIImage?
    @State private var data: Data?
    @State private var didFail = false
    @State private var scale: CGFloat = 1
    @State private var settledScale: CGFloat = 1

    var body: some View {
        Group {
            if let loaded = image {
                Image(uiImage: loaded)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(zoomGesture)
                    .onTapGesture(count: 2) { toggleZoom() }
                    .accessibilityLabel(spokenLabel)
                    .accessibilityAddTraits(.isImage)
            } else if didFail {
                Label("This photo could not be opened.", systemImage: "photo")
                    .font(.headline)
                    .foregroundStyle(Color.white)
            } else {
                ProgressView()
                    .tint(Color.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: photo.id) { await load() }
        .onDisappear {
            scale = 1
            settledScale = 1
        }
    }

    private func load() async {
        if let data, image != nil || didFail {
            // Already read; the viewer may have been rebuilt, so hand the bytes over again.
            onLoad(data)
            return
        }
        // A photo deleted while the viewer was open must not be read.
        guard !photo.isDeleted, photo.modelContext != nil else {
            didFail = true
            return
        }
        let bytes = data ?? photo.imageData
        data = bytes
        onLoad(bytes)
        let decoded = await Task.detached(priority: .userInitiated) {
            UIImage(data: bytes)?.preparingForDisplay()
        }.value
        guard !Task.isCancelled else { return }
        image = decoded
        didFail = decoded == nil
    }

    private var spokenLabel: String {
        total > 1 ? "Photo \(position) of \(total)" : "Photo"
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(settledScale * value.magnification, 1), 4)
            }
            .onEnded { _ in
                settledScale = scale
            }
    }

    private func toggleZoom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            scale = scale > 1 ? 1 : 2
        }
        settledScale = scale
    }
}

/// Shares the stored JPEG as a real image file, so Save Image and Messages both work.
private struct CatchPhotoShareItem: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .jpeg) { (item: CatchPhotoShareItem) in
            item.data
        }
    }
}
