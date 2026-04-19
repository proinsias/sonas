import Foundation
import Observation

// MARK: - PhotoViewModel (T065)

@Observable
@MainActor
final class PhotoViewModel {
    private(set) var photos: [Photo] = []
    private(set) var isLoading: Bool = true
    private(set) var error: PanelError?
    private(set) var selectedAlbumName: String?

    private let service: any PhotoServiceProtocol

    init(service: any PhotoServiceProtocol) {
        self.service = service
        selectedAlbumName = service.selectedAlbumName
        if let photoService = service as? PhotoService {
            photoService.onAlbumChanged { [weak self] in
                Swift.Task { await self?.reload() }
            }
        }
    }

    static func makeDefault() -> PhotoViewModel {
        let useMock = ProcessInfo.processInfo.environment["USE_MOCK_PHOTOS"] == "1"
        return PhotoViewModel(service: useMock ? PhotoServiceMock() : PhotoService())
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            photos = try await service.fetchRecentPhotos(limit: 20)
            selectedAlbumName = service.selectedAlbumName
            isLoading = false
        } catch PhotoServiceError.albumEmpty {
            photos = []
            isLoading = false
        } catch PhotoServiceError.permissionDenied {
            error = .permissionDenied
            isLoading = false
        } catch {
            self.error = PanelError(title: "Photos Unavailable", message: error.localizedDescription, isRetryable: true)
            isLoading = false
        }
    }

    func reload() async {
        await load()
    }

    func loadThumbnail(for photo: Photo) async throws -> Data {
        try await service.loadThumbnail(for: photo, size: CGSize(width: 400, height: 400))
    }

    func loadFullImage(for photo: Photo) async throws -> Data {
        try await service.loadFullImage(for: photo)
    }
}
