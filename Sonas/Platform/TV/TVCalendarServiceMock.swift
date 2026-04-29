import Foundation

// MARK: - TVCalendarServiceMock

@MainActor
final class TVCalendarServiceMock: TVCalendarServiceProtocol, @unchecked Sendable {
    private(set) var isGoogleConnected: Bool = true
    private(set) var needsReauth: Bool = false

    func fetchUpcomingEvents(hours _: Int = 48) async throws -> [CalendarEvent] {
        Self.fixtures
    }

    static var fixtures: [CalendarEvent] {
        let now = Date.now
        return [
            CalendarEvent(
                id: "tv-mock-1",
                title: "Family Dinner",
                startDate: now.addingTimeInterval(3 * 3600),
                endDate: now.addingTimeInterval(5 * 3600),
                isAllDay: false,
                calendarName: "Family",
                source: .iCloud,
                attendees: ["Alice", "Bob"],
                calendarColorHex: "#4A90E2"
            ),
            CalendarEvent(
                id: "tv-mock-2",
                title: "School Run",
                startDate: now.addingTimeInterval(8 * 3600),
                endDate: now.addingTimeInterval(9 * 3600),
                isAllDay: false,
                calendarName: "Personal",
                source: .google,
                attendees: [],
                calendarColorHex: "#34A853"
            )
        ]
    }
}
