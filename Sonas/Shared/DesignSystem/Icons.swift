import Foundation

// MARK: - SF Symbols Aliases
// All icons use SF Symbols 5+ names. Each constant maps to a semantic panel concept.
// Using string aliases (not enum) allows easy preview via Image(systemName:).

enum Icon {

    // MARK: Panel identifiers
    static let clock = "clock"
    static let location = "location.fill"
    static let calendar = "calendar"
    static let weather = "cloud.sun.fill"
    static let tasks = "checkmark.circle"
    static let photos = "photo.on.rectangle.angled"
    static let jam = "music.note.list"
    static let settings = "gear"

    // MARK: Weather conditions
    static let weatherClear = "sun.max.fill"
    static let weatherCloudy = "cloud.fill"
    static let weatherPartlyCloudy = "cloud.sun.fill"
    static let weatherRain = "cloud.rain.fill"
    static let weatherHeavyRain = "cloud.heavyrain.fill"
    static let weatherSnow = "snowflake"
    static let weatherThunder = "cloud.bolt.fill"
    static let weatherFog = "cloud.fog.fill"
    static let weatherWind = "wind"
    static let weatherHail = "cloud.hail.fill"

    // MARK: Weather attributes
    static let humidity = "humidity.fill"
    static let windSpeed = "wind"
    static let pressure = "gauge"
    static let airQuality = "aqi.medium"
    static let sunrise = "sunrise.fill"
    static let sunset = "sunset.fill"

    // MARK: Moon phases
    static let moonNew = "moonphase.new.moon"
    static let moonWaxingCrescent = "moonphase.waxing.crescent"
    static let moonFirstQuarter = "moonphase.first.quarter"
    static let moonWaxingGibbous = "moonphase.waxing.gibbous"
    static let moonFull = "moonphase.full.moon"
    static let moonWaningGibbous = "moonphase.waning.gibbous"
    static let moonLastQuarter = "moonphase.last.quarter"
    static let moonWaningCrescent = "moonphase.waning.crescent"

    // MARK: Status
    static let locationUnavailable = "location.slash.fill"
    static let offline = "wifi.slash"
    static let error = "exclamationmark.triangle.fill"
    static let loading = "arrow.2.circlepath"
    static let refresh = "arrow.clockwise"
    static let retry = "arrow.counterclockwise"

    // MARK: Actions
    static let complete = "checkmark.circle.fill"
    static let incomplete = "circle"
    static let expand = "arrow.up.left.and.arrow.down.right"
    static let collapse = "arrow.down.right.and.arrow.up.left"
    static let connect = "link"
    static let disconnect = "link.badge.minus"
    static let install = "arrow.down.app.fill"

    // MARK: Spotify
    static let spotifyPlay = "play.fill"
    static let spotifyStop = "stop.fill"
    static let spotifyQR = "qrcode"
}
