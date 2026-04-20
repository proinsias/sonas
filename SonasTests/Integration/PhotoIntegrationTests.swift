import Foundation
@testable import Sonas
import Testing

// MARK: - PhotoIntegrationTests (T068-I)

// Constitution §II — every user-facing feature MUST have an integration test.

@MainActor
@Suite("Photo Gallery Integration Tests")
struct PhotoIntegrationTests {
    // MARK: - T068-I.1: PhotoGalleryView renders ≥1 thumbnail within 500ms

    @Test
    func `given PhotoServiceMock with 5 assets when PhotoViewModel loads then photos populated within 500ms`() async {
        let start = Date.now
        let vm = PhotoViewModel(service: PhotoServiceMock())
        await vm.load()
        let elapsed = Date.now.timeIntervalSince(start)

        #expect(!vm.photos.isEmpty, "PhotoViewModel must have photos after load")
        #expect(elapsed < 0.5, "Photo mock load must complete within 500ms; took \(elapsed)s")
    }

    // MARK: - T068-I.2: PHPhotoLibraryChangeObserver callback doesn't crash

    @Test
    func `given mock service when reload called then no crash and photos refreshed`() async {
        let vm = PhotoViewModel(service: PhotoServiceMock())
        await vm.load()
        let countBefore = vm.photos.count

        // Simulate library change callback triggering reload
        await vm.reload()
        let countAfter = vm.photos.count

        #expect(countAfter == countBefore, "Photo count must remain consistent after reload with same mock data")
        #expect(vm.error == nil, "No error should occur on reload with mock service")
    }
}
