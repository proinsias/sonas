# Contract: JamService

**Purpose**: Authenticate with Spotify via the iOS SDK; create and end a Spotify Jam (Group Session); expose the join
URL for QR code rendering.

```swift
protocol JamServiceProtocol {
    /// Current Jam session state, or nil if no session active.
    var currentSession: JamSession? { get }

    /// Start a new Spotify Jam session.
    /// Connects Spotify if not already connected, then creates a group session.
    /// Returns the active JamSession with a joinURL suitable for QR encoding.
    func startJam() async throws -> JamSession

    /// End the current Jam session. Throws sessionNotActive if no active session.
    func endJam() async throws

    /// Connect a Spotify account via SPTSessionManager OAuth.
    /// Reads SPTClientID and SPTRedirectURL from Info.plist.
    func connectSpotify() async throws

    /// Whether a valid Spotify token is available.
    var isSpotifyConnected: Bool { get }

    /// Whether the Spotify app is installed on this device.
    var isSpotifyInstalled: Bool { get }
}
```

**Spotify iOS SDK integration** (SpotifyiOS 1.2.3):

- `SPTConfiguration(clientID:redirectURL:)` — reads from Info.plist keys `SPTClientID` / `SPTRedirectURL`
- `SPTSessionManager` — OAuth via Spotify app (`.clientOnly`); scope: `.appRemoteControl`
- Delegate callbacks (`SPTSessionManagerDelegate`) bridge to `withCheckedThrowingContinuation`
- `SPTAppRemote` — IPC to Spotify app; `startGroupSession` returns `SPTAppRemoteGroupSession.joinSessionURI`
- URL routing: `SonasApp.onOpenURL` posts `Notification.Name.spotifyOpenURL`; service observes and forwards to
  `sessionManager.application(_:open:options:)`
- Jam join URL format: `spotify://jam/{token}` deep link (returned by `SPTAppRemoteGroupSession.joinSessionURI`)

**QR Code generation** (in `JamPanelView`, not in service):

```swift
let filter = CIFilter.qrCodeGenerator()
filter.message = Data(joinURL.absoluteString.utf8)
filter.correctionLevel = "M"
let outputImage = filter.outputImage!.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
```

**Error cases**:

- `JamServiceError.spotifyNotInstalled` — `isSpotifyInstalled == false`; panel shows App Store deep-link prompt.
- `JamServiceError.spotifyAuthFailed(Error)` — `SPTSessionManager` OAuth failure.
- `JamServiceError.sessionStartFailed(Error)` — `SPTAppRemote` connection or group session creation failure.
- `JamServiceError.sessionNotActive` — `endJam()` called with no active session.
- `JamServiceError.missingConfiguration(String)` — `SPTClientID` or `SPTRedirectURL` absent from Info.plist.

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
