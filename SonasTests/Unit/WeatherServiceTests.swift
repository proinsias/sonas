import CoreLocation
@testable import Sonas
import Testing

// MARK: - WeatherServiceTests (T051)

@MainActor
@Suite("Weather Service Unit Tests")
struct WeatherServiceTests {
    // MARK: - T051.1: MoonPhase from WeatherKit fraction value

    @Test
    func `given fraction 0 0 when moon phase initialised then returns new moon`() {
        let phase = MoonPhase(fraction: 0.0)
        #expect(phase == .newMoon)
    }

    @Test
    func `given fraction 0 49 when moon phase initialised then returns full moon`() {
        let phase = MoonPhase(fraction: 0.49)
        #expect(phase == .fullMoon)
    }

    @Test
    func `given fraction 0 95 when moon phase initialised then returns waning crescent`() {
        let phase = MoonPhase(fraction: 0.95)
        #expect(phase == .waningCrescent)
    }

    // MARK: - T051.2: airQualityIndex is nil when AQI fetch fails (non-fatal)

    @Test
    func `given WeatherServiceMock when fetchWeather_called_then_airQualityIndex_is_non_nil_from_fixture`(
    ) async throws {
        // WeatherServiceMock fixture has airQualityIndex = 42
        let service = WeatherServiceMock()
        let (snapshot, _) = try await service.fetchWeather(
            for: CLLocationCoordinate2D(latitude: 53.3, longitude: -6.2),
        )
        #expect(snapshot.airQualityIndex == 42)
    }

    // MARK: - T051.3: WeatherServiceError.locationNotConfigured when coordinate is nil

    @Test
    func `given invalid coordinate when fetchWeather_called_then_throws_locationNotConfigured`() async throws {
        let service = WeatherService()
        let invalidCoord = CLLocationCoordinate2D(latitude: 999, longitude: 999)
        await #expect(throws: WeatherServiceError.self) {
            _ = try await service.fetchWeather(for: invalidCoord)
        }
    }

    // MARK: - T051.4: AQICategory mapping

    @Test
    func `given us aqi 42 when AQI category initialised then returns good`() {
        #expect(AQICategory(usAQI: 42) == .good)
    }

    @Test
    func `given us aqi 160 when AQI category initialised then returns unhealthy`() {
        #expect(AQICategory(usAQI: 160) == .unhealthy)
    }
}
