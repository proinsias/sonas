import Foundation
import WeatherKit
import CoreLocation

// MARK: - WeatherServiceProtocol (T044)

protocol WeatherServiceProtocol: AnyObject, Sendable {
    /// Fetch current weather + 7-day forecast for the given coordinate.
    func fetchWeather(for coordinate: CLLocationCoordinate2D) async throws
        -> (current: WeatherSnapshot, forecast: [DayForecast])
}

// MARK: - WeatherServiceError

enum WeatherServiceError: LocalizedError {
    case locationNotConfigured
    case weatherKitUnavailable(Error)
    case aqiFetchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .locationNotConfigured:
            return "Set your home location in Settings to view weather."
        case .weatherKitUnavailable(let err):
            return "Weather service unavailable: \(err.localizedDescription)"
        case .aqiFetchFailed:
            return nil  // Non-fatal — weather still shown without AQI
        }
    }
}

// MARK: - WeatherService (T046)
// Concurrent async let for WeatherKit + Open-Meteo AQI per research.md §Decision 2.

@MainActor
final class WeatherService: WeatherServiceProtocol {

    private let weatherService = WeatherKit.WeatherService.shared
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchWeather(for coordinate: CLLocationCoordinate2D) async throws
        -> (current: WeatherSnapshot, forecast: [DayForecast]) {
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            throw WeatherServiceError.locationNotConfigured
        }

        SonasLogger.weather.info("WeatherService: fetching weather")

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        // Concurrent fetch: WeatherKit + AQI
        async let weatherKitResult = fetchWeatherKit(location: location)
        async let aqiResult = fetchAQI(coordinate: coordinate)

        let (wk, aqiValue) = try await (weatherKitResult, aqiResult)

        let snapshot = WeatherSnapshot(
            temperature: wk.current.temperature.converted(to: .celsius).value,
            feelsLike: wk.current.apparentTemperature.converted(to: .celsius).value,
            conditionDescription: wk.current.condition.description,
            conditionSymbolName: wk.current.symbolName,
            humidity: wk.current.humidity,
            windSpeed: wk.current.wind.speed.converted(to: .kilometersPerHour).value,
            windDirection: Double(wk.current.wind.direction.value),
            windCompassLabel: wk.current.wind.compassDirection.abbreviation,
            pressure: wk.current.pressure.converted(to: .hectopascals).value,
            pressureTrend: PressureTrend(weatherKitTrend: wk.current.pressureTrend),
            airQualityIndex: aqiValue,
            aiqCategory: aqiValue.map { AQICategory(usAQI: $0) },
            sunriseTime: wk.daily[0].sun.sunrise ?? .now,
            sunsetTime: wk.daily[0].sun.sunset ?? .now,
            moonPhase: MoonPhase(weatherKit: wk.daily[0].moon.phase),
            fetchedAt: .now
        )

        let forecast = wk.daily.prefix(7).enumerated().map { index, day in
            let calendar = Calendar.current
            let dateString = ISO8601DateFormatter().string(
                from: calendar.startOfDay(for: day.date)
            )
            return DayForecast(
                id: String(dateString.prefix(10)),
                date: day.date,
                highTemperature: day.highTemperature.converted(to: .celsius).value,
                lowTemperature: day.lowTemperature.converted(to: .celsius).value,
                conditionSymbolName: day.symbolName,
                conditionDescription: day.condition.description,
                precipitationChance: day.precipitationChance
            )
        }

        return (snapshot, Array(forecast))
    }

    // MARK: - Private helpers

    private func fetchWeatherKit(location: CLLocation) async throws
        -> (current: CurrentWeather, daily: Forecast<DayWeather>) {
        do {
            let weather = try await weatherService.weather(
                for: location,
                including: .current, .daily
            )
            return (weather.0, weather.1)
        } catch {
            throw WeatherServiceError.weatherKitUnavailable(error)
        }
    }

    private func fetchAQI(coordinate: CLLocationCoordinate2D) async -> Int? {
        // Open-Meteo Air Quality API (no API key required; free tier)
        let urlString = "https://air-quality-api.open-meteo.com/v1/air-quality"
            + "?latitude=\(coordinate.latitude)"
            + "&longitude=\(coordinate.longitude)"
            + "&current=us_aqi"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                SonasLogger.weather.warning("WeatherService: AQI fetch returned non-200")
                return nil
            }
            let decoded = try JSONDecoder().decode(OpenMeteoAQIResponse.self, from: data)
            return decoded.current.us_aqi
        } catch {
            SonasLogger.error(SonasLogger.weather, "WeatherService: AQI fetch failed", error: error)
            return nil  // AQI failure is non-fatal
        }
    }
}

// MARK: - Open-Meteo AQI response

private struct OpenMeteoAQIResponse: Decodable {
    let current: CurrentAQI
    struct CurrentAQI: Decodable {
        let us_aqi: Int?
    }
}

// MARK: - WeatherKit bridging extensions

private extension PressureTrend {
    init(weatherKitTrend: WeatherKit.PressureTrend) {
        switch weatherKitTrend {
        case .rising:  self = .rising
        case .steady:  self = .steady
        case .falling: self = .falling
        @unknown default: self = .steady
        }
    }
}

private extension WeatherKit.Wind.CompassDirection {
    var abbreviation: String {
        switch self {
        case .north:          return "N"
        case .northNortheast: return "NNE"
        case .northeast:      return "NE"
        case .eastNortheast:  return "ENE"
        case .east:           return "E"
        case .eastSoutheast:  return "ESE"
        case .southeast:      return "SE"
        case .southSoutheast: return "SSE"
        case .south:          return "S"
        case .southSouthwest: return "SSW"
        case .southwest:      return "SW"
        case .westSouthwest:  return "WSW"
        case .west:           return "W"
        case .westNorthwest:  return "WNW"
        case .northwest:      return "NW"
        case .northNorthwest: return "NNW"
        @unknown default:     return "—"
        }
    }
}

// MARK: - MoonPhase mapping from WeatherKit

private extension MoonPhase {
    init(weatherKit phase: WeatherKit.MoonPhase) {
        switch phase {
        case .new:             self = .newMoon
        case .waxingCrescent:  self = .waxingCrescent
        case .firstQuarter:    self = .firstQuarter
        case .waxingGibbous:   self = .waxingGibbous
        case .full:            self = .fullMoon
        case .waningGibbous:   self = .waningGibbous
        case .lastQuarter:     self = .lastQuarter
        case .waningCrescent:  self = .waningCrescent
        @unknown default:      self = .newMoon
        }
    }
}
