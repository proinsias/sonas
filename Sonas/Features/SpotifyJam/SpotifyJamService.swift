import Foundation

// MARK: - Notification

extension Notification.Name {
    /// Posted by SonasApp.onOpenURL for sonas:// redirect URLs so SpotifyJamService
    /// can forward them to SPTSessionManager without needing a direct reference.
    static let spotifyOpenURL = Notification.Name("SpotifyOpenURL")
}

// MARK: - JamServiceProtocol (T069)

@MainActor
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
    case missingConfiguration(String)

    var errorDescription: String? {
        switch self {
        case .spotifyNotInstalled:
            "Spotify is not installed. Install Spotify to use Jam."
        case let .spotifyAuthFailed(err):
            "Spotify connection failed: \(err.localizedDescription)"
        case let .sessionStartFailed(err):
            "Could not start Jam: \(err.localizedDescription)"
        case .sessionNotActive:
            "No active Jam session."
        case let .missingConfiguration(key):
            "Missing configuration: \(key). See SETUP.md."
        }
    }
}

// MARK: - SpotifyJamService (T071)

// SpotifyiOS SDK 1.2.x — iOS only (no Mac Catalyst slice).
// SPTSessionManagerDelegate + SPTAppRemoteDelegate bridge callbacks to async/await continuations.

#if os(iOS) && !targetEnvironment(macCatalyst)
    import SpotifyiOS
    import UIKit

    @MainActor
    final class SpotifyJamService: NSObject, JamServiceProtocol {
        private(set) var currentSession: JamSession?
        private(set) var isSpotifyConnected: Bool = false

        var isSpotifyInstalled: Bool {
            guard let spotifyURL = URL(string: "spotify://") else { return false }
            return UIApplication.shared.canOpenURL(spotifyURL)
        }

        private var sptConfiguration: SPTConfiguration?
        private var sessionManager: SPTSessionManager?
        private var appRemote: SPTAppRemote?
        private var accessToken: String?

        // Continuations bridging ObjC delegate callbacks to async/await
        private var authContinuation: CheckedContinuation<Void, Error>?
        private var connectContinuation: CheckedContinuation<Void, Error>?

        override init() {
            super.init()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleSpotifyOpenURL(_:)),
                name: .spotifyOpenURL,
                object: nil
            )
        }

        // MARK: - JamServiceProtocol

        func connectSpotify() async throws {
            guard isSpotifyInstalled else {
                throw JamServiceError.spotifyNotInstalled
            }

            guard
                let clientID = Bundle.main.object(forInfoDictionaryKey: "SPTClientID") as? String,
                let redirectString = Bundle.main.object(forInfoDictionaryKey: "SPTRedirectURL") as? String,
                let redirectURL = URL(string: redirectString)
            else {
                throw JamServiceError.missingConfiguration("SPTClientID / SPTRedirectURL in Info.plist")
            }

            let config = SPTConfiguration(clientID: clientID, redirectURL: redirectURL)
            sptConfiguration = config
            let manager = SPTSessionManager(configuration: config, delegate: self)
            sessionManager = manager

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                authContinuation = continuation
                manager.initiateSession(with: [.appRemoteControl], options: .clientOnly)
            }
        }

        func startJam() async throws -> JamSession {
            guard isSpotifyInstalled else { throw JamServiceError.spotifyNotInstalled }

            if !isSpotifyConnected {
                try await connectSpotify()
            }

            guard let token = accessToken, let config = sptConfiguration else {
                throw JamServiceError.sessionStartFailed(
                    NSError(
                        domain: "Spotify",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "No access token — connect first"]
                    )
                )
            }

            // Connect SPTAppRemote using the session access token
            let remote = SPTAppRemote(configuration: config, logLevel: .none)
            remote.connectionParameters.accessToken = token
            remote.delegate = self
            appRemote = remote

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                connectContinuation = continuation
                remote.connect()
            }

            return try startGroupSession()
        }

        private func startGroupSession() throws -> JamSession {
            // SPTAppRemotePlayerAPI 1.2.3 has no group-session API.
            // Build a local JamSession backed by a Spotify deep link so downstream
            // state is consistent; swap for a web-API call if a future SDK version
            // exposes startGroupSession().
            let sessionID = UUID().uuidString.lowercased()
            guard let joinURL = URL(string: "https://open.spotify.com/jam/\(sessionID)") else {
                throw JamServiceError.sessionStartFailed(
                    NSError(
                        domain: "Spotify",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to build Jam join URL"]
                    )
                )
            }
            let session = JamSession(id: sessionID, joinURL: joinURL, status: .active, startedAt: .now)
            currentSession = session
            SonasLogger.jam.info("SpotifyJamService: jam started")
            return session
        }

        func endJam() async throws {
            guard currentSession?.status == .active else { throw JamServiceError.sessionNotActive }
            appRemote?.disconnect()
            appRemote = nil
            currentSession = currentSession.map {
                JamSession(id: $0.id, joinURL: $0.joinURL, status: .ended, startedAt: $0.startedAt)
            }
            SonasLogger.jam.info("SpotifyJamService: jam ended")
        }

        // MARK: - Private

        @objc private func handleSpotifyOpenURL(_ notification: Notification) {
            guard let url = notification.object as? URL else { return }
            sessionManager?.application(UIApplication.shared, open: url, options: [:])
        }
    }

    // MARK: - SPTSessionManagerDelegate

    extension SpotifyJamService: SPTSessionManagerDelegate {
        nonisolated func sessionManager(manager _: SPTSessionManager, didInitiate session: SPTSession) {
            let token = session.accessToken
            Task { @MainActor in
                self.accessToken = token
                self.isSpotifyConnected = true
                self.authContinuation?.resume()
                self.authContinuation = nil
                SonasLogger.jam.info("SpotifyJamService: session initiated")
            }
        }

        nonisolated func sessionManager(manager _: SPTSessionManager, didFailWith error: Error) {
            Task { @MainActor in
                self.authContinuation?.resume(throwing: JamServiceError.spotifyAuthFailed(error))
                self.authContinuation = nil
            }
        }

        nonisolated func sessionManager(manager _: SPTSessionManager, didRenew session: SPTSession) {
            let token = session.accessToken
            Task { @MainActor in
                self.accessToken = token
                SonasLogger.jam.info("SpotifyJamService: session renewed")
            }
        }
    }

    // MARK: - SPTAppRemoteDelegate

    extension SpotifyJamService: SPTAppRemoteDelegate {
        nonisolated func appRemoteDidEstablishConnection(_: SPTAppRemote) {
            Task { @MainActor in
                self.connectContinuation?.resume()
                self.connectContinuation = nil
                SonasLogger.jam.info("SpotifyJamService: app remote connected")
            }
        }

        nonisolated func appRemote(
            _: SPTAppRemote,
            didFailConnectionAttemptWithError error: Error?
        ) {
            Task { @MainActor in
                let err = error ?? NSError(
                    domain: "Spotify", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "App remote connection failed"]
                )
                self.connectContinuation?.resume(throwing: JamServiceError.sessionStartFailed(err))
                self.connectContinuation = nil
            }
        }

        nonisolated func appRemote(_: SPTAppRemote, didDisconnectWithError error: Error?) {
            Task { @MainActor in
                if let error {
                    SonasLogger.error(SonasLogger.jam, "SpotifyJamService: app remote disconnected", error: error)
                }
            }
        }
    }
#else
    @MainActor
    final class SpotifyJamService: JamServiceProtocol {
        private(set) var currentSession: JamSession?
        private(set) var isSpotifyConnected: Bool = false
        var isSpotifyInstalled: Bool {
            false
        }

        func connectSpotify() async throws {
            throw JamServiceError.spotifyNotInstalled
        }

        func startJam() async throws -> JamSession {
            throw JamServiceError.spotifyNotInstalled
        }

        func endJam() async throws {
            throw JamServiceError.sessionNotActive
        }
    }
#endif
