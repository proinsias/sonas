import SwiftUI

// MARK: - PhotoGalleryView (T066)
// TimelineView carousel with 15-second auto-advance at 60fps.
// Tap → full-screen modal sheet with swipe-through navigation.

struct PhotoGalleryView: View {

    @State var viewModel: PhotoViewModel
    @State private var selectedIndex: Int = 0
    @State private var isFullScreen: Bool = false

    var body: some View {
        PanelView(title: "Photos", icon: Icon.photos) {
            content
        }
        .task { await viewModel.load() }
        .sheet(isPresented: $isFullScreen) {
            FullScreenPhotoView(
                photos: viewModel.photos,
                selectedIndex: $selectedIndex,
                viewModel: viewModel
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            LoadingStateView(rows: 1, showsLargeBlock: true)
                .frame(height: 200)
        } else if let error = viewModel.error {
            ErrorStateView(error: error) { Swift.Task { await viewModel.reload() } }
        } else if viewModel.photos.isEmpty && viewModel.selectedAlbumName == nil {
            selectAlbumPrompt
        } else if viewModel.photos.isEmpty {
            emptyAlbumPrompt
        } else {
            carousel
        }
    }

    // MARK: - Carousel

    private var carousel: some View {
        TimelineView(.periodic(from: .now, by: 15)) { _ in
            // Auto-advance index on each timeline tick
            carouselPhoto(for: selectedIndex)
                .onAppear { advanceIndex() }
        }
        .onTapGesture { isFullScreen = true }
        .accessibilityInfo("Photo gallery", hint: "Tap to view full screen")
    }

    private func carouselPhoto(for index: Int) -> some View {
        let photo = viewModel.photos[index]
        return AsyncPhotoView(photo: photo, viewModel: viewModel)
            .frame(height: 200)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func advanceIndex() {
        guard !viewModel.photos.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % viewModel.photos.count
    }

    // MARK: - Prompts

    private var selectAlbumPrompt: some View {
        VStack(spacing: 8) {
            Image(systemName: Icon.photos)
                .font(.title2)
                .foregroundStyle(Color.secondaryLabel)
                .accessibilityHidden(true)
            Text("Select a shared album")
                .font(.caption)
                .foregroundStyle(Color.secondaryLabel)
                .multilineTextAlignment(.center)
            Text("Choose an album in Settings.")
                .font(.caption2)
                .foregroundStyle(Color.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var emptyAlbumPrompt: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.badge.plus")
                .font(.title2)
                .foregroundStyle(Color.secondaryLabel)
                .accessibilityHidden(true)
            Text("Add photos to your shared album")
                .font(.caption)
                .foregroundStyle(Color.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - AsyncPhotoView

private struct AsyncPhotoView: View {
    let photo: Photo
    @State var viewModel: PhotoViewModel
    @State private var imageData: Data?

    var body: some View {
        Group {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.secondaryLabel.opacity(0.2)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(Color.secondaryLabel)
                    }
            }
        }
        .task {
            imageData = try? await viewModel.loadThumbnail(for: photo)
        }
    }
}

// MARK: - FullScreenPhotoView

private struct FullScreenPhotoView: View {
    let photos: [Photo]
    @Binding var selectedIndex: Int
    @State var viewModel: PhotoViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedIndex) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    AsyncPhotoView(photo: photo, viewModel: viewModel)
                        .tag(index)
                        .accessibilityLabel("Photo \(index + 1) of \(photos.count)")
                }
            }
            .tabViewStyle(.page)
            .background(Color.black)
            .navigationTitle("Photo \(selectedIndex + 1) of \(photos.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}
