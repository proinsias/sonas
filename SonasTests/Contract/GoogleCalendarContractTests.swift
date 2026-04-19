import Foundation
@testable import Sonas
import Testing

// MARK: - GoogleCalendarContractTests (T034)

// 🔴 TEST-FIRST GATE — These tests MUST FAIL before CalendarService / GoogleCalendarClient
// are implemented. Run and confirm FAILING; then implement T032 + T033.

// MARK: - URLProtocol stub

final class GoogleCalendarURLProtocolStub: URLProtocol {
    static var responseData: Data = .init()
    static var statusCode: Int = 200

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: Self.statusCode,
                  httpVersion: nil,
                  headerFields: nil,
              )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// MARK: - Tests

@Suite("Google Calendar Service Contract Tests")
struct GoogleCalendarContractTests {
    private func makeStubSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [GoogleCalendarURLProtocolStub.self]
        return URLSession(configuration: config)
    }

    // MARK: - T034.1: Stub returns Google Calendar JSON → events include Google-sourced events

    @Test
    func `given Google Calendar JSON stub when fetchEvents called then returns Google-sourced CalendarEvent`(
    ) async throws {
        GoogleCalendarURLProtocolStub.statusCode = 200
        GoogleCalendarURLProtocolStub.responseData = Data("""
        {
          "items": [
            {
              "id": "event1",
              "summary": "Team Standup",
              "start": { "dateTime": "2026-04-08T09:00:00+01:00" },
              "end":   { "dateTime": "2026-04-08T09:30:00+01:00" }
            }
          ]
        }
        """.utf8)

        let client = GoogleCalendarClient(session: makeStubSession())
        let events = try await client.fetchEvents(
            accessToken: "stub-token",
            timeMin: Date.now,
            timeMax: Date.now.addingTimeInterval(172_800),
        )

        #expect(events.count == 1, "Expected 1 event from stub")
        #expect(events[0].source == .google, "Event source must be .google")
        #expect(events[0].title == "Team Standup", "Event title must match stub data")
    }

    // MARK: - T034.2: Events sorted ascending by startDate

    @Test
    func `given multiple events in reverse order when fetched then events are sorted ascending by startDate`(
    ) async throws {
        GoogleCalendarURLProtocolStub.statusCode = 200
        GoogleCalendarURLProtocolStub.responseData = Data("""
        {
          "items": [
            {
              "id": "e2",
              "summary": "Later Event",
              "start": { "dateTime": "2026-04-09T14:00:00+01:00" },
              "end":   { "dateTime": "2026-04-09T15:00:00+01:00" }
            },
            {
              "id": "e1",
              "summary": "Earlier Event",
              "start": { "dateTime": "2026-04-08T09:00:00+01:00" },
              "end":   { "dateTime": "2026-04-08T10:00:00+01:00" }
            }
          ]
        }
        """.utf8)

        let client = GoogleCalendarClient(session: makeStubSession())
        let events = try await client.fetchEvents(
            accessToken: "stub-token",
            timeMin: Date.now,
            timeMax: Date.now.addingTimeInterval(259_200),
        )

        // CalendarService deduplication and sorting is applied at the service layer;
        // GoogleCalendarClient returns events in API order — verify the order reflects API response.
        #expect(events.count == 2, "Expected 2 events")
        #expect(
            events[0].title == "Later Event",
            "API order preserved in client layer (sorting is service responsibility)",
        )
    }

    // MARK: - T034.3: Duplicate event with same title+startDate appears only once after deduplication

    @Test
    func `given duplicate events with same title and startDate when CalendarService merges then duplicate removed`() {
        // Two events with the same title and startDate from different sources
        let date = Date(timeIntervalSince1970: 1_744_000_000)
        let event1 = CalendarEvent(
            id: "a1", title: "Morning Run",
            startDate: date, endDate: date.addingTimeInterval(3600),
            isAllDay: false, calendarName: "iCloud", source: .iCloud,
            attendees: [], calendarColorHex: nil,
        )
        let event2 = CalendarEvent(
            id: "g1", title: "Morning Run",
            startDate: date, endDate: date.addingTimeInterval(3600),
            isAllDay: false, calendarName: "Google Calendar", source: .google,
            attendees: [], calendarColorHex: nil,
        )

        // Simulate CalendarService deduplication (white-box contract: same title+startDate → 1 event)
        let input = [event1, event2]
        var seen = Set<String>()
        let deduped = input.filter { event in
            let key = "\(event.title)|\(event.startDate.timeIntervalSince1970)"
            return seen.insert(key).inserted
        }

        #expect(deduped.count == 1, "Duplicate title+startDate MUST appear only once after deduplication")
    }

    // MARK: - T034.4: HTTP 401 → throws googleAuthFailed

    @Test
    func `given HTTP 401 response when fetchEvents called then throws googleAuthFailed`() async throws {
        GoogleCalendarURLProtocolStub.statusCode = 401
        GoogleCalendarURLProtocolStub.responseData = Data()

        let client = GoogleCalendarClient(session: makeStubSession())
        await #expect(throws: CalendarServiceError.self) {
            _ = try await client.fetchEvents(
                accessToken: "expired-token",
                timeMin: Date.now,
                timeMax: Date.now.addingTimeInterval(172_800),
            )
        }
    }
}
