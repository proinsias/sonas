import Foundation
import Network
import Observation

@Observable
final class MenuBarState: Sendable {
    private(set) var familyLocations: [FamilyMember] = []
    private(set) var nextEvent: CalendarEvent?
    private(set) var weatherSummary: WeatherSnapshot?
    private(set) var lastUpdated: Date?
    var isOffline: Bool = false

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "MenuBarStateMonitor")

    @MainActor
    func refresh() async {
        let cache = CacheService.shared
        async let locations = cache.loadLocations()
        async let events = cache.loadEvents()
        async let weather = cache.loadWeather()

        let (fetchedLocations, fetchedEvents, fetchedWeather) = await (locations, events, weather)

        // Only update if we have data, or keep old cached data if offline
        if !fetchedLocations.isEmpty { familyLocations = fetchedLocations }
        if fetchedWeather != nil { weatherSummary = fetchedWeather }

        // Compute nextEvent: first event with startDate > now within 24 hours
        let now = Date.now
        let upcoming = fetchedEvents
            .filter { $0.startDate > now && $0.startDate < now.addingTimeInterval(86400) }
            .sorted { $0.startDate < $1.startDate }

        if !upcoming.isEmpty {
            nextEvent = upcoming.first
        }

        lastUpdated = now
    }

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOffline = (path.status != .satisfied)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    deinit {
        monitor.cancel()
    }
}
