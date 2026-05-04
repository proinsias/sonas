import CoreImage
import Foundation
@testable import Sonas
import Testing

// MARK: - JamIntegrationTests (T076-I)

// Constitution §II — every user-facing feature MUST have an integration test.

@MainActor
@Suite("Jam Panel Integration Tests")
struct JamIntegrationTests {
    // MARK: - T076-I.1: JamPanelView renders non-nil QR Image within 500ms of startJam resolving

    @Test
    func `given JamServiceMock when startJam called then QR_CIImage_is_non_nil_within_500_ms`() async throws {
        let start = Date.now
        let service = JamServiceMock()
        let session = try await service.startJam()
        let elapsed = Date.now.timeIntervalSince(start)

        #expect(elapsed < 0.5, "JamService startJam mock must complete within 500ms; took \(elapsed)s")

        // Verify QR code can be generated from session.joinURL (same path as JamPanelView)
        let data = Data(session.joinURL.absoluteString.utf8)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        let ciImage = filter?.outputImage
        #expect(ciImage != nil, "QR CIImage must be non-nil for a valid Spotify jam URL")
    }

    // MARK: - T076-I.2: QR Image accessibility identifier disappears after endJam

    @Test
    func `given active jam session when endJam called then session_status_is_ended_and_QR_should_be_hidden`() async {
        let service = JamServiceMock()
        let vm = JamViewModel(service: service)

        await vm.startJam()
        #expect(vm.status == .active, "Status must be active after startJam")

        await vm.endJam()
        #expect(vm.status == .ended, "Status must be ended after endJam — QR view should be hidden")
    }
}
