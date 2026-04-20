import CoreLocation
import Foundation
@testable import Sonas
import Testing

// MARK: - WeatherIntegrationTests (T083)

// Requires WeatherKit entitlement; run in SonasIntegrationTests scheme.

@MainActor
@Suite("Weather Integration Tests", .tags(.integration))
struct WeatherIntegrationTests {
    @Test
    func `given hard-coded Dublin coordinate when fetchWeather called then snapshot is non-nil with 7-day forecast`(
    ) async throws {
        let service = WeatherService()
        let dublinCoord = CLLocationCoordinate2D(latitude: 53.3498, longitude: -6.2603)

        let (snapshot, forecast) = try await service.fetchWeather(for: dublinCoord)

        #expect(snapshot.temperature > -50 && snapshot.temperature < 60, "Temperature must be in a realistic range")
        #expect(forecast.count == 7, "Forecast must contain exactly 7 entries")
        #expect(!snapshot.conditionDescription.isEmpty, "Condition description must be non-empty")
    }
}
