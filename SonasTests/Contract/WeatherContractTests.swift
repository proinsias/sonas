import CoreLocation
import Foundation
@testable import Sonas
import Testing

// MARK: - WeatherContractTests (T048)

// 🔴 TEST-FIRST GATE — run before WeatherService (T046)

@MainActor
@Suite("Weather Service Contract Tests")
struct WeatherContractTests {
    // MARK: - T048.1: snapshot.airQualityIndex == 42 from AQI stub

    @Test
    func `given AQI stub returns 42 when weather fetched then snapshot airQualityIndex is 42`() async throws {
        // WeatherKit mock + AQI stub — WeatherServiceMock short-circuits WeatherKit entitlement
        let mock = WeatherServiceMock()
        let (snapshot, _) = try await mock.fetchWeather(
            for: CLLocationCoordinate2D(latitude: 53.35, longitude: -6.26)
        )
        // Fixture sets airQualityIndex = 42
        #expect(snapshot.airQualityIndex == 42, "Fixture airQualityIndex must be 42")
    }

    // MARK: - T048.2: forecast.count == 7

    @Test
    func `given mock weather service when fetchWeather called then forecast contains 7 days`() async throws {
        let mock = WeatherServiceMock()
        let (_, forecast) = try await mock.fetchWeather(
            for: CLLocationCoordinate2D(latitude: 53.35, longitude: -6.26)
        )
        #expect(forecast.count == 7, "Forecast must contain exactly 7 DayForecast entries")
    }

    // MARK: - T048.3: forecast[0].id equals today midnight (ISO date prefix)

    @Test
    func `given mock weather service when fetchWeather called then forecast[0].id equals today's date`() async throws {
        let mock = WeatherServiceMock()
        let (_, forecast) = try await mock.fetchWeather(
            for: CLLocationCoordinate2D(latitude: 53.35, longitude: -6.26)
        )
        let todayString = String(
            ISO8601DateFormatter()
                .string(from: Calendar.current.startOfDay(for: .now))
                .prefix(10)
        )
        #expect(forecast[0].id == todayString, "First forecast entry ID must be today's ISO date (YYYY-MM-DD)")
    }

    // MARK: - T048.4: All 8 required weather attributes are non-nil/non-default

    @Test
    func `given mock weather service when fetchWeather called then all 8 required attributes are populated`(
    ) async throws {
        let mock = WeatherServiceMock()
        let (snapshot, _) = try await mock.fetchWeather(
            for: CLLocationCoordinate2D(latitude: 53.35, longitude: -6.26)
        )
        #expect(!snapshot.conditionDescription.isEmpty, "conditionDescription must be non-empty")
        #expect(snapshot.humidity > 0, "humidity must be > 0")
        #expect(snapshot.windSpeed > 0, "windSpeed must be > 0")
        #expect(!snapshot.windCompassLabel.isEmpty, "windCompassLabel must be non-empty")
        #expect(snapshot.pressure > 0, "pressure must be > 0")
        #expect(snapshot.airQualityIndex != nil, "airQualityIndex must be present in fixture")
        #expect(snapshot.sunriseTime < snapshot.sunsetTime, "sunrise must precede sunset")
    }
}
