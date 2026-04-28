import Foundation
import Sonas
import XCTest

@MainActor
final class MockSpotifyWebClient: @unchecked Sendable {
    private let track: TVCurrentTrack?
    private let shouldThrow: Error?

    init(track: TVCurrentTrack? = nil, shouldThrow: Error? = nil) {
        self.track = track
        self.shouldThrow = shouldThrow
    }

    static func authenticated(track: TVCurrentTrack) -> MockSpotifyWebClient {
        MockSpotifyWebClient(track: track)
    }

    static func authenticated(nothingPlaying _: Bool = true) -> MockSpotifyWebClient {
        MockSpotifyWebClient(track: nil)
    }

    static func unauthenticated() -> MockSpotifyWebClient {
        MockSpotifyWebClient(shouldThrow: SpotifyServiceError.unauthenticated)
    }
}

extension MockSpotifyWebClient: TVSpotifyWebClientProtocol {
    func fetchCurrentlyPlaying() async throws -> TVCurrentTrack? {
        if let err = shouldThrow {
            throw err
        }
        return track
    }
}

// MARK: - TVSpotifyReadServiceTests

@MainActor
final class TVSpotifyReadServiceTests: XCTestCase {
    /// Scenario 1: given_authenticated_trackPlaying_when_fetchCurrentlyPlaying_then_returnsTrack
    func test_given_authenticated_trackPlaying_when_fetchCurrentlyPlaying_then_returnsTrack() async throws {
        let fixture = TVCurrentTrack(
            id: "spotify:track:123",
            title: "Test Track",
            artistName: "Test Artist",
            albumArtURL: URL(string: "https://example.com/art.jpg"),
            isPlaying: true,
            fetchedAt: Date()
        )
        let client = MockSpotifyWebClient.authenticated(track: fixture)
        let sut = TVSpotifyReadService(client: client)

        let result = try await sut.fetchCurrentlyPlaying()

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.title, "Test Track")
        XCTAssertTrue(sut.isAuthenticated)
    }

    /// Scenario 2: given_authenticated_nothingPlaying_when_fetchCurrentlyPlaying_then_returnsNil
    func test_given_authenticated_nothingPlaying_when_fetchCurrentlyPlaying_then_returnsNil() async throws {
        let client = MockSpotifyWebClient.authenticated(nothingPlaying: true)
        let sut = TVSpotifyReadService(client: client)

        let result = try await sut.fetchCurrentlyPlaying()

        XCTAssertNil(result)
        XCTAssertTrue(sut.isAuthenticated)
    }

    /// Scenario 3: given_notAuthenticated_when_fetchCurrentlyPlaying_then_returnsNilAndNoRequest
    func test_given_notAuthenticated_when_fetchCurrentlyPlaying_then_returnsNilAndNoRequest() async throws {
        let client = MockSpotifyWebClient.unauthenticated()
        let sut = TVSpotifyReadService(client: client)

        let result = try await sut.fetchCurrentlyPlaying()

        XCTAssertNil(result)
        XCTAssertFalse(sut.isAuthenticated)
    }
}
