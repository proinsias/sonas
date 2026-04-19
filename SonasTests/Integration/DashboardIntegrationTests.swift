@testable import Sonas
import SwiftUI
import Testing

// MARK: - DashboardIntegrationTests (T043)

// All-mock service injection — verifies US1 panels render within 500ms and
// degraded state ("Location unavailable") renders correctly.

@Suite("Dashboard Integration Tests")
struct DashboardIntegrationTests {
    // MARK: - T043.1: All panels render with mock services within 500ms

    @Test
    func `given all mock services when dashboard loads then all US1 panels render within 500ms`() async {
        let start = Date.now

        let vm = DashboardViewModel(
            locationService: LocationServiceMock(),
            calendarService: CalendarServiceMock(),
        )

        await vm.locationVM.start()
        await vm.eventsVM.load()

        let elapsed = Date.now.timeIntervalSince(start)

        #expect(elapsed < 0.5, "Dashboard mock load must complete within 500ms (SC-002); took \(elapsed)s")
        #expect(!vm.locationVM.members.isEmpty, "Location panel must have members from mock")
        #expect(!vm.eventsVM.events.isEmpty, "Events panel must have events from mock")
    }

    // MARK: - T043.2: "Location unavailable" renders when mock returns nil location

    @Test
    func `given member with nil location when dashboard loads then location unavailable indicator shown`() async {
        let vm = DashboardViewModel(
            locationService: LocationServiceMock(),
            calendarService: CalendarServiceMock(),
        )

        await vm.locationVM.start()

        // LocationServiceMock.fixtures includes Carol with nil location (see LocationServiceMock.swift)
        let carolMember = vm.locationVM.members.first { $0.displayName == "Carol" }
        #expect(carolMember != nil, "Carol fixture member must be present")
        #expect(carolMember?.isStale == true, "Carol's location must be stale/nil")
    }

    // MARK: - T043.3: Empty calendar events → "Nothing scheduled" state

    @Test
    func `given no upcoming events when events panel loads then shows empty state`() async {
        final class EmptyCalendarMock: CalendarServiceProtocol, @unchecked Sendable {
            var isGoogleConnected: Bool = false
            var needsGoogleReconnect: Bool = false
            func fetchUpcomingEvents(hours _: Int) async throws -> [CalendarEvent] {
                []
            }

            func connectGoogleAccount() async throws {}
            func disconnectGoogleAccount() async {}
        }

        let vm = EventsViewModel(service: EmptyCalendarMock())
        await vm.load()

        #expect(vm.events.isEmpty, "Events array must be empty for empty calendar mock")
        #expect(vm.error == nil, "No error should be set for empty but successful fetch")
    }
}
