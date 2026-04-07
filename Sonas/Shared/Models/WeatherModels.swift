import Foundation

// MARK: - WeatherSnapshot

/// Current weather conditions for the configured home location.
struct WeatherSnapshot: Equatable, Sendable {
    let temperature: Double        // Celsius
    let feelsLike: Double          // Celsius
    let conditionDescription: String
    let conditionSymbolName: String  // SF Symbol name
    let humidity: Double           // 0.0 – 1.0
    let windSpeed: Double          // km/h
    let windDirection: Double      // degrees, 0 = north
    let windCompassLabel: String   // e.g., "NNW"
    let pressure: Double           // hPa
    let pressureTrend: PressureTrend
    let airQualityIndex: Int?      // nil when AQI fetch failed
    let aiqCategory: AQICategory?
    let sunriseTime: Date
    let sunsetTime: Date
    let moonPhase: MoonPhase
    let fetchedAt: Date
}

// MARK: - DayForecast

/// One day's forecast entry for the 7-day strip.
struct DayForecast: Identifiable, Equatable, Sendable {
    let id: String   // ISO date string "yyyy-MM-dd" — stable across re-fetches
    let date: Date
    let highTemperature: Double  // Celsius
    let lowTemperature: Double   // Celsius
    let conditionSymbolName: String
    let conditionDescription: String
    let precipitationChance: Double  // 0.0 – 1.0
}

// MARK: - PressureTrend

enum PressureTrend: String, Sendable, Equatable {
    case rising   = "Rising"
    case steady   = "Steady"
    case falling  = "Falling"

    var symbolName: String {
        switch self {
        case .rising:  return "arrow.up.right"
        case .steady:  return "arrow.right"
        case .falling: return "arrow.down.right"
        }
    }
}

// MARK: - MoonPhase

enum MoonPhase: String, CaseIterable, Sendable, Equatable {
    case newMoon          = "New Moon"
    case waxingCrescent   = "Waxing Crescent"
    case firstQuarter     = "First Quarter"
    case waxingGibbous    = "Waxing Gibbous"
    case fullMoon         = "Full Moon"
    case waningGibbous    = "Waning Gibbous"
    case lastQuarter      = "Last Quarter"
    case waningCrescent   = "Waning Crescent"

    var displayName: String { rawValue }

    var symbolName: String {
        switch self {
        case .newMoon:        return Icon.moonNew
        case .waxingCrescent: return Icon.moonWaxingCrescent
        case .firstQuarter:   return Icon.moonFirstQuarter
        case .waxingGibbous:  return Icon.moonWaxingGibbous
        case .fullMoon:       return Icon.moonFull
        case .waningGibbous:  return Icon.moonWaningGibbous
        case .lastQuarter:    return Icon.moonLastQuarter
        case .waningCrescent: return Icon.moonWaningCrescent
        }
    }

    /// Initialise from a WeatherKit moon phase fractional value (0.0–1.0).
    init(fraction: Double) {
        switch fraction {
        case 0..<0.0625:   self = .newMoon
        case 0.0625..<0.1875: self = .waxingCrescent
        case 0.1875..<0.3125: self = .firstQuarter
        case 0.3125..<0.4375: self = .waxingGibbous
        case 0.4375..<0.5625: self = .fullMoon
        case 0.5625..<0.6875: self = .waningGibbous
        case 0.6875..<0.8125: self = .lastQuarter
        default:           self = .waningCrescent
        }
    }
}

// MARK: - AQICategory

enum AQICategory: Sendable, Equatable {
    case good           // 0–50
    case moderate       // 51–100
    case unhealthySensitive // 101–150
    case unhealthy      // 151–200
    case veryUnhealthy  // 201–300
    case hazardous      // 301+

    init(usAQI: Int) {
        switch usAQI {
        case 0...50:    self = .good
        case 51...100:  self = .moderate
        case 101...150: self = .unhealthySensitive
        case 151...200: self = .unhealthy
        case 201...300: self = .veryUnhealthy
        default:        self = .hazardous
        }
    }

    var label: String {
        switch self {
        case .good:               return "Good"
        case .moderate:           return "Moderate"
        case .unhealthySensitive: return "Unhealthy for Sensitive"
        case .unhealthy:          return "Unhealthy"
        case .veryUnhealthy:      return "Very Unhealthy"
        case .hazardous:          return "Hazardous"
        }
    }

    var color: String {  // Hex string for SwiftUI Color(hex:)
        switch self {
        case .good:               return "#00E400"
        case .moderate:           return "#FFFF00"
        case .unhealthySensitive: return "#FF7E00"
        case .unhealthy:          return "#FF0000"
        case .veryUnhealthy:      return "#8F3F97"
        case .hazardous:          return "#7E0023"
        }
    }
}
