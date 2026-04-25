import BackgroundTasks
@preconcurrency import GoogleSignIn
import SwiftData
import SwiftUI

// MARK: - SonasApp (T025)

@main
struct SonasApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .onOpenURL { url in
                    // Google OAuth redirect (com.googleusercontent.apps.* scheme)
                    GIDSignIn.sharedInstance.handle(url)
                    // Spotify OAuth redirect (sonas:// scheme)
                    if url.scheme == "sonas" {
                        NotificationCenter.default.post(name: .spotifyOpenURL, object: url)
                    }
                }
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
            using: nil,
        ) { task in
            // T089: Full BGAppRefreshTask handler
            // Fetches weather snapshot, AQI, and Todoist tasks; writes to CacheService.
            SonasLogger.app.info("BGAppRefreshTask: handler invoked")

            // Guard against setTaskCompleted being called twice (once from the task body
            // on success/error, and once from the expiration handler on timeout).
            var completed = false

            let refreshTask = Task {
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

                    if !completed { completed = true; task.setTaskCompleted(success: true) }
                } catch {
                    SonasLogger.error(SonasLogger.app, "BGAppRefreshTask: refresh failed", error: error)
                    if !completed { completed = true; task.setTaskCompleted(success: false) }
                }
            }

            // Expiry handler: cancel in-flight work AND immediately mark the task done.
            // Calling setTaskCompleted here (not only from the async body) is required because
            // cooperative Task cancellation may not propagate before the OS watchdog fires.
            task.expirationHandler = {
                refreshTask.cancel()
                if !completed { completed = true; task.setTaskCompleted(success: false) }
                SonasLogger.app.warning("BGAppRefreshTask: expired — in-flight work cancelled")
            }
        }
        SonasLogger.app.info("SonasApp: BGTaskScheduler registered")
    }

    private func scheduleBGRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.sonas.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 min
        do {
            try BGTaskScheduler.shared.submit(request)
            SonasLogger.app.info("BGAppRefreshTask: scheduled in ≥15 min")
        } catch {
            SonasLogger.error(SonasLogger.app, "BGAppRefreshTask: scheduling failed", error: error)
        }
    }
}
