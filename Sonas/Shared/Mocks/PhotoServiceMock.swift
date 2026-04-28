import Foundation
#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

// MARK: - PhotoServiceMock (T062)

final class PhotoServiceMock: PhotoServiceProtocol, @unchecked Sendable {
    private(set) var selectedAlbumName: String? = "Family Album"

    func fetchRecentPhotos(limit _: Int = 20) async throws -> [Photo] {
        Self.fixtures
    }

    func loadThumbnail(for _: Photo, size: CGSize) async throws -> Data {
        #if os(macOS)
            return NSImage(color: .systemBlue, size: size).pngData() ?? Data()
        #else
            return UIColor.systemBlue.image(size: size).pngData() ?? Data()
        #endif
    }

    func loadFullImage(for _: Photo) async throws -> Data {
        let size = CGSize(width: 1080, height: 1080)
        #if os(macOS)
            return NSImage(color: .systemBlue, size: size).pngData() ?? Data()
        #else
            return UIColor.systemBlue.image(size: size).pngData() ?? Data()
        #endif
    }

    func selectSharedAlbum() async throws -> String {
        selectedAlbumName ?? "Mock Album"
    }

    static let fixtures: [Photo] = (0 ..< 5).map { index in
        Photo(
            id: "mock-photo-\(index)",
            creationDate: Date.now.addingTimeInterval(TimeInterval(-index * 86400)),
            width: 1080,
            height: 1080,
            contributorName: ["Alice", "Bob", "Carol"][index % 3],
        )
    }
}

// MARK: - Helpers

#if os(macOS)
    private extension NSImage {
        convenience init(color: NSColor, size: CGSize) {
            self.init(size: size)
            lockFocus()
            color.set()
            NSRect(origin: .zero, size: size).fill()
            unlockFocus()
        }
    }
#else
    private extension UIColor {
        func image(size: CGSize) -> UIImage {
            guard size.width > 0, size.height > 0 else { return UIImage() }
            return UIGraphicsImageRenderer(size: size).image { ctx in
                self.setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
            }
        }
    }
#endif
