import Foundation
import Observation

// MARK: - TasksViewModel (T057)

@Observable
@MainActor
final class TasksViewModel {
    // MARK: Published state

    private(set) var tasksByProject: [String: [Task]] = [:]
    private(set) var isLoading: Bool = true
    private(set) var error: PanelError?
    private(set) var completionErrorToast: String?
    private(set) var lastUpdated: Date?

    // MARK: Dependencies

    private let service: any TaskServiceProtocol
    private let cache: CacheServiceProtocol
    private var refreshTimer: Timer?

    private(set) var isConnected: Bool
    private(set) var availableProjects: [TaskProject] = []

    init(service: any TaskServiceProtocol, cache: CacheServiceProtocol? = nil) {
        self.service = service
        self.cache = cache ?? CacheService.shared
        isConnected = service.isConnected
    }

    static func makeDefault() -> TasksViewModel {
        let useMock = ProcessInfo.processInfo.environment["USE_MOCK_TASKS"] == "1"
        return TasksViewModel(service: useMock ? TaskServiceMock() : TodoistService())
    }

    // MARK: - Data loading

    func start() async {
        if isConnected, availableProjects.isEmpty {
            availableProjects = await (try? service.fetchProjects()) ?? []
        }
        // Load cached tasks first
        let cached = await cache.loadTasks()
        if !cached.isEmpty {
            tasksByProject = Dictionary(grouping: cached, by: \.projectName)
            lastUpdated = await cache.loadTasksSavedAt()
            isLoading = false
        }
        await fetchLive()
        startRefreshTimer()
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func refresh() async {
        await fetchLive()
    }

    // MARK: - Todoist connection (called from SettingsView)

    func connectTodoist(apiToken: String) async throws {
        try await service.connectTodoist(apiToken: apiToken)
        isConnected = true
        availableProjects = await (try? service.fetchProjects()) ?? []
        await start()
    }

    func disconnectTodoist() async {
        await service.disconnectTodoist()
        isConnected = false
        availableProjects = []
        tasksByProject = [:]
        error = nil
        isLoading = false
    }

    // MARK: - Optimistic task completion

    func completeTask(_ task: Task) async {
        // Optimistic: remove from UI immediately
        var updated = tasksByProject
        for project in updated.keys where updated[project]?.contains(where: { $0.id == task.id }) == true {
            updated[project] = updated[project]?.filter { $0.id != task.id }
        }
        tasksByProject = updated

        // API call in background
        do {
            try await service.completeTask(id: task.id)
            try? await cache.saveTasks(Array(tasksByProject.values.flatMap(\.self)))
        } catch {
            // Rollback on failure
            var rolled = tasksByProject
            for (project, tasks) in rolled where project == task.projectName {
                rolled[project] = ([task] + tasks).sorted { $0.orderIndex < $1.orderIndex }
            }
            tasksByProject = rolled
            completionErrorToast = "Couldn't complete task. Please try again."
            SonasLogger.error(SonasLogger.tasks, "TasksViewModel: completeTask failed", error: error)
        }
    }

    func dismissToast() {
        completionErrorToast = nil
    }

    // MARK: - Private

    private func fetchLive() async {
        guard service.isConnected else {
            isLoading = false
            return
        }
        do {
            let tasks = try await service.fetchTasks()
            tasksByProject = Dictionary(grouping: tasks, by: \.projectName)
            lastUpdated = Date()
            error = nil
            isLoading = false
            try? await cache.saveTasks(tasks)
        } catch TaskServiceError.authenticationFailed {
            error = PanelError(title: "Todoist Disconnected", message: "Re-connect in Settings.", isRetryable: false)
            isLoading = false
        } catch {
            if tasksByProject.isEmpty {
                self.error = PanelError(
                    title: "Tasks Unavailable",
                    message: error.localizedDescription,
                    isRetryable: true,
                )
            }
            isLoading = false
        }
    }

    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { [weak self] _ in
            Swift.Task { @MainActor in await self?.fetchLive() }
        }
    }
}
