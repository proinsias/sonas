# Contract: JamService

**Purpose**: Authenticate with Spotify via the iOS SDK; create and end a Spotify Jam (Group
Session); expose the join URL for QR code rendering.

```swift
protocol JamServiceProtocol {
    /// Current Jam session state, or nil if no session active.
    var currentSession: JamSession? { get async }

    /// Start a new Spotify Jam session.
    /// Requires: Spotify app installed, Spotify account connected.
    /// Returns the active JamSession with a joinURL suitable for QR encoding.
    func startJam() async throws -> JamSession

    /// End the current Jam session. No-op if no session is active.
    func endJam() async throws

    /// Connect a Spotify account via OAuth (SPTSessionManager).
    /// Presents ASWebAuthenticationSession if no valid token exists.
    func connectSpotify() async throws

    /// Whether a valid Spotify token is available.
    var isSpotifyConnected: Bool { get }

    /// Whether the Spotify app is installed on this device.
    var isSpotifyInstalled: Bool { get }
}
```

**Spotify iOS SDK integration**:
- `SPTConfiguration(clientID:redirectURL:)` — registered in Apple Developer portal + Spotify Dashboard
- `SPTSessionManager` — handles auth, token storage, refresh
- Scopes: `user-read-playback-state`, `user-modify-playback-state`, `streaming`, `app-remote-control`
- Group Session (Jam) initiation: `SPTAppRemote.playerAPI.startGroupSession` — SDK communicates
  with Spotify app via IPC; returns `joinURL` in callback
- Jam join URL format: `https://spotify.com/jam/{token}` (or `spotify://jam/{token}` deep link)

**QR Code generation** (in `JamPanelView`, not in service):
```swift
let filter = CIFilter.qrCodeGenerator()
filter.message = Data(joinURL.absoluteString.utf8)
filter.correctionLevel = "M"
let outputImage = filter.outputImage!.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
```

**Error cases**:
- `JamServiceError.spotifyNotInstalled` — `isSpotifyInstalled == false`; panel shows
  App Store deep-link prompt.
- `JamServiceError.notConnected` — no Spotify token; panel shows "Connect Spotify" button.
- `JamServiceError.sessionCreationFailed` — SDK error creating group session.
- `JamServiceError.appRemoteDisconnected` — Spotify app closed mid-session; `currentSession`
  set to `.ended`; QR removed.

**Contract test fixtures** (`SpotifyContractTests.swift`):
```swift
// Given: mock SPTSessionManager returning valid token
//        mock SPTAppRemote returning joinURL "https://spotify.com/jam/abc123"
// When: startJam() called
// Then: returns JamSession with joinURL == "https://spotify.com/jam/abc123"
//       status == .active

// Given: isSpotifyInstalled == false
// When: startJam() called
// Then: throws JamServiceError.spotifyNotInstalled
```
