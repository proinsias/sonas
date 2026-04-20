import Foundation
import Photos

// MARK: - PhotoServiceProtocol (T061)

@MainActor
protocol PhotoServiceProtocol: AnyObject, Sendable {
    func fetchRecentPhotos(limit: Int) async throws -> [Photo]
    func loadThumbnail(for photo: Photo, size: CGSize) async throws -> Data
    func loadFullImage(for photo: Photo) async throws -> Data
    func selectSharedAlbum() async throws -> String // Returns album display name
    var selectedAlbumName: String? { get }
}

// MARK: - PhotoServiceError

enum PhotoServiceError: LocalizedError {
    case permissionDenied
    case albumNotFound
    case albumEmpty
    case imageLoadFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied: "Photo library access is required to show the family gallery."
        case .albumNotFound: "The selected album could not be found. Re-select in Settings."
        case .albumEmpty: "The selected album is empty. Add photos to see them here."
        case .imageLoadFailed: "Could not load photo."
        }
    }
}

// MARK: - PhotoService (T063)

@MainActor
final class PhotoService: NSObject, PhotoServiceProtocol, PHPhotoLibraryChangeObserver {
    var selectedAlbumName: String? {
        AppConfiguration.shared.selectedAlbumName
    }

    private var changeObservationTask: Swift.Task<Void, Never>?
    private var onAlbumChanged: (() -> Void)?

    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    // MARK: - PhotoServiceProtocol

    func fetchRecentPhotos(limit: Int = 20) async throws -> [Photo] {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else {
            throw PhotoServiceError.permissionDenied
        }

        guard let albumID = AppConfiguration.shared.selectedAlbumIdentifier else {
            return []
        }

        let collections = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [albumID],
            options: nil,
        )
        guard let album = collections.firstObject else {
            throw PhotoServiceError.albumNotFound
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = limit
        let assets = PHAsset.fetchAssets(in: album, options: fetchOptions)

        // swiftlint:disable:next empty_count
        guard assets.count != 0 else { // PHFetchResult lacks isEmpty before iOS 18 (SONAS-001)
            throw PhotoServiceError.albumEmpty
        }

        var photos: [Photo] = []
        assets.enumerateObjects { asset, _, _ in
            photos.append(Photo(
                id: asset.localIdentifier,
                creationDate: asset.creationDate,
                width: asset.pixelWidth,
                height: asset.pixelHeight,
                contributorName: nil,
            ))
        }
        SonasLogger.photos.info("PhotoService: fetched \(photos.count) photos")
        return photos
    }

    func loadThumbnail(for photo: Photo, size: CGSize = CGSize(width: 400, height: 400)) async throws -> Data {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [photo.id], options: nil)
        guard let asset = assets.firstObject else { throw PhotoServiceError.imageLoadFailed }

        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: options,
            ) { image, info in
                if let degraded = info?[PHImageResultIsDegradedKey] as? Bool, degraded { return }
                if let image, let data = image.pngData() {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: PhotoServiceError.imageLoadFailed)
                }
            }
        }
    }

    func loadFullImage(for photo: Photo) async throws -> Data {
        try await loadThumbnail(for: photo, size: PHImageManagerMaximumSize)
    }

    func selectSharedAlbum() async throws -> String {
        // Album picker presented from SettingsView via PHPickerViewController
        // Returns album name after user selection; actual UI in SettingsView T092
        AppConfiguration.shared.selectedAlbumName ?? ""
    }

    // MARK: - PHPhotoLibraryChangeObserver

    nonisolated func photoLibraryDidChange(_: PHChange) {
        Swift.Task { @MainActor in
            SonasLogger.photos.info("PhotoService: library changed — triggering re-fetch")
            onAlbumChanged?()
        }
    }

    func onAlbumChanged(_ handler: @escaping () -> Void) {
        onAlbumChanged = handler
    }
}
