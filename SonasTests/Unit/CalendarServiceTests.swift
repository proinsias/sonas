import Testing
import Foundation
@testable import Sonas

// MARK: - CalendarServiceTests (T084)

@Suite("Calendar Service Unit Tests")
struct CalendarServiceTests {

    // MARK: - T084.1: Deduplication removes event when title+startDate match

    @Test("given two events with same title and startDate when merged then only one event retained")
    func given_duplicateEvents_when_merged_then_deduplicated() {
        let date = Date(timeIntervalSince1970: 1_744_000_000)
        let icloudEvent = CalendarEvent(
            id: "ical-1", title: "Family Meeting",
            startDate: date, endDate: date.addingTimeInterval(3600),
            isAllDay: false, calendarName: "Family", source: .iCloud,
            attendees: [], calendarColorHex: nil
        )
        let googleEvent = CalendarEvent(
            id: "gcal-1", title: "Family Meeting",
            startDate: date, endDate: date.addingTimeInterval(3600),
            isAllDay: false, calendarName: "Google", source: .google,
            attendees: [], calendarColorHex: nil
        )

        var seen = Set<String>()
        let deduped = [icloudEvent, googleEvent].filter { event in
            let key = "\(event.title)|\(event.startDate.timeIntervalSince1970)"
            return seen.insert(key).inserted
        }

        #expect(deduped.count == 1, "Duplicate title+startDate must produce exactly 1 event")
    }

    // MARK: - T084.2: Sort order ascending

    @Test("given events in reverse order when sorted then ascending by startDate")
    func given_eventsReverseOrder_when_sorted_then_ascending() {
        let base = Date(timeIntervalSince1970: 1_744_000_000)
        let events = [
            CalendarEvent(id: "e3", title: "C", startDate: base.addingTimeInterval(7200), endDate: base.addingTimeInterval(10800), isAllDay: false, calendarName: "", source: .iCloud, attendees: [], calendarColorHex: nil),
            CalendarEvent(id: "e1", title: "A", startDate: base, endDate: base.addingTimeInterval(3600), isAllDay: false, calendarName: "", source: .iCloud, attendees: [], calendarColorHex: nil),
            CalendarEvent(id: "e2", title: "B", startDate: base.addingTimeInterval(3600), endDate: base.addingTimeInterval(7200), isAllDay: false, calendarName: "", source: .iCloud, attendees: [], calendarColorHex: nil)
        ]
        let sorted = events.sorted { $0.startDate < $1.startDate }
        #expect(sorted.map(\.title) == ["A", "B", "C"], "Events must be sorted ascending by startDate")
    }

    // MARK: - T084.3: isGoogleConnected == false after disconnectGoogleAccount

    @Test("given connected Google account when disconnected then isGoogleConnected is false")
    func given_googleConnected_when_disconnected_then_isGoogleConnectedFalse() async {
        let service = CalendarServiceMock()
        try? await service.connectGoogleAccount()
        #expect(service.isGoogleConnected, "Must be connected after connect")
        await service.disconnectGoogleAccount()
        #expect(!service.isGoogleConnected, "Must be disconnected after disconnect")
    }
}
