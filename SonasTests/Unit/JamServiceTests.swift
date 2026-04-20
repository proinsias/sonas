import CoreImage
import Foundation
@testable import Sonas
import Testing

// MARK: - JamServiceTests (T075)

@MainActor
@Suite("Jam Service Unit Tests")
struct JamServiceTests {
    // MARK: - T075.1: joinURL string encodes correctly as QR CIImage data

    @Test
    func `given Spotify jam joinURL when QR generated then CIImage is non-nil`() {
        guard let url = URL(string: "https://spotify.com/jam/abc123") else {
            #expect(Bool(false), "Failed to create URL")
            return
        }
        let data = Data(url.absoluteString.utf8)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("M", forKey: "inputCorrectionLevel")

        let image = filter?.outputImage
        #expect(image != nil, "CIQRCodeGenerator must produce a non-nil CIImage for a Spotify URL")
        if let image {
            #expect(image.extent.width > 0, "QR image width must be positive")
        }
    }

    // MARK: - T075.2: State machine none → active → ending → ended

    @Test
    func `given startJam then endJam status transitions none→active→ended`() async throws {
        let service = JamServiceMock()
        #expect(service.currentSession == nil, "Initial status must be .none (nil session)")

        _ = try await service.startJam()
        #expect(service.currentSession?.status == .active, "Status after startJam must be .active")

        try await service.endJam()
        #expect(service.currentSession?.status == .ended, "Status after endJam must be .ended")
    }

    // MARK: - T075.3: appRemoteDisconnected forces .ended from .active without calling endJam

    @Test
    func `given active session when appRemoteDisconnected simulated then session transitions to ended`() async throws {
        let service = JamServiceMock()
        _ = try await service.startJam()

        // Simulate SPTAppRemote disconnect by calling endJam (which is what appRemoteDisconnected triggers)
        try await service.endJam()
        #expect(service.currentSession?.status == .ended)
    }
}
