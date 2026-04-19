# Contract: WeatherService

**Purpose**: Fetch current weather snapshot (WeatherKit) and AQI (Open-Meteo) for a given coordinate; provide a 7-day
forecast.

```swift
protocol WeatherServiceProtocol {
    /// Fetch current conditions and 7-day forecast for the given coordinate.
    /// Combines WeatherKit and Open-Meteo AQI concurrently.
    /// - Returns: tuple of current snapshot and ordered forecast array (ascending date)
    func fetchWeather(
        for coordinate: CLLocationCoordinate2D
    ) async throws -> (current: WeatherSnapshot, forecast: [DayForecast])
}
```

**WeatherKit attributes used**:

- `WeatherService.weather(for:including:)` with `.current` and `.daily` queries
- `CurrentWeather`: `.temperature`, `.feelsLike`, `.condition`, `.humidity`, `.wind`, `.pressure`, `.pressureTrend`
- `DayWeather`: `.sun.sunrise`, `.sun.sunset`, `.moon.phase`, `.highTemperature`, `.lowTemperature`, `.condition`,
  `.precipitationChance`

**Open-Meteo AQI endpoint**:

```
GET https://air-quality-api.open-meteo.com/v1/air-quality
    ?latitude={lat}
    &longitude={lon}
    &current=european_aqi,us_aqi
    &timezone=auto
```

Response field used: `current.us_aqi` (integer 0–500).

**Error cases**:

- `WeatherServiceError.weatherKitUnavailable` — entitlement missing or region unsupported; returns cached snapshot with
  `airQualityIndex = nil`
- `WeatherServiceError.aqiUnavailable` — Open-Meteo unreachable; `WeatherSnapshot` returned with `airQualityIndex = nil`
  (degraded, not a total failure)
- `WeatherServiceError.locationNotConfigured` — home coordinate not set in `AppConfiguration`

**Contract test fixtures** (`WeatherContractTests.swift`):

```swift
// Given: WeatherKit mock returning fixture CurrentWeather and DailyForecast
//        Open-Meteo stub returning { "current": { "us_aqi": 42 } }
// When: fetchWeather(for:) called
// Then: WeatherSnapshot.airQualityIndex == 42
//       forecast.count == 7
//       forecast[0].date == today (midnight)
```
