import Testing
import Foundation
@testable import Sonas

// MARK: - PhotoContractTests (T064)
// 🔴 TEST-FIRST GATE — run before PhotoService (T063)

@Suite("Photo Service Contract Tests")
struct PhotoContractTests {

    // MARK: - T064.1: fetchRecentPhotos returns 5 photos sorted descending by creationDate

    @Test("given mock photo service with 5 assets when fetchRecentPhotos called then returns 5 photos sorted descending")
    func given_mockWith5Assets_when_fetchRecent_then_5PhotosSortedDescending() async throws {
        let service = PhotoServiceMock()
        let photos = try await service.fetchRecentPhotos(limit: 20)

        #expect(photos.count == 5, "Fixture must return exactly 5 photos")

        // Verify descending sort by creationDate
        for i in 0..<(photos.count - 1) {
            if let d1 = photos[i].creationDate, let d2 = photos[i + 1].creationDate {
                #expect(d1 >= d2, "Photos must be sorted by creationDate descending")
            }
        }
    }

    // MARK: - T064.2: albumEmpty error when album has no assets

    @Test("given album with no assets when fetchRecentPhotos called then throws albumEmpty")
    func given_emptyAlbum_when_fetchRecentPhotos_then_throwsAlbumEmpty() async throws {
        final class EmptyPhotoServiceMock: PhotoServiceProtocol, @unchecked Sendable {
            var selectedAlbumName: String? = "Empty Album"
            func fetchRecentPhotos(limit: Int) async throws -> [Photo] {
                throw PhotoServiceError.albumEmpty
            }
            func loadThumbnail(for photo: Photo, size: CGSize) async throws -> Data { Data() }
            func loadFullImage(for photo: Photo) async throws -> Data { Data() }
            func selectSharedAlbum() async throws -> String { "" }
        }

        let service = EmptyPhotoServiceMock()
        await #expect(throws: PhotoServiceError.self) {
            _ = try await service.fetchRecentPhotos(limit: 20)
        }
    }
}
