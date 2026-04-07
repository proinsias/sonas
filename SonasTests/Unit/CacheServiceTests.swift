import Testing
import Foundation
import SwiftData
@testable import Sonas

// MARK: - CacheServiceTests (T085)

@Suite("Cache Service Unit Tests")
struct CacheServiceTests {

    private func makeInMemoryService() throws -> CacheService {
        let schema = Schema([
            CachedWeatherSnapshot.self, CachedLocationSnapshot.self,
            CachedCalendarEvent.self, CachedTask.self, CachedJamSession.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return CacheService(container: container)
    }

    // MARK: - T085.1: loadWeather returns nil after TTL eviction

    @Test("given weather saved more than 1h ago when evictStaleEntries called then loadWeather returns nil")
    func given_staleWeather_when_evicted_then_loadWeatherNil() async throws {
        let sut = try makeInMemoryService()
        let staleSnapshot = WeatherSnapshot(
            temperature: 15.0, feelsLike: 13.0, conditionDescription: "Clear", conditionSymbolName: "sun.max.fill",
            humidity: 0.5, windSpeed: 10.0, windDirection: 180.0, windCompassLabel: "S",
            pressure: 1010.0, pressureTrend: .steady, airQualityIndex: nil, aiqCategory: nil,
            sunriseTime: Date(timeIntervalSinceNow: -43200), sunsetTime: Date(timeIntervalSinceNow: 0),
            moonPhase: .newMoon, fetchedAt: Date(timeIntervalSinceNow: -7200)  // 2 hours ago
        )
        try await sut.saveWeather(staleSnapshot, forecast: [])
        try await sut.evictStaleEntries()
        let loaded = await sut.loadWeather()
        #expect(loaded == nil, "Stale weather (>1h old fetchedAt) must be evicted")
    }

    // MARK: - T085.2: Location staleness thresholds

    @Test("given fresh location snapshot then isStale is false")
    func given_freshSnapshot_then_notStale() {
        let snapshot = LocationSnapshot(
            coordinate: .init(latitude: 53.3, longitude: -6.2),
            placeName: "Dublin",
            recordedAt: Date.now.addingTimeInterval(-60)  // 1 minute ago
        )
        #expect(!snapshot.isStale, "Snapshot recorded 1 minute ago must not be stale")
        #expect(snapshot.staleness == .fresh, "Must be .fresh")
    }

    @Test("given location snapshot 10 minutes old then staleness is stale")
    func given_10MinuteOldSnapshot_then_stale() {
        let snapshot = LocationSnapshot(
            coordinate: .init(latitude: 53.3, longitude: -6.2),
            placeName: "Dublin",
            recordedAt: Date.now.addingTimeInterval(-600)  // 10 minutes ago
        )
        #expect(snapshot.isStale, "Snapshot recorded 10 minutes ago must be stale")
        #expect(snapshot.staleness == .stale, "Must be .stale (between 5 and 30 min)")
    }

    @Test("given location snapshot 35 minutes old then staleness is veryStale")
    func given_35MinuteOldSnapshot_then_veryStale() {
        let snapshot = LocationSnapshot(
            coordinate: .init(latitude: 53.3, longitude: -6.2),
            placeName: "Dublin",
            recordedAt: Date.now.addingTimeInterval(-2100)  // 35 minutes ago
        )
        #expect(snapshot.staleness == .veryStale, "Must be .veryStale (>30 min)")
        #expect(snapshot.ageLabel == "Location unavailable", "Very stale ageLabel must be 'Location unavailable'")
    }
}
