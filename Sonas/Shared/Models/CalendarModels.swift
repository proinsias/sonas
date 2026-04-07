import Foundation

// MARK: - CalendarEvent

/// A single calendar event from either iCloud (EventKit) or Google Calendar REST.
struct CalendarEvent: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarName: String
    let source: CalendarSource
    /// Display names of attendees/invitees (may be empty for personal events)
    let attendees: [String]
    /// Colour hex string from the originating calendar (e.g., "#4A90E2")
    let calendarColorHex: String?
}

// MARK: - CalendarSource

/// The data source for a calendar event.
enum CalendarSource: String, Sendable, Equatable {
    case iCloud  = "iCloud"
    case google  = "Google"
}

// MARK: - Convenience computed properties

extension CalendarEvent {
    var isUpcoming: Bool {
        endDate > .now
    }

    var formattedTime: String {
        if isAllDay { return "All day" }
        return startDate.formatted(.dateTime.hour().minute())
    }

    var formattedDateRange: String {
        if isAllDay { return startDate.formatted(.dateTime.weekday(.wide).month().day()) }
        return startDate.formatted(.dateTime.weekday(.abbreviated).hour().minute())
    }
}
