import Foundation
import Observation

// MARK: - JamViewModel (T073)

@Observable
@MainActor
final class JamViewModel {
    // MARK: Published state

    private(set) var session: JamSession?
    private(set) var isLoading: Bool = false
    private(set) var error: PanelError?
    var status: JamStatus {
        session?.status ?? .none
    }

    private(set) var isSpotifyConnected: Bool
    private(set) var isSpotifyInstalled: Bool

    // MARK: Dependencies

    private let service: any JamServiceProtocol

    init(service: any JamServiceProtocol) {
        self.service = service
        session = service.currentSession
        isSpotifyConnected = service.isSpotifyConnected
        isSpotifyInstalled = service.isSpotifyInstalled
    }

    static func makeDefault() -> JamViewModel {
        let useMock = ProcessInfo.processInfo.environment["USE_MOCK_JAM"] == "1"
        return JamViewModel(service: useMock ? JamServiceMock() : SpotifyJamService())
    }

    // MARK: - Actions

    func startJam() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        do {
            session = try await service.startJam()
            isSpotifyConnected = service.isSpotifyConnected
            SonasLogger.jam.info("JamViewModel: session started")
        } catch JamServiceError.spotifyNotInstalled {
            let errorDescription = JamServiceError.spotifyNotInstalled.errorDescription ?? "Spotify is not installed"
            error = PanelError(title: "Spotify Not Installed", message: errorDescription, isRetryable: false)
        } catch {
            self.error = PanelError(title: "Jam Failed", message: error.localizedDescription, isRetryable: true)
        }
        isLoading = false
    }

    func endJam() async {
        isLoading = true
        do {
            try await service.endJam()
            session = service.currentSession
        } catch {
            self.error = PanelError(title: "Could Not End Jam", message: error.localizedDescription, isRetryable: true)
        }
        isLoading = false
    }

    func connectSpotify() async {
        isLoading = true
        do {
            try await service.connectSpotify()
            isSpotifyConnected = true
        } catch {
            self.error = PanelError(title: "Connection Failed", message: error.localizedDescription, isRetryable: true)
        }
        isLoading = false
    }
}
