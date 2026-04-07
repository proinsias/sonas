import XCTest
import SwiftData
@testable import Sonas

// MARK: - PerformanceTests (T090)
// Constitution §IV — performance baselines MUST be verified in task checklist.
// Uses XCTestCase.measure{} for baseline recording.

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
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        measure(options: options) {
            let exp = expectation(description: "load")
            Swift.Task { @MainActor in
                let vm = DashboardViewModel(
                    locationService: LocationServiceMock(),
                    calendarService: CalendarServiceMock()
                )
                await vm.locationVM.start()
                await vm.eventsVM.load()
                exp.fulfill()
            }
            wait(for: [exp], timeout: 0.5)  // Constitution §IV: ≤500ms
        }
    }

    // MARK: - T090.2: WeatherViewModel cache-load path ≤ 500ms

    func test_weatherViewModelCacheLoad_isWithin500ms() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        measure(options: options) {
            let exp = expectation(description: "weather load")
            Swift.Task { @MainActor in
                let vm = WeatherViewModel(service: WeatherServiceMock())
                await vm.start()
                exp.fulfill()
            }
            wait(for: [exp], timeout: 0.5)
        }
    }

    // MARK: - T090.3: UI transition ≤ 100ms (JamViewModel state transition)

    func test_jamStateTransition_isWithin100ms() {
        let options = XCTMeasureOptions()
        options.iterationCount = 10
        measure(options: options) {
            let exp = expectation(description: "jam transition")
            Swift.Task { @MainActor in
                let vm = JamViewModel(service: JamServiceMock())
                await vm.startJam()
                await vm.endJam()
                exp.fulfill()
            }
            wait(for: [exp], timeout: 0.1)  // Constitution §IV: ≤100ms UI interaction
        }
    }
}
