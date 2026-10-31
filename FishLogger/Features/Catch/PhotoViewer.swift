import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Full-screen photo pager. Present with `.fullScreenCover`.
struct PhotoViewer: View {
    let photos: [CatchPhoto]
    let startIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var selection: Int

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
                    ForEach(photos.indices, id: \.self) { index in
                        CatchPhotoViewerPage(photo: photos[index], position: index + 1, total: photos.count)
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
                ShareLink(
                    item: CatchPhotoShareItem(data: photo.imageData),
                    preview: SharePreview("Catch photo", image: previewImage(for: photo))
                ) {
                    controlIcon("square.and.arrow.up.circle.fill")
                }
                .accessibilityLabel("Share photo")
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
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }

    private func previewImage(for photo: CatchPhoto) -> Image {
        if let thumbnail = photo.thumbnailImage {
            return Image(uiImage: thumbnail)
        }
        return Image(systemName: "photo")
    }
}

/// One page. Decodes its photo once and keeps it, so pinching does not decode on every frame.
private struct CatchPhotoViewerPage: View {
    let photo: CatchPhoto
    let position: Int
    let total: Int

    @State private var image: UIImage?
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
        .task(id: photo.id) {
            guard image == nil else { return }
            let decoded = photo.fullImage
            image = decoded
            didFail = decoded == nil
        }
        .onDisappear {
            scale = 1
            settledScale = 1
        }
    }

    private var spokenLabel: String {
        total > 1 ? "Photo \(position) of \(total)" : "Photo"
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(settledScale * value, 1), 4)
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
