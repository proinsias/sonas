import Foundation
import Sonas
import XCTest

@MainActor
final class MockGoogleCalendarClient: @unchecked Sendable {
    private let events: [CalendarEvent]
    private let shouldThrow: CalendarServiceError?
    private let isExpiredToken: Bool

    init(events: [CalendarEvent] = [], shouldThrow: CalendarServiceError? = nil, isExpiredToken: Bool = false) {
        self.events = events
        self.shouldThrow = shouldThrow
        self.isExpiredToken = isExpiredToken
    }

    static func stub(events: [CalendarEvent]) -> MockGoogleCalendarClient {
        MockGoogleCalendarClient(events: events)
    }

    static func unauthenticated() -> MockGoogleCalendarClient {
        MockGoogleCalendarClient(shouldThrow: .googleAuthFailed(NSError(domain: "test", code: 401)))
    }

    static func networkError() -> MockGoogleCalendarClient {
        MockGoogleCalendarClient(shouldThrow: .fetchFailed(NSError(domain: "test", code: -1)))
    }

    static func expiredToken() -> MockGoogleCalendarClient {
        MockGoogleCalendarClient(
            shouldThrow: .googleAuthFailed(NSError(domain: "test", code: 401)),
            isExpiredToken: true
        )
    }
}

extension MockGoogleCalendarClient: TVCalendarClientProtocol {
    func fetchEvents(from start: Date, to end: Date) async throws -> [CalendarEvent] {
        if let err = shouldThrow {
            throw err
        }
        return events.filter { $0.startDate >= start && $0.startDate < end }
    }
}

// MARK: - TVCalendarServiceTests

@MainActor
final class TVCalendarServiceTests: XCTestCase {
    /// Scenario 1: given_googleConnected_when_fetchUpcomingEvents_then_returnsSortedEvents
    func test_given_googleConnected_when_fetchUpcomingEvents_then_returnsSortedEvents() async throws {
        let mockEvents = [
            CalendarEvent(
                id: "evt-2",
                title: "Later Event",
                startDate: Date().addingTimeInterval(86400),
                endDate: Date().addingTimeInterval(90000),
                isAllDay: false,
                calendarName: "Family",
                source: .google,
                attendees: [],
                calendarColorHex: "#4A90E2",
            ),
            CalendarEvent(
                id: "evt-1",
                title: "First Event",
                startDate: Date().addingTimeInterval(3600),
                endDate: Date().addingTimeInterval(7200),
                isAllDay: false,
                calendarName: "Family",
                source: .google,
                attendees: [],
                calendarColorHex: "#4A90E2"
            )
        ]
        let client = MockGoogleCalendarClient.stub(events: mockEvents)
        let sut = TVCalendarService(client: client)

        let result = try await sut.fetchUpcomingEvents(hours: 48)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.title, "First Event")
        XCTAssertTrue(sut.isGoogleConnected)
        XCTAssertFalse(sut.needsReauth)
    }

    /// Scenario 2: given_notAuthenticated_when_fetchUpcomingEvents_then_throwsAuthError
    func test_given_notAuthenticated_when_fetchUpcomingEvents_then_throwsAuthError() async {
        let client = MockGoogleCalendarClient.unauthenticated()
        let sut = TVCalendarService(client: client)

        do {
            _ = try await sut.fetchUpcomingEvents(hours: 48)
            XCTFail("Expected throw")
        } catch is CalendarServiceError {
            // Expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }

        XCTAssertFalse(sut.isGoogleConnected)
    }

    /// Scenario 3: given_networkError_when_fetchUpcomingEvents_then_throwsFetchFailed
    func test_given_networkError_when_fetchUpcomingEvents_then_throwsFetchFailed() async {
        let client = MockGoogleCalendarClient.networkError()
        let sut = TVCalendarService(client: client)

        do {
            _ = try await sut.fetchUpcomingEvents(hours: 48)
            XCTFail("Expected throw")
        } catch CalendarServiceError.fetchFailed {
            // Expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    /// Scenario 4: given_tokenExpired_when_fetchUpcomingEvents_then_needsReauthIsTrue
    func test_given_tokenExpired_when_fetchUpcomingEvents_then_needsReauthIsTrue() async {
        let client = MockGoogleCalendarClient.expiredToken()
        let sut = TVCalendarService(client: client)

        do {
            _ = try await sut.fetchUpcomingEvents(hours: 48)
            XCTFail("Expected throw")
        } catch {
            // Expected
        }

        XCTAssertTrue(sut.needsReauth)
    }
}
