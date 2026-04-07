import Foundation
import Observation
import CoreLocation

// MARK: - WeatherViewModel (T049)

@Observable
@MainActor
final class WeatherViewModel {

    // MARK: Published state
    private(set) var snapshot: WeatherSnapshot?
    private(set) var forecast: [DayForecast] = []
    private(set) var isLoading: Bool = true
    private(set) var error: PanelError?
    private(set) var lastUpdated: Date?

    // MARK: Dependencies
    private let service: any WeatherServiceProtocol
    private let cache: CacheServiceProtocol
    private let config: AppConfiguration
    private var refreshTimer: Timer?

    init(
        service: any WeatherServiceProtocol,
        cache: CacheServiceProtocol? = nil,
        config: AppConfiguration = .shared
    ) {
        self.service = service
        self.cache = cache ?? CacheService.shared
        self.config = config
    }

    // MARK: - Convenience factory

    static func makeDefault() -> WeatherViewModel {
        let useMock = ProcessInfo.processInfo.environment["USE_MOCK_WEATHER"] == "1"
        return WeatherViewModel(service: useMock ? WeatherServiceMock() : WeatherService())
    }

    // MARK: - Data loading

    func start() async {
        // 1. Load cached data immediately for ≤500ms first frame (SC-002)
        if let cached = await cache.loadWeather() {
            snapshot = cached
            forecast = await cache.loadForecast()
            lastUpdated = cached.fetchedAt
            isLoading = false
        }

        // 2. Fetch live data
        await fetchLive()

        // 3. Schedule 15-min foreground refresh timer
        startRefreshTimer()
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func refresh() async {
        await fetchLive()
    }

    // MARK: - Private

    private func fetchLive() async {
        guard let coordinate = config.homeLocation else {
            isLoading = false
            error = PanelError.notConfigured
            return
        }
        do {
            let (current, days) = try await service.fetchWeather(for: coordinate)
            snapshot = current
            forecast = days
            lastUpdated = current.fetchedAt
            error = nil
            isLoading = false
            try? await cache.saveWeather(current, forecast: days)
            SonasLogger.weather.info("WeatherViewModel: live data loaded")
        } catch WeatherServiceError.locationNotConfigured {
            error = .notConfigured
            isLoading = false
        } catch {
            if snapshot == nil {
                self.error = PanelError(
                    title: "Weather Unavailable",
                    message: error.localizedDescription,
                    isRetryable: true
                )
            }
            isLoading = false
        }
    }

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            Swift.Task { @MainActor in await self?.fetchLive() }
        }
    }
}
