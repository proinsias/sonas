import Photos
import SwiftUI

// MARK: - AlbumPickerView

struct AlbumItem: Identifiable {
    let id: String
    let name: String
    let count: Int
}

struct AlbumPickerView: View {
    var photoVM: PhotoViewModel
    @Binding var isPresented: Bool
    @State private var albums: [AlbumItem] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading albums…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if albums.isEmpty {
                    ContentUnavailableView(
                        "No Albums Found",
                        systemImage: "photo.on.rectangle",
                        description: Text("Grant photo access in Settings to see your albums."),
                    )
                } else {
                    List(albums) { album in
                        Button {
                            AppConfiguration.shared.selectedAlbumIdentifier = album.id
                            AppConfiguration.shared.selectedAlbumName = album.name
                            Swift.Task { await photoVM.reload() }
                            isPresented = false
                        } label: {
                            HStack {
                                Text(album.name)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                Text("\(album.count)")
                                    .foregroundStyle(Color.secondaryLabel)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
        .task { await loadAlbums() }
    }

    private func loadAlbums() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else {
            isLoading = false
            return
        }

        var result: [AlbumItem] = []

        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        userAlbums.enumerateObjects { collection, _, _ in
            let count = PHAsset.fetchAssets(in: collection, options: nil).count
            // swiftlint:disable:next empty_count
            if count > 0, let title = collection.localizedTitle { // SONAS-001
                result.append(AlbumItem(id: collection.localIdentifier, name: title, count: count))
            }
        }

        let smartAlbums = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumUserLibrary,
            options: nil,
        )
        smartAlbums.enumerateObjects { collection, _, _ in
            let count = PHAsset.fetchAssets(in: collection, options: nil).count
            // swiftlint:disable:next empty_count
            if count > 0, let title = collection.localizedTitle { // SONAS-001
                result.append(AlbumItem(id: collection.localIdentifier, name: title, count: count))
            }
        }

        albums = result.sorted { $0.name < $1.name }
        isLoading = false
    }
}
