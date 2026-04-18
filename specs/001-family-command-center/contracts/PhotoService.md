# Contract: PhotoService

**Purpose**: Access the designated iCloud Shared Album via PhotoKit; provide
photo metadata and on-demand image loading.

```swift
protocol PhotoServiceProtocol {
    /// Fetch metadata for the most recent `limit` photos in the configured shared album.
    /// Default limit: 20. Sorted by creationDate descending.
    func fetchRecentPhotos(limit: Int) async throws -> [Photo]

    /// Load a thumbnail image for the given photo at the specified point size.
    func loadThumbnail(for photo: Photo, size: CGSize) async -> Image

    /// Load the full-resolution image for the given photo.
    func loadFullImage(for photo: Photo) async -> Image

    /// Present the system album picker so the user can select a shared album.
    /// Stores the selected album's localIdentifier in AppConfiguration.
    func selectSharedAlbum() async throws

    /// The currently selected shared album name, or nil if none configured.
    var selectedAlbumName: String? { get }
}
```

**PhotoKit access pattern**:

```swift
// Enumerate iCloud Shared Albums
let albums = PHAssetCollection.fetchAssetCollections(
    with: .album,
    subtype: .albumCloudShared,
    options: nil
)

// Fetch recent assets from selected album
let options = PHFetchOptions()
options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
options.fetchLimit = limit
let assets = PHAsset.fetchAssets(in: selectedAlbum, options: options)

// Load thumbnail
PHImageManager.default().requestImage(
    for: asset,
    targetSize: thumbnailSize,
    contentMode: .aspectFill,
    options: { options in options.deliveryMode = .opportunistic }
)
```

**Change observation**:

- `PHPhotoLibraryChangeObserver.photoLibraryDidChange(_:)` called when album
  content changes.
- On change: re-fetch photo list; removed photos disappear gracefully on next
  carousel cycle.

**Error cases**:

- `PhotoServiceError.permissionDenied` — photo library access denied; panel
  shows "Enable photo access in Settings" prompt.
- `PhotoServiceError.noAlbumSelected` — no shared album configured; panel shows
  "Select a shared album" prompt.
- `PhotoServiceError.albumEmpty` — selected album has no photos; panel shows
  "Add photos to your shared album" prompt.
- Image load failure: returns a placeholder `Image` (SF Symbol `photo`); does
  not throw.

**Contract test fixtures** (`PhotoContractTests.swift`):

```swift
// Given: mock PHAssetCollection with 5 PHAssets
// When: fetchRecentPhotos(limit: 20) called
// Then: returns [Photo] with count == 5, sorted creationDate descending

// Given: album is empty
// When: fetchRecentPhotos(limit: 20) called
// Then: throws PhotoServiceError.albumEmpty
```
