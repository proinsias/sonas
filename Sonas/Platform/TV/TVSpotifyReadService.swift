import Foundation

// MARK: - SpotifyServiceError

enum SpotifyServiceError: LocalizedError {
    case unauthenticated
    case networkError
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .unauthenticated: "Spotify not authenticated"
        case .networkError: "Network error"
        case .decodingFailed: "Failed to decode response"
        }
    }
}

// MARK: - TVSpotifyWebClientProtocol

protocol TVSpotifyWebClientProtocol: AnyObject, Sendable {
    func fetchCurrentlyPlaying() async throws -> TVCurrentTrack?
}

// MARK: - TVSpotifyReadServiceProtocol

@MainActor
protocol TVSpotifyReadServiceProtocol: AnyObject, Sendable {
    func fetchCurrentlyPlaying() async throws -> TVCurrentTrack?
    var isAuthenticated: Bool { get }
}

// MARK: - TVSpotifyReadService

@MainActor
final class TVSpotifyReadService: TVSpotifyReadServiceProtocol {
    private let client: TVSpotifyWebClientProtocol
    private var cachedToken: String?

    var isAuthenticated: Bool {
        cachedToken != nil
    }

    init(client: TVSpotifyWebClientProtocol? = nil, tokenOverride: String? = nil) {
        self.client = client ?? SpotifyWebClient()
        cachedToken = tokenOverride ?? UserDefaults.standard.string(forKey: "spotify_access_token")
    }

    func fetchCurrentlyPlaying() async throws -> TVCurrentTrack? {
        guard isAuthenticated else { return nil }

        let track = try await client.fetchCurrentlyPlaying()
        return track.map {
            TVCurrentTrack(
                id: $0.id,
                title: $0.title,
                artistName: $0.artistName,
                albumArtURL: $0.albumArtURL,
                isPlaying: true,
                fetchedAt: Date()
            )
        }
    }
}

// MARK: - SpotifyWebClient

final class SpotifyWebClient: TVSpotifyWebClientProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCurrentlyPlaying() async throws -> TVCurrentTrack? {
        guard let token = UserDefaults.standard.string(forKey: "spotify_access_token") else {
            throw SpotifyServiceError.unauthenticated
        }

        guard let url = URL(string: "https://api.spotify.com/v1/me/player/currently-playing") else {
            throw SpotifyServiceError.networkError
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpotifyServiceError.networkError
        }

        if httpResponse.statusCode == 401 {
            throw SpotifyServiceError.unauthenticated
        }

        guard httpResponse.statusCode == 200 else {
            return nil
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let item = json["item"] as? [String: Any],
              let id = item["id"] as? String,
              let name = item["name"] as? String,
              let artists = item["artists"] as? [[String: Any]],
              let artistName = artists.first?["name"] as? String,
              let album = item["album"] as? [String: Any],
              let images = album["images"] as? [[String: Any]],
              let firstImage = images.first,
              let imageURLString = firstImage["url"] as? String
        else {
            return nil
        }

        return TVCurrentTrack(
            id: id,
            title: name,
            artistName: artistName,
            albumArtURL: URL(string: imageURLString),
            isPlaying: json["is_playing"] as? Bool ?? false,
            fetchedAt: Date()
        )
    }
}
