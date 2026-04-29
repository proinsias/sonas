import Foundation

// MARK: - TVSpotifyReadServiceMock (T011a)

@MainActor
final class TVSpotifyReadServiceMock: TVSpotifyReadServiceProtocol, @unchecked Sendable {
    let isAuthenticated: Bool
    private let track: TVCurrentTrack?

    init(authenticated: Bool = true, track: TVCurrentTrack? = nil) {
        isAuthenticated = authenticated
        self.track = track ?? (authenticated ? Self.fixture : nil)
    }

    func fetchCurrentlyPlaying() async throws -> TVCurrentTrack? {
        guard isAuthenticated else { return nil }
        return track
    }

    static let fixture = TVCurrentTrack(
        id: "mock-track-1",
        title: "Family Playlist",
        artistName: "Various Artists",
        albumArtURL: nil,
        isPlaying: true,
        fetchedAt: Date()
    )
}
