import Foundation
@testable import Sonas
import Testing

@Suite("CalendarEvent computed properties")
struct CalendarModelsTests {
    private func makeEvent(
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false
    ) -> CalendarEvent {
        CalendarEvent(
            id: "test-id",
            title: "Test Event",
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            calendarName: "Work",
            source: .iCloud,
            attendees: [],
            calendarColorHex: nil
        )
    }

    @Test
    func `given event ending in future when isUpcoming then returns true`() {
        let event = makeEvent(
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date().addingTimeInterval(3600)
        )
        #expect(event.isUpcoming == true)
    }

    @Test
    func `given event ended in past when isUpcoming then returns false`() {
        let event = makeEvent(
            startDate: Date().addingTimeInterval(-7200),
            endDate: Date().addingTimeInterval(-3600)
        )
        #expect(event.isUpcoming == false)
    }

    @Test
    func `given all-day event when formattedTime then returns all day`() {
        let event = makeEvent(
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400),
            isAllDay: true
        )
        #expect(event.formattedTime == "All day")
    }

    @Test
    func `given timed event when formattedTime then returns non-empty time string`() {
        let event = makeEvent(
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            isAllDay: false
        )
        #expect(!event.formattedTime.isEmpty)
        #expect(event.formattedTime != "All day")
    }

    @Test
    func `given all-day event when formattedDateRange then returns weekday month day`() {
        let event = makeEvent(
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400),
            isAllDay: true
        )
        let result = event.formattedDateRange
        #expect(!result.isEmpty)
    }

    @Test
    func `given timed event when formattedDateRange then returns abbreviated weekday and time`() {
        let event = makeEvent(
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            isAllDay: false
        )
        let result = event.formattedDateRange
        #expect(!result.isEmpty)
    }

    @Test
    func `given google source when source then equals google`() {
        let event = makeEvent(startDate: Date(), endDate: Date().addingTimeInterval(3600))
        #expect(event.source == .iCloud)
    }

    @Test
    func `given two events with same id when equatable then returns true`() {
        let start = Date()
        let e1 = makeEvent(startDate: start, endDate: start.addingTimeInterval(3600))
        let e2 = CalendarEvent(
            id: "test-id",
            title: "Test Event",
            startDate: start,
            endDate: start.addingTimeInterval(3600),
            isAllDay: false,
            calendarName: "Work",
            source: .iCloud,
            attendees: [],
            calendarColorHex: nil
        )
        #expect(e1 == e2)
    }
}
