import Foundation

// MARK: - JamServiceMock (T070)

final class JamServiceMock: JamServiceProtocol, @unchecked Sendable {
    private(set) var currentSession: JamSession?
    private(set) var isSpotifyConnected: Bool = true
    var isSpotifyInstalled: Bool = true

    func connectSpotify() async throws {
        isSpotifyConnected = true
    }

    func startJam() async throws -> JamSession {
        let session = JamSession(
            id: "mock-jam-session",
            joinURL: URL(string: "https://spotify.com/jam/abc123")!,
            status: .active,
            startedAt: .now,
        )
        currentSession = session
        return session
    }

    func endJam() async throws {
        currentSession = currentSession.map {
            JamSession(id: $0.id, joinURL: $0.joinURL, status: .ended, startedAt: $0.startedAt)
        }
    }
}
