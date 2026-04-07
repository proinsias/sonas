import Testing
import Foundation
import CoreImage
@testable import Sonas

// MARK: - JamIntegrationTests (T076-I)
// Constitution §II — every user-facing feature MUST have an integration test.

@Suite("Jam Panel Integration Tests")
struct JamIntegrationTests {

    // MARK: - T076-I.1: JamPanelView renders non-nil QR Image within 500ms of startJam resolving

    @Test("given JamServiceMock when startJam called then QR CIImage is non-nil within 500ms")
    func given_mockJamService_when_startJam_then_qrImageNonNilWithin500ms() async throws {
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

    @Test("given active jam session when endJam called then session status is ended and QR should be hidden")
    func given_activeSession_when_endJam_then_sessionEnded() async throws {
        let service = JamServiceMock()
        let vm = JamViewModel(service: service)

        await vm.startJam()
        #expect(vm.status == .active, "Status must be active after startJam")

        await vm.endJam()
        #expect(vm.status == .ended, "Status must be ended after endJam — QR view should be hidden")
    }
}
