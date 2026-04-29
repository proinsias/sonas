# Contract: TVSpotifyReadServiceProtocol

**Service**: `TVSpotifyReadService` (tvOS only)  
**Protocol**: `TVSpotifyReadServiceProtocol`  
**Test file**: `SonasTests/TVSpotifyReadServiceTests.swift`

## Responsibility

Display-only Spotify integration for tvOS. Polls the Spotify Web API `GET /v1/me/player/currently-playing` at 30-second
intervals to show the track currently playing in the household's Spotify session. No playback control. No SpotifyiOS SDK
dependency.

## Contract Scenarios

### Scenario 1 — Authenticated, track playing: returns current track

**Given** a valid Spotify access token is cached and a track is currently playing  
**When** `fetchCurrentlyPlaying()` is called  
**Then**

- Returns a non-nil `TVCurrentTrack` with non-empty `title`, `artistName`, and valid `albumArtURL`
- `isPlaying` is `true`
- `isAuthenticated` is `true`

```swift
// given_authenticated_trackPlaying_when_fetchCurrentlyPlaying_then_returnsTrack
func test_given_authenticated_trackPlaying_when_fetchCurrentlyPlaying_then_returnsTrack() async throws {
    let sut = TVSpotifyReadService(session: MockURLSession.stub(response: Fixtures.currentlyPlayingJSON))
    let track = try await sut.fetchCurrentlyPlaying()
    XCTAssertNotNil(track)
    XCTAssertFalse(track!.title.isEmpty)
    XCTAssertTrue(track!.isPlaying)
}
```

---

### Scenario 2 — Authenticated, nothing playing: returns nil

**Given** a valid Spotify access token is cached and nothing is playing (204 No Content or `is_playing: false`)  
**When** `fetchCurrentlyPlaying()` is called  
**Then**

- Returns `nil` (not an error)
- `isAuthenticated` is `true`
- Caller renders the idle/placeholder state

```swift
// given_authenticated_nothingPlaying_when_fetchCurrentlyPlaying_then_returnsNil
func test_given_authenticated_nothingPlaying_when_fetchCurrentlyPlaying_then_returnsNil() async throws {
    let sut = TVSpotifyReadService(session: MockURLSession.stub(statusCode: 204))
    let track = try await sut.fetchCurrentlyPlaying()
    XCTAssertNil(track)
    XCTAssertTrue(sut.isAuthenticated)
}
```

---

### Scenario 3 — Unauthenticated: returns nil, isAuthenticated false, does not throw

**Given** no Spotify access token is cached  
**When** `fetchCurrentlyPlaying()` is called  
**Then**

- Returns `nil` without throwing
- `isAuthenticated` is `false`
- No network request is made

```swift
// given_notAuthenticated_when_fetchCurrentlyPlaying_then_returnsNilAndNoRequest
func test_given_notAuthenticated_when_fetchCurrentlyPlaying_then_returnsNilAndNoRequest() async throws {
    let mockSession = MockURLSession.recording()
    let sut = TVSpotifyReadService(session: mockSession, tokenStore: .empty)
    let track = try await sut.fetchCurrentlyPlaying()
    XCTAssertNil(track)
    XCTAssertFalse(sut.isAuthenticated)
    XCTAssertEqual(mockSession.requestCount, 0)
}
```
