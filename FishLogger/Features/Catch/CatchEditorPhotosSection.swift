import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// Photo grid and add buttons for the catch editor. Sits right under the species, so Take photo is
/// on screen when the editor opens. Presentations hang off single rows, because modifiers on a whole
/// Section get copied onto every row.
struct CatchEditorPhotosSection: View {
    let fishCatch: FishCatch

    @Environment(AppSettings.self) private var settings
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isLoading = false
    @State private var showingCamera = false
    @State private var viewerRequest: CatchPhotoViewerRequest?
    @State private var photoPendingDelete: CatchPhoto?

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
                .confirmationDialog(
                    "Delete this photo?",
                    isPresented: deleteDialogBinding,
                    titleVisibility: .visible,
                    presenting: photoPendingDelete
                ) { photo in
                    Button("Delete photo", role: .destructive) { deletePhoto(photo) }
                    Button("Cancel", role: .cancel) {}
                } message: { _ in
                    Text("This cannot be undone.")
                }
            }

            // Camera first: on the water, a fresh photo is the common case.
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

    private var deleteDialogBinding: Binding<Bool> {
        Binding(
            get: { photoPendingDelete != nil },
            set: { if !$0 { photoPendingDelete = nil } }
        )
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
            photoPendingDelete = photo
        }
        .contextMenu {
            Button(role: .destructive) {
                photoPendingDelete = photo
            } label: {
                Label("Delete photo", systemImage: "trash")
            }
        }
    }

    /// Library files go to the encoder as data, which downsamples while it decodes, so a big HEIC
    /// never sits in memory or decodes on the main thread.
    private func addPicked(_ items: [PhotosPickerItem]) async {
        isLoading = true
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            // Loading can take a while; the catch may have been deleted in the meantime.
            guard let context = fishCatch.catchEditorLiveContext else { break }
            await CatchLogger.attachPhoto(data: data, to: fishCatch, in: context)
        }
        isLoading = false
        pickerItems = []
    }

    private func addCaptured(_ image: UIImage) {
        guard let context = fishCatch.catchEditorLiveContext else { return }
        isLoading = true
        Task {
            await CatchLogger.attachPhoto(image, to: fishCatch, in: context)
            isLoading = false
        }
    }

    private func deletePhoto(_ photo: CatchPhoto) {
        photoPendingDelete = nil
        guard let context = fishCatch.catchEditorLiveContext, !photo.isDeleted else { return }
        // Drop it from the relationship first so the grid never shows a deleted photo.
        let photoID = photo.id
        fishCatch.photos.removeAll { $0.id == photoID }
        context.delete(photo)
        CatchLogger.save(context)
        Haptics.warning()
    }
}

private struct CatchPhotoViewerRequest: Identifiable {
    let index: Int
    var id: Int { index }
}
