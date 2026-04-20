import Foundation
@testable import Sonas
import Testing

// MARK: - PhotoContractTests (T064)

// 🔴 TEST-FIRST GATE — run before PhotoService (T063)

@MainActor
@Suite("Photo Service Contract Tests")
struct PhotoContractTests {
    // MARK: - T064.1: fetchRecentPhotos returns 5 photos sorted descending by creationDate

    @Test
    func `given mock with 5 assets when fetch recent then 5 photos sorted descending`() async throws {
        let service = PhotoServiceMock()
        let photos = try await service.fetchRecentPhotos(limit: 20)

        #expect(photos.count == 5, "Fixture must return exactly 5 photos")

        // Verify descending sort by creationDate
        for index in 0 ..< (photos.count - 1) {
            if let date1 = photos[index].creationDate, let date2 = photos[index + 1].creationDate {
                #expect(date1 >= date2, "Photos must be sorted by creationDate descending")
            }
        }
    }

    // MARK: - T064.2: albumEmpty error when album has no assets

    @Test
    func `given album with no assets when fetchRecentPhotos called then throws albumEmpty`() async throws {
        final class EmptyPhotoServiceMock: PhotoServiceProtocol, @unchecked Sendable {
            var selectedAlbumName: String? = "Empty Album"
            func fetchRecentPhotos(limit _: Int) async throws -> [Photo] {
                throw PhotoServiceError.albumEmpty
            }

            func loadThumbnail(for _: Photo, size _: CGSize) async throws -> Data {
                Data()
            }

            func loadFullImage(for _: Photo) async throws -> Data {
                Data()
            }

            func selectSharedAlbum() async throws -> String {
                ""
            }
        }

        let service = EmptyPhotoServiceMock()
        await #expect(throws: PhotoServiceError.self) {
            _ = try await service.fetchRecentPhotos(limit: 20)
        }
    }
}
