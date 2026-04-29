# Contract: TVCalendarServiceProtocol

**Service**: `TVCalendarService` (tvOS only)  
**Protocol**: `TVCalendarServiceProtocol`  
**Test file**: `SonasTests/TVCalendarServiceTests.swift`

## Responsibility

Fetch upcoming calendar events on tvOS using Google Calendar REST v3 only. EventKit is not available on tvOS. This
service wraps the existing `GoogleCalendarClient` and applies identical error handling and retry semantics to the iOS
`CalendarService`, but omits all EventKit paths.

## Contract Scenarios

### Scenario 1 — Authenticated fetch returns upcoming events

**Given** a valid Google OAuth token is stored for this device  
**When** `fetchUpcomingEvents(hours: 48)` is called  
**Then**

- Returns an array of `CalendarEvent` objects sorted ascending by `startDate`
- Each event has a non-empty `title` and a valid `startDate`
- `isGoogleConnected` is `true`
- `needsReauth` is `false`

```swift
// given_googleConnected_when_fetchUpcomingEvents_then_returnsSortedEvents
func test_given_googleConnected_when_fetchUpcomingEvents_then_returnsSortedEvents() async throws {
    let sut = TVCalendarService(client: MockGoogleCalendarClient.stub(events: mockEvents))
    let result = try await sut.fetchUpcomingEvents(hours: 48)
    XCTAssertTrue(result.count > 0)
    XCTAssertEqual(result, result.sorted { $0.startDate < $1.startDate })
}
```

---

### Scenario 2 — Unauthenticated: graceful disabled state

**Given** no Google OAuth token is stored (first launch or signed-out state)  
**When** `fetchUpcomingEvents(hours: 48)` is called  
**Then**

- Throws `CalendarServiceError.googleAuthFailed` (or a dedicated `.notAuthenticated` case)
- `isGoogleConnected` is `false`
- Does NOT crash or return partial data

```swift
// given_notAuthenticated_when_fetchUpcomingEvents_then_throwsAuthError
func test_given_notAuthenticated_when_fetchUpcomingEvents_then_throwsAuthError() async {
    let sut = TVCalendarService(client: MockGoogleCalendarClient.unauthenticated())
    await XCTAssertThrowsErrorAsync(try await sut.fetchUpcomingEvents(hours: 48)) { error in
        XCTAssertTrue(error is CalendarServiceError)
    }
    XCTAssertFalse(sut.isGoogleConnected)
}
```

---

### Scenario 3 — Network error: propagates error, does not cache partial data

**Given** a valid Google token but the network request fails  
**When** `fetchUpcomingEvents(hours: 48)` is called  
**Then**

- Throws `CalendarServiceError.fetchFailed`
- Previously returned events are not altered (caller's responsibility to retain cache)

```swift
// given_networkError_when_fetchUpcomingEvents_then_throwsFetchFailed
func test_given_networkError_when_fetchUpcomingEvents_then_throwsFetchFailed() async {
    let sut = TVCalendarService(client: MockGoogleCalendarClient.networkError())
    await XCTAssertThrowsErrorAsync(try await sut.fetchUpcomingEvents(hours: 48)) { error in
        guard case CalendarServiceError.fetchFailed = error else { return XCTFail("Wrong error") }
    }
}
```

---

### Scenario 4 — Token expired: `needsReauth` set true, caller can re-trigger device flow

**Given** the stored Google OAuth token has expired (server returns 401)  
**When** `fetchUpcomingEvents(hours: 48)` is called  
**Then**

- Throws `CalendarServiceError.googleAuthFailed`
- `needsReauth` transitions to `true`

```swift
// given_tokenExpired_when_fetchUpcomingEvents_then_needsReauthIsTrue
func test_given_tokenExpired_when_fetchUpcomingEvents_then_needsReauthIsTrue() async {
    let sut = TVCalendarService(client: MockGoogleCalendarClient.expiredToken())
    await XCTAssertThrowsErrorAsync(try await sut.fetchUpcomingEvents(hours: 48))
    XCTAssertTrue(sut.needsReauth)
}
```
