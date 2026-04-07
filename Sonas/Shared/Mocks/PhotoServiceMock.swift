import Foundation
import UIKit

// MARK: - PhotoServiceMock (T062)

final class PhotoServiceMock: PhotoServiceProtocol, @unchecked Sendable {

    private(set) var selectedAlbumName: String? = "Family Album"

    func fetchRecentPhotos(limit: Int = 20) async throws -> [Photo] {
        return Self.fixtures
    }

    func loadThumbnail(for photo: Photo, size: CGSize) async throws -> Data {
        return UIColor.systemBlue.image(size: size).pngData() ?? Data()
    }

    func loadFullImage(for photo: Photo) async throws -> Data {
        return UIColor.systemBlue.image(size: CGSize(width: 1080, height: 1080)).pngData() ?? Data()
    }

    func selectSharedAlbum() async throws -> String {
        return selectedAlbumName ?? "Mock Album"
    }

    static let fixtures: [Photo] = (0..<5).map { index in
        Photo(
            id: "mock-photo-\(index)",
            creationDate: Date.now.addingTimeInterval(TimeInterval(-index * 86400)),
            width: 1080,
            height: 1080,
            contributorName: ["Alice", "Bob", "Carol"][index % 3]
        )
    }
}

// MARK: - Helper

private extension UIColor {
    func image(size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { ctx in
            self.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}
