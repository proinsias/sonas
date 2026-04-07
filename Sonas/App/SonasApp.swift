import SwiftUI
import SwiftData
import BackgroundTasks

// MARK: - SonasApp (T025)

@main
struct SonasApp: App {

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .modelContainer(CacheService.shared.modelContainer)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                scheduleBGRefresh()
            }
        }
    }

    // MARK: - Background Tasks

    /// Registers the BGAppRefreshTask identifier.
    /// The no-op placeholder handler is replaced by the full implementation in T089
    /// (SonasApp.swift will be updated to add the weather + tasks + AQI fetch logic).
    init() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.sonas.refresh",
            using: nil
        ) { task in
            // T089: Full BGAppRefreshTask handler
            // Fetches weather snapshot, AQI, and Todoist tasks; writes to CacheService.
            SonasLogger.app.info("BGAppRefreshTask: handler invoked")

            let refreshTask = Swift.Task {
                do {
                    // Weather + AQI (concurrent)
                    if let coord = AppConfiguration.shared.homeLocation {
                        let (snapshot, forecast) = try await WeatherService().fetchWeather(for: coord)
                        try await CacheService.shared.saveWeather(snapshot, forecast: forecast)
                        SonasLogger.app.info("BGAppRefreshTask: weather refreshed")
                    }

                    // Todoist tasks
                    if AppConfiguration.shared.todoistAPIToken != nil {
                        let tasks = try await TodoistService().fetchTasks()
                        try await CacheService.shared.saveTasks(tasks)
                        SonasLogger.app.info("BGAppRefreshTask: tasks refreshed (\(tasks.count) tasks)")
                    }

                    // Evict stale entries
                    try await CacheService.shared.evictStaleEntries()

                    task.setTaskCompleted(success: true)
                } catch {
                    SonasLogger.error(SonasLogger.app, "BGAppRefreshTask: refresh failed", error: error)
                    task.setTaskCompleted(success: false)
                }
            }

            // Expiry handler cancels in-flight work
            task.expirationHandler = {
                refreshTask.cancel()
                SonasLogger.app.warning("BGAppRefreshTask: expired — in-flight work cancelled")
            }
        }
        SonasLogger.app.info("SonasApp: BGTaskScheduler registered")
    }

    private func scheduleBGRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.sonas.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)  // 15 min
        do {
            try BGTaskScheduler.shared.submit(request)
            SonasLogger.app.info("BGAppRefreshTask: scheduled in ≥15 min")
        } catch {
            SonasLogger.error(SonasLogger.app, "BGAppRefreshTask: scheduling failed", error: error)
        }
    }
}
