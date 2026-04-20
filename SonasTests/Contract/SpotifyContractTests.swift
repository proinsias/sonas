import Foundation
@testable import Sonas
import Testing

// MARK: - SpotifyContractTests (T072)

// 🔴 TEST-FIRST GATE — run before SpotifyJamService (T071)

@MainActor
@Suite("Spotify Jam Service Contract Tests")
struct SpotifyContractTests {
    // MARK: - T072.1: startJam returns active session with joinURL

    @Test
    func `given mock Spotify service when startJam called then returns JamSession with status active and joinURL`(
    ) async throws {
        let service = JamServiceMock()
        let session = try await service.startJam()

        #expect(session.status == .active, "Session status must be .active after startJam")
        #expect(session.joinURL.absoluteString.contains("spotify.com/jam"), "joinURL must reference Spotify jam")
    }

    // MARK: - T072.2: startJam throws spotifyNotInstalled when isSpotifyInstalled == false

    @Test
    func `given Spotify not installed when startJam called then throws spotifyNotInstalled`() async throws {
        let service = JamServiceMock()
        service.isSpotifyInstalled = false

        await #expect(throws: JamServiceError.self) {
            _ = try await service.startJam()
        }
    }

    // MARK: - T072.3: endJam transitions status to ended

    @Test
    func `given active session when endJam then session status transitions to ended`() async throws {
        let service = JamServiceMock()
        _ = try await service.startJam()
        try await service.endJam()

        #expect(service.currentSession?.status == .ended, "Session must be .ended after endJam")
    }

    // MARK: - T072.4: QR code can be generated from joinURL

    @Test
    func `given jam session joinURL when CIFilter.qrCodeGenerator then produces non-nil CIImage`() async throws {
        let service = JamServiceMock()
        let session = try await service.startJam()

        let urlString = session.joinURL.absoluteString
        let data = Data(urlString.utf8)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("M", forKey: "inputCorrectionLevel")

        let ciImage = filter?.outputImage
        #expect(ciImage != nil, "CIQRCodeGenerator must produce a non-nil CIImage for a valid Spotify jam URL")
    }
}

// MARK: - CIFilter import

import CoreImage
