import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// Photo grid and add buttons for the catch editor. Presentations hang off single rows, because
/// modifiers on a whole Section get copied onto every row.
struct CatchEditorPhotosSection: View {
    let fishCatch: FishCatch

    @Environment(AppSettings.self) private var settings
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isLoading = false
    @State private var showingCamera = false
    @State private var viewerRequest: CatchPhotoViewerRequest?

    init(fishCatch: FishCatch) {
        self.fishCatch = fishCatch
    }

    private var thumbnailSize: CGFloat { 80 * settings.buttonSize.scale }

    var body: some View {
        let photos = fishCatch.sortedPhotos
        Section {
            if !photos.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: thumbnailSize), spacing: 8)], spacing: 8) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        thumbnailButton(photo: photo, index: index, total: photos.count)
                    }
                }
                .padding(.vertical, 4)
                .fullScreenCover(item: $viewerRequest) { request in
                    PhotoViewer(photos: fishCatch.sortedPhotos, startIndex: request.index)
                }
            }

            PhotosPicker(selection: $pickerItems, maxSelectionCount: 10, matching: .images) {
                Label("Add photos", systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .disabled(isLoading)
            .onChange(of: pickerItems) { _, items in
                guard !items.isEmpty else { return }
                Task { await addPicked(items) }
            }

            if CameraPicker.isAvailable {
                Button {
                    showingCamera = true
                } label: {
                    Label("Take photo", systemImage: "camera")
                        .frame(maxWidth: .infinity, minHeight: settings.buttonSize.minTapSize, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .disabled(isLoading)
                .fullScreenCover(isPresented: $showingCamera) {
                    CameraPicker(onCapture: { image in
                        addCaptured(image)
                    })
                    .ignoresSafeArea()
                }
            }

            if isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Adding photos")
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: settings.buttonSize.minTapSize)
                .accessibilityElement(children: .combine)
            }
        } header: {
            Text("Photos")
        }
    }

    private func thumbnailButton(photo: CatchPhoto, index: Int, total: Int) -> some View {
        Button {
            viewerRequest = CatchPhotoViewerRequest(index: index)
        } label: {
            PhotoThumbnail(photo: photo, size: thumbnailSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Photo \(index + 1) of \(total)")
        .accessibilityHint("Opens the photo full screen")
        .accessibilityAction(named: "Delete photo") {
            deletePhoto(photo)
        }
        .contextMenu {
            Button(role: .destructive) {
                deletePhoto(photo)
            } label: {
                Label("Delete photo", systemImage: "trash")
            }
        }
    }

    private func addPicked(_ items: [PhotosPickerItem]) async {
        isLoading = true
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { continue }
            // Loading can take a while; the catch may have been deleted in the meantime.
            guard let context = fishCatch.catchEditorLiveContext else { break }
            CatchLogger.addPhoto(image, to: fishCatch, in: context)
        }
        isLoading = false
        pickerItems = []
    }

    private func addCaptured(_ image: UIImage) {
        guard let context = fishCatch.catchEditorLiveContext else { return }
        CatchLogger.addPhoto(image, to: fishCatch, in: context)
    }

    private func deletePhoto(_ photo: CatchPhoto) {
        guard let context = fishCatch.catchEditorLiveContext else { return }
        // Drop it from the relationship first so the grid never shows a deleted photo.
        let photoID = photo.id
        fishCatch.photos.removeAll { $0.id == photoID }
        context.delete(photo)
        CatchLogger.save(context)
    }
}

private struct CatchPhotoViewerRequest: Identifiable {
    let index: Int
    var id: Int { index }
}
