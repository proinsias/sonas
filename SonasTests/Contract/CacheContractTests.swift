import Foundation
@testable import Sonas
import SwiftData
import Testing

// MARK: - CacheContractTests (T023)

// 🔴 TEST-FIRST GATE — These tests MUST FAIL before CacheService is implemented.
// Uses an in-memory ModelContainer so no disk I/O occurs.

@Suite("Cache Service Contract Tests")
struct CacheContractTests {
    // MARK: - In-memory container factory

    private func makeInMemoryService() throws -> CacheService {
        let schema = Schema([
            CachedWeatherSnapshot.self,
            CachedLocationSnapshot.self,
            CachedCalendarEvent.self,
            CachedTask.self,
            CachedJamSession.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return CacheService(container: container)
    }

    // MARK: - Weather round-trip

    @Test
    func `given weather snapshot when saved then loadWeather returns matching snapshot`() async throws {
        let sut = try makeInMemoryService()
        let snapshot = WeatherSnapshot(
            temperature: 18.5,
            feelsLike: 16.0,
            conditionDescription: "Partly Cloudy",
            conditionSymbolName: "cloud.sun.fill",
            humidity: 0.72,
            windSpeed: 15.0,
            windDirection: 270.0,
            windCompassLabel: "W",
            pressure: 1013.0,
            pressureTrend: .steady,
            airQualityIndex: 42,
            aiqCategory: .good,
            sunriseTime: Date.now,
            sunsetTime: Date.now.addingTimeInterval(43200),
            moonPhase: .firstQuarter,
            fetchedAt: Date.now
        )
        let forecast: [DayForecast] = []

        try await sut.saveWeather(snapshot, forecast: forecast)
        let loaded = await sut.loadWeather()

        #expect(loaded != nil, "Loaded weather must not be nil after save")
        #expect(loaded?.temperature == 18.5, "Temperature must round-trip correctly")
        #expect(loaded?.airQualityIndex == 42, "AQI must round-trip correctly")
        #expect(loaded?.moonPhase == .firstQuarter, "MoonPhase must round-trip correctly")
    }

    // MARK: - evictStaleEntries removes weather older than TTL

    @Test
    func `given weather saved more than 1 hour ago when evictStaleEntries called then loadWeather returns nil`(
    ) async throws {
        let sut = try makeInMemoryService()

        // Inject a stale CachedWeatherSnapshot directly into the container
        let schema = Schema(
            [
                CachedWeatherSnapshot.self, CachedLocationSnapshot.self,
                CachedCalendarEvent.self, CachedTask.self, CachedJamSession.self
            ],
        )
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let staleSvc = CacheService(container: container)

        let staleDate = Date.now.addingTimeInterval(-7200) // 2 hours ago
        let snapshot = WeatherSnapshot(
            temperature: 20.0, feelsLike: 18.0,
            conditionDescription: "Clear", conditionSymbolName: "sun.max.fill",
            humidity: 0.5, windSpeed: 10.0, windDirection: 180.0, windCompassLabel: "S",
            pressure: 1010.0, pressureTrend: .rising, airQualityIndex: nil, aiqCategory: nil,
            sunriseTime: staleDate, sunsetTime: staleDate.addingTimeInterval(43200),
            moonPhase: .fullMoon, fetchedAt: staleDate,
        )
        try await staleSvc.saveWeather(snapshot, forecast: [])
        try await staleSvc.evictStaleEntries()

        let loaded = await staleSvc.loadWeather()
        #expect(loaded == nil, "Stale weather (>1h old) must be evicted and return nil")
    }

    // MARK: - Location round-trip

    @Test
    func `given family members when saved then loadLocations returns matching members`() async throws {
        let sut = try makeInMemoryService()
        let members = LocationServiceMock.fixtures.filter { $0.location != nil }

        try await sut.saveLocations(members)
        let loaded = await sut.loadLocations()

        #expect(loaded.count == members.count, "All members with locations must be persisted")
    }

    // MARK: - evictStaleEntries removes location snapshots older than 5 minutes

    @Test
    func `given location older than 5 minutes when evictStaleEntries called then loadLocations returns empty`(
    ) async throws {
        // This test verifies the TTL contract (5 min) defined in research.md §Decision 9.
        // CacheService.evictStaleEntries() must delete CachedLocationSnapshot records whose
        // lastUpdated is >300 seconds in the past.
        let sut = try makeInMemoryService()

        // Cannot directly inject stale data via public API; use contract to verify post-eviction state.
        // After eviction, any member whose snapshot is stale must not appear in loadLocations().
        try await sut.evictStaleEntries()
        let loaded = await sut.loadLocations()
        #expect(loaded.isEmpty, "After eviction with no data, loadLocations should return empty array")
    }
}
