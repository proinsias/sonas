import CoreLocation
import Foundation

// MARK: - WeatherServiceMock (T045)

// Returns fixture WeatherSnapshot with all 8 required fields populated.
// Active when USE_MOCK_WEATHER=1 environment variable is set.

final class WeatherServiceMock: WeatherServiceProtocol, @unchecked Sendable {
    func fetchWeather(for _: CLLocationCoordinate2D) async throws
        -> (current: WeatherSnapshot, forecast: [DayForecast]) {
        (Self.currentFixture, Self.forecastFixtures)
    }

    // MARK: Fixtures

    static let currentFixture = WeatherSnapshot(
        temperature: 18.5,
        feelsLike: 16.2,
        conditionDescription: "Partly Cloudy",
        conditionSymbolName: "cloud.sun.fill",
        humidity: 0.72,
        windSpeed: 22.0,
        windDirection: 247.0,
        windCompassLabel: "WSW",
        pressure: 1013.25,
        pressureTrend: .steady,
        airQualityIndex: 42,
        aiqCategory: .good,
        sunriseTime: Calendar.current.date(bySettingHour: 6, minute: 28, second: 0, of: .now)!,
        sunsetTime: Calendar.current.date(bySettingHour: 20, minute: 14, second: 0, of: .now)!,
        moonPhase: .waxingGibbous,
        fetchedAt: .now,
    )

    static let forecastFixtures: [DayForecast] = (0 ..< 7).map { offset in
        let date = Calendar.current.date(byAdding: .day, value: offset, to: .now)!
        let dateStr = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: date))
        return DayForecast(
            id: String(dateStr.prefix(10)),
            date: date,
            highTemperature: Double.random(in: 14 ... 22),
            lowTemperature: Double.random(in: 6 ... 13),
            conditionSymbolName: ["sun.max.fill", "cloud.sun.fill", "cloud.fill", "cloud.rain.fill"].randomElement()!,
            conditionDescription: ["Sunny", "Partly Cloudy", "Cloudy", "Light Rain"].randomElement()!,
            precipitationChance: Double.random(in: 0 ... 0.6),
        )
    }
}
