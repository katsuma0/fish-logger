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
    /// True while the shown page is zoomed in. A side drag then pans the photo instead of paging.
    @State private var isZoomed = false

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
                            },
                            onZoomChange: { zoomed in
                                if isZoomed != zoomed { isZoomed = zoomed }
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: indexDisplayMode))
                // Backs up the page's own pan gesture: a zoomed photo never flips to the next one.
                .scrollDisabled(isZoomed)
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
/// swiping never decode on the main thread. Zoomed in, a drag moves the photo around the way it
/// does in Photos, so the tail spot or fin markings at the edge can be brought into view.
private struct CatchPhotoViewerPage: View {
    let photo: CatchPhoto
    let position: Int
    let total: Int
    /// Hands the bytes to the viewer for sharing.
    let onLoad: (Data) -> Void
    /// Tells the viewer when the page zooms in or back out, so it can stop paging meanwhile.
    let onZoomChange: (Bool) -> Void

    @State private var image: UIImage?
    @State private var data: Data?
    @State private var didFail = false
    @State private var scale: CGFloat = 1
    @State private var settledScale: CGFloat = 1
    /// Where a zoomed photo sat when the last drag ended.
    @State private var settledOffset: CGSize = .zero
    /// The drag in progress. Goes back to zero by itself if the drag is cancelled.
    @GestureState private var dragTranslation: CGSize = .zero

    var body: some View {
        Group {
            if let loaded = image {
                GeometryReader { geo in
                    let container = geo.size
                    let imageSize = loaded.size
                    // Panning only exists while zoomed in, so at full size the side swipe still pages.
                    let panMask: GestureMask = scale > 1 ? .all : .subviews
                    let shownOffset = clamped(
                        CGSize(
                            width: settledOffset.width + dragTranslation.width,
                            height: settledOffset.height + dragTranslation.height
                        ),
                        container: container,
                        imageSize: imageSize
                    )
                    Image(uiImage: loaded)
                        .resizable()
                        .scaledToFit()
                        // A photo, so Smart Invert leaves its colours alone.
                        .accessibilityIgnoresInvertColors()
                        .scaleEffect(scale)
                        .offset(shownOffset)
                        .frame(width: container.width, height: container.height)
                        .contentShape(Rectangle())
                        .gesture(panGesture(container: container, imageSize: imageSize), including: panMask)
                        .simultaneousGesture(zoomGesture(container: container, imageSize: imageSize))
                        .onTapGesture(count: 2) { toggleZoom() }
                        .accessibilityLabel(spokenLabel)
                        .accessibilityAddTraits(.isImage)
                }
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
        .onChange(of: scale > 1) { _, zoomed in
            onZoomChange(zoomed)
        }
        .onDisappear {
            scale = 1
            settledScale = 1
            settledOffset = .zero
            onZoomChange(false)
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

    /// While pinching, the shown offset is clamped to the new size in `body`. When the pinch ends,
    /// that clamp is kept, and back at full size the photo returns to the centre.
    private func zoomGesture(container: CGSize, imageSize: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(settledScale * value.magnification, 1), 4)
            }
            .onEnded { _ in
                settledScale = scale
                settledOffset = scale > 1 ? clamped(settledOffset, container: container, imageSize: imageSize) : .zero
            }
    }

    private func panGesture(container: CGSize, imageSize: CGSize) -> some Gesture {
        DragGesture()
            .updating($dragTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let moved = CGSize(
                    width: settledOffset.width + value.translation.width,
                    height: settledOffset.height + value.translation.height
                )
                settledOffset = clamped(moved, container: container, imageSize: imageSize)
            }
    }

    /// Keeps the zoomed photo's edges from coming inside the screen's edges, like Photos. At full
    /// size the photo fits, so there is nothing to move and the offset is zero.
    private func clamped(_ proposed: CGSize, container: CGSize, imageSize: CGSize) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0, container.width > 0, container.height > 0 else { return .zero }
        let fit = min(container.width / imageSize.width, container.height / imageSize.height)
        let maxX = max((imageSize.width * fit * scale - container.width) / 2, 0)
        let maxY = max((imageSize.height * fit * scale - container.height) / 2, 0)
        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }

    private func toggleZoom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            scale = scale > 1 ? 1 : 2
            settledOffset = .zero
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
