@testable import Sonas
import SwiftData
import XCTest

// MARK: - PerformanceTests (T090)

// Constitution §IV — performance baselines MUST be verified in task checklist.

@MainActor
final class PerformanceTests: XCTestCase {
    // MARK: - T090.1: Cached-data dashboard render ≤ 500ms

    func test_cachedDataDashboardRender_isWithin500ms() async throws {
        // Arrange: pre-populate CacheService with fixture data
        let schema = Schema([
            CachedWeatherSnapshot.self, CachedLocationSnapshot.self,
            CachedCalendarEvent.self, CachedTask.self, CachedJamSession.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let cache = CacheService(container: container)
        try await cache.saveLocations(LocationServiceMock.fixtures)

        // Act: measure DashboardViewModel initialisation + mock data load
        let start = Date()
        let vm = DashboardViewModel(
            locationService: LocationServiceMock(),
            calendarService: CalendarServiceMock()
        )
        await vm.locationVM.start()
        await vm.eventsVM.load()
        let elapsed = Date().timeIntervalSince(start)

        // Assert: Constitution §IV: ≤500ms
        XCTAssertLessThan(elapsed, 0.5, "Dashboard render must complete within 500ms")
    }

    // MARK: - T090.2: WeatherViewModel cache-load path ≤ 500ms

    func test_weatherViewModelCacheLoad_isWithin500ms() async {
        let start = Date()
        let vm = WeatherViewModel(service: WeatherServiceMock())
        await vm.start()
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertLessThan(elapsed, 0.5, "Weather view model load must complete within 500ms")
    }

    // MARK: - T090.3: UI transition ≤ 100ms (JamViewModel state transition)

    func test_jamStateTransition_isWithin100ms() async {
        let start = Date()
        let vm = JamViewModel(service: JamServiceMock())
        _ = try? await vm.startJam()
        await vm.endJam()
        let elapsed = Date().timeIntervalSince(start)

        // Constitution §IV: ≤100ms UI interaction
        XCTAssertLessThan(elapsed, 0.1, "Jam state transition must complete within 100ms")
    }
}
