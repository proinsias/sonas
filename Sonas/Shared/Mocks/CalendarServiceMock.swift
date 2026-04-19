import Foundation

// MARK: - CalendarServiceMock (T029)

// Returns fixture CalendarEvent data.
// Active when USE_MOCK_CALENDAR=1 environment variable is set.

final class CalendarServiceMock: CalendarServiceProtocol, @unchecked Sendable {
    private(set) var isGoogleConnected: Bool = true
    private(set) var needsGoogleReconnect: Bool = false

    func fetchUpcomingEvents(hours _: Int = 48) async throws -> [CalendarEvent] {
        Self.fixtures
    }

    func connectGoogleAccount() async throws {
        isGoogleConnected = true
        needsGoogleReconnect = false
    }

    func disconnectGoogleAccount() async {
        isGoogleConnected = false
    }

    // MARK: Fixtures

    static let fixtures: [CalendarEvent] = [
        CalendarEvent(
            id: "mock-event-1",
            title: "Family Dinner",
            startDate: Calendar.current.date(byAdding: .hour, value: 3, to: .now)!,
            endDate: Calendar.current.date(byAdding: .hour, value: 5, to: .now)!,
            isAllDay: false,
            calendarName: "Family",
            source: .iCloud,
            attendees: ["Alice", "Bob", "Carol"],
            calendarColorHex: "#4A90E2",
        ),
        CalendarEvent(
            id: "mock-event-2",
            title: "School Run",
            startDate: Calendar.current.date(byAdding: .hour, value: 8, to: .now)!,
            endDate: Calendar.current.date(byAdding: .hour, value: 9, to: .now)!,
            isAllDay: false,
            calendarName: "Personal",
            source: .google,
            attendees: [],
            calendarColorHex: "#34A853",
        ),
        CalendarEvent(
            id: "mock-event-3",
            title: "Weekend Hiking",
            startDate: Calendar.current.date(byAdding: .day, value: 1, to: .now)!,
            endDate: Calendar.current.date(byAdding: .day, value: 1, to: .now)!
                .addingTimeInterval(14400),
            isAllDay: false,
            calendarName: "Family",
            source: .iCloud,
            attendees: ["Alice", "Bob"],
            calendarColorHex: "#4A90E2",
        ),
    ]
}
