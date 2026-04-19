import Foundation
import Observation

// MARK: - DashboardViewModel (T040)

@Observable
@MainActor
final class DashboardViewModel {
    // MARK: Sub-ViewModels (injected for testability)

    let locationVM: LocationViewModel
    let eventsVM: EventsViewModel

    // MARK: State

    private(set) var isShowingSettings: Bool = false

    init(
        locationService: any LocationServiceProtocol,
        calendarService: any CalendarServiceProtocol,
    ) {
        locationVM = LocationViewModel(service: locationService)
        eventsVM = EventsViewModel(service: calendarService)
    }

    // MARK: - Convenience factory

    static func makeDefault() -> DashboardViewModel {
        let useMockLocation = ProcessInfo.processInfo.environment["USE_MOCK_LOCATION"] == "1"
        let useMockCalendar = ProcessInfo.processInfo.environment["USE_MOCK_CALENDAR"] == "1"

        return DashboardViewModel(
            locationService: useMockLocation ? LocationServiceMock() : LocationService(),
            calendarService: useMockCalendar ? CalendarServiceMock() : CalendarService(),
        )
    }

    // MARK: - Settings

    func showSettings() {
        isShowingSettings = true
    }

    func hideSettings() {
        isShowingSettings = false
    }

    // MARK: - Dashboard-level refresh

    func refreshAll() async {
        async let locationRefresh: () = eventsVM.refresh()
        async let calendarRefresh: () = locationVM.refresh()
        _ = await (locationRefresh, calendarRefresh)
    }
}
