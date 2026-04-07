import Foundation
import UIKit

// MARK: - JamServiceProtocol (T069)

protocol JamServiceProtocol: AnyObject, Sendable {
    var currentSession: JamSession? { get }
    func startJam() async throws -> JamSession
    func endJam() async throws
    func connectSpotify() async throws
    var isSpotifyConnected: Bool { get }
    var isSpotifyInstalled: Bool { get }
}

// MARK: - JamServiceError

enum JamServiceError: LocalizedError {
    case spotifyNotInstalled
    case spotifyAuthFailed(Error)
    case sessionStartFailed(Error)
    case sessionNotActive

    var errorDescription: String? {
        switch self {
        case .spotifyNotInstalled:
            return "Spotify is not installed. Install Spotify to use Jam."
        case .spotifyAuthFailed(let err):
            return "Spotify connection failed: \(err.localizedDescription)"
        case .sessionStartFailed(let err):
            return "Could not start Jam: \(err.localizedDescription)"
        case .sessionNotActive:
            return "No active Jam session."
        }
    }
}

// MARK: - SpotifyJamService (T071)
// Spotify iOS SDK integration — SPTConfiguration, SPTSessionManager, SPTAppRemote.
// Requires SpotifyiOS framework linked in project.yml.

@MainActor
final class SpotifyJamService: JamServiceProtocol {

    private(set) var currentSession: JamSession?
    private(set) var isSpotifyConnected: Bool = false

    var isSpotifyInstalled: Bool {
        guard let spotifyURL = URL(string: "spotify://") else { return false }
        return UIApplication.shared.canOpenURL(spotifyURL)
    }

    // MARK: - JamServiceProtocol

    func connectSpotify() async throws {
        guard isSpotifyInstalled else {
            throw JamServiceError.spotifyNotInstalled
        }
        // SPTConfiguration + SPTSessionManager.initiateSession via ASWebAuthenticationSession
        // Full implementation requires SpotifyiOS SDK calls
        // Placeholder: marks connected state
        isSpotifyConnected = true
        SonasLogger.jam.info("SpotifyJamService: connected")
    }

    func startJam() async throws -> JamSession {
        guard isSpotifyInstalled else { throw JamServiceError.spotifyNotInstalled }
        if !isSpotifyConnected {
            try await connectSpotify()
            guard isSpotifyConnected else {
                throw JamServiceError.spotifyAuthFailed(
                    NSError(domain: "Spotify", code: -1, userInfo: [NSLocalizedDescriptionKey: "Auth failed"])
                )
            }
        }

        // SPTAppRemote.playerAPI.startGroupSession(callback:)
        // Placeholder: returns a fixture join URL until SPTAppRemote is integrated
        let joinURL = URL(string: "https://open.spotify.com/jam/\(UUID().uuidString.lowercased().prefix(8))")!
        let session = JamSession(
            id: UUID().uuidString,
            joinURL: joinURL,
            status: .active,
            startedAt: .now
        )
        currentSession = session
        SonasLogger.jam.info("SpotifyJamService: jam started")
        return session
    }

    func endJam() async throws {
        guard currentSession?.status == .active else { throw JamServiceError.sessionNotActive }
        currentSession = currentSession.map {
            JamSession(id: $0.id, joinURL: $0.joinURL, status: .ended, startedAt: $0.startedAt)
        }
        // SPTAppRemote stop group session call
        SonasLogger.jam.info("SpotifyJamService: jam ended")
    }
}
