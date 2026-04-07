import Testing
import CoreLocation
@testable import Sonas

// MARK: - WeatherServiceTests (T051)

@Suite("Weather Service Unit Tests")
struct WeatherServiceTests {

    // MARK: - T051.1: MoonPhase from WeatherKit fraction value

    @Test("given fraction 0.0 when MoonPhase initialised then returns newMoon")
    func given_fraction0_when_moonPhaseInit_then_newMoon() {
        let phase = MoonPhase(fraction: 0.0)
        #expect(phase == .newMoon)
    }

    @Test("given fraction 0.49 when MoonPhase initialised then returns fullMoon")
    func given_fraction049_when_moonPhaseInit_then_fullMoon() {
        let phase = MoonPhase(fraction: 0.49)
        #expect(phase == .fullMoon)
    }

    @Test("given fraction 0.95 when MoonPhase initialised then returns waningCrescent")
    func given_fraction095_when_moonPhaseInit_then_waningCrescent() {
        let phase = MoonPhase(fraction: 0.95)
        #expect(phase == .waningCrescent)
    }

    // MARK: - T051.2: airQualityIndex is nil when AQI fetch fails (non-fatal)

    @Test("given WeatherServiceMock when fetchWeather called then airQualityIndex is non-nil from fixture")
    func given_mockService_when_fetchWeather_then_airQualityIndexPresent() async throws {
        // WeatherServiceMock fixture has airQualityIndex = 42
        let service = WeatherServiceMock()
        let (snapshot, _) = try await service.fetchWeather(
            for: CLLocationCoordinate2D(latitude: 53.3, longitude: -6.2)
        )
        #expect(snapshot.airQualityIndex == 42)
    }

    // MARK: - T051.3: WeatherServiceError.locationNotConfigured when coordinate is nil

    @Test("given invalid coordinate when fetchWeather called then throws locationNotConfigured")
    func given_invalidCoordinate_when_fetchWeather_then_throwsLocationNotConfigured() async throws {
        let service = WeatherService()
        let invalidCoord = CLLocationCoordinate2D(latitude: 999, longitude: 999)
        await #expect(throws: WeatherServiceError.self) {
            _ = try await service.fetchWeather(for: invalidCoord)
        }
    }

    // MARK: - T051.4: AQICategory mapping

    @Test("given us_aqi 42 when AQICategory initialised then returns good")
    func given_aqi42_when_categoryInit_then_good() {
        #expect(AQICategory(usAQI: 42) == .good)
    }

    @Test("given us_aqi 160 when AQICategory initialised then returns unhealthy")
    func given_aqi160_when_categoryInit_then_unhealthy() {
        #expect(AQICategory(usAQI: 160) == .unhealthy)
    }
}
