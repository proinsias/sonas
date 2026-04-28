@preconcurrency import BackgroundTasks
@preconcurrency import GoogleSignIn
import SwiftData
import SwiftUI

// MARK: - SonasApp (T025)

@main
struct SonasApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AdaptiveRootView()
                .onOpenURL { url in
                    // Google OAuth redirect (com.googleusercontent.apps.* scheme)
                    GIDSignIn.sharedInstance.handle(url)
                    // Spotify OAuth redirect (sonas:// scheme)
                    if url.scheme == "sonas" {
                        NotificationCenter.default.post(name: .spotifyOpenURL, object: url)
                    }
                }
        }
        .commands {
            SonasCommands()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                scheduleBGRefresh()
            }
        }
    }

    // MARK: - Background Tasks

    init() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.sonas.refresh",
            using: nil
        ) { task in
            SonasLogger.app.info("BGAppRefreshTask: handler invoked")

            var completed = false
            let refreshTask = Task {
                do {
                    if let coord = AppConfiguration.shared.homeLocation {
                        let (snapshot, forecast) = try await WeatherService().fetchWeather(for: coord)
                        try await CacheService.shared.saveWeather(snapshot, forecast: forecast)
                    }

                    if AppConfiguration.shared.todoistAPIToken != nil {
                        let tasks = try await TodoistService().fetchTasks()
                        try await CacheService.shared.saveTasks(tasks)
                    }

                    try await CacheService.shared.evictStaleEntries()

                    if !completed {
                        completed = true
                        task.setTaskCompleted(success: true)
                    }
                } catch {
                    SonasLogger.error(SonasLogger.app, "BGAppRefreshTask: refresh failed", error: error)
                    if !completed {
                        completed = true
                        task.setTaskCompleted(success: false)
                    }
                }
            }

            task.expirationHandler = {
                refreshTask.cancel()
                if !completed {
                    completed = true
                    task.setTaskCompleted(success: false)
                }
            }
        }
    }

    private func scheduleBGRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.sonas.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            SonasLogger.error(SonasLogger.app, "BGAppRefreshTask: scheduling failed", error: error)
        }
    }
}

// MARK: - AdaptiveRootView

struct AdaptiveRootView: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass

    var body: some View {
        if hSizeClass == .regular {
            IPadShell()
        } else {
            DashboardView()
        }
    }
}
