import CoreLocation
@testable import Sonas
import SwiftUI
import Testing

@Suite("View+PointerInteraction Unit Tests")
@MainActor
struct PointerInteractionTests {
    @Test
    func `location card context menu nil coordinate does not crash`() {
        // When coordinate is nil the contextMenu renders no items.
        // This verifies the nil branch compiles and doesn't trap at view construction.
        let view = Text("Member").locationCardContextMenu(memberName: "Alice", coordinate: nil)
        _ = view
    }

    @Test
    func `location card context menu with coordinate does not crash`() {
        let coord = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        let view = Text("Member").locationCardContextMenu(memberName: "Bob", coordinate: coord)
        _ = view
    }

    @Test
    func `event row context menu does not crash`() {
        let event = CalendarEvent(
            id: "test-1",
            title: "Team Standup",
            startDate: .now,
            endDate: .now.addingTimeInterval(3600),
            isAllDay: false,
            calendarName: "Work",
            source: .iCloud,
            attendees: [],
            calendarColorHex: nil
        )
        let view = Text("Event").eventRowContextMenu(event: event)
        _ = view
    }
}
