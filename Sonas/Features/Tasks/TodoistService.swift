import Foundation

// MARK: - TaskServiceProtocol (T053)

@MainActor
protocol TaskServiceProtocol: AnyObject, Sendable {
    func fetchTasks() async throws -> [Task]
    func completeTask(id: String) async throws
    func connectTodoist(apiToken: String) async throws
    func disconnectTodoist() async
    var isConnected: Bool { get }
}

// MARK: - TaskServiceError

enum TaskServiceError: LocalizedError {
    case authenticationFailed
    case rateLimitExceeded(retryAfter: TimeInterval)
    case networkError(Error)
    case notConnected

    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            "Todoist token invalid. Re-connect in Settings."
        case let .rateLimitExceeded(retry):
            "Rate limit reached. Retry in \(Int(retry)) seconds."
        case let .networkError(err):
            "Network error: \(err.localizedDescription)"
        case .notConnected:
            "Connect your Todoist account in Settings."
        }
    }
}

// MARK: - TodoistService (T055)

// Todoist REST API v2 — personal API token auth, cursor pagination, optimistic complete + rollback.

@MainActor
final class TodoistService: TaskServiceProtocol {
    private enum Endpoint {
        static let base = "https://api.todoist.com/rest/v2"
        static let projects = "\(base)/projects"
        static func tasks(projectID: String) -> String {
            "\(base)/tasks?project_id=\(projectID)"
        }

        static func closeTask(id: String) -> String {
            "\(base)/tasks/\(id)/close"
        }
    }

    private let session: URLSession
    private let tokenOverride: String?
    private(set) var isConnected: Bool

    init(session: URLSession = .shared, token: String? = nil) {
        self.session = session
        tokenOverride = token
        isConnected = token != nil || AppConfiguration.shared.todoistAPIToken != nil
    }

    private var resolvedToken: String? {
        tokenOverride ?? AppConfiguration.shared.todoistAPIToken
    }

    // MARK: - TaskServiceProtocol

    func connectTodoist(apiToken: String) async throws {
        AppConfiguration.shared.todoistAPIToken = apiToken
        isConnected = true
        SonasLogger.tasks.info("TodoistService: connected")
    }

    func disconnectTodoist() async {
        AppConfiguration.shared.todoistAPIToken = nil
        isConnected = false
        SonasLogger.tasks.info("TodoistService: disconnected")
    }

    func fetchTasks() async throws -> [Task] {
        guard let token = resolvedToken else {
            throw TaskServiceError.notConnected
        }
        SonasLogger.tasks.info("TodoistService: fetchTasks")

        let projectIDs = try await fetchSelectedProjectIDs(token: token)
        var allTasks: [Task] = []

        for projectID in projectIDs {
            try await Swift.Task.sleep(nanoseconds: 300_000_000) // 300ms inter-request delay
            let tasks = try await fetchTasksForProject(id: projectID, token: token)
            allTasks.append(contentsOf: tasks)
        }
        return allTasks
    }

    func completeTask(id: String) async throws {
        guard let token = resolvedToken else {
            throw TaskServiceError.notConnected
        }
        guard let url = URL(string: Endpoint.closeTask(id: id)) else {
            throw TaskServiceError.networkError(NSError(domain: "Todoist", code: -1))
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { return }

        switch http.statusCode {
        case 204:
            SonasLogger.tasks.info("TodoistService: task \(id) completed")
        case 401:
            throw TaskServiceError.authenticationFailed
        case 429:
            let retryAfter = Double(http.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
            throw TaskServiceError.rateLimitExceeded(retryAfter: retryAfter)
        default:
            throw TaskServiceError.networkError(
                NSError(domain: "Todoist", code: http.statusCode)
            )
        }
    }

    // MARK: - Private

    private func fetchSelectedProjectIDs(token: String) async throws -> [String] {
        let selectedIDs = AppConfiguration.shared.selectedTodoistProjectIDs
        if !selectedIDs.isEmpty { return selectedIDs }

        // Fall back to all projects if none configured
        guard let projectsURL = URL(string: Endpoint.projects) else {
            throw TaskServiceError.networkError(NSError(domain: "Todoist", code: -1))
        }
        var request = URLRequest(url: projectsURL)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await session.data(for: request)
        let projects = try JSONDecoder().decode([TodoistProject].self, from: data)
        return projects.map(\.id)
    }

    private func fetchTasksForProject(id: String, token: String) async throws -> [Task] {
        var tasks: [Task] = []
        var cursor: String?
        var orderIndex = 0

        repeat {
            var urlString = Endpoint.tasks(projectID: id)
            if let cursor { urlString += "&cursor=\(cursor)" }
            guard let tasksURL = URL(string: urlString) else {
                throw TaskServiceError.networkError(NSError(domain: "Todoist", code: -1))
            }
            var request = URLRequest(url: tasksURL)
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { break }

            switch http.statusCode {
            case 200: break
            case 401: throw TaskServiceError.authenticationFailed
            case 429:
                let retry = Double(http.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
                throw TaskServiceError.rateLimitExceeded(retryAfter: retry)
            default:
                throw TaskServiceError.networkError(
                    NSError(domain: "Todoist", code: http.statusCode)
                )
            }

            let decoded = try JSONDecoder().decode([TodoistTask].self, from: data)
            tasks.append(contentsOf: decoded.map { $0.toTask(orderIndex: &orderIndex) })
            cursor = http.value(forHTTPHeaderField: "X-Next-Cursor")
        } while cursor != nil

        return tasks
    }
}

// MARK: - Todoist API response types

private struct TodoistProject: Decodable {
    let id: String
    let name: String
}

private struct TodoistTask: Decodable {
    let id: String
    let content: String
    let description: String
    let projectID: String
    let priority: Int
    let due: TodoistDue?

    enum CodingKeys: String, CodingKey {
        case id, content, description, priority, due
        case projectID = "project_id"
    }

    func toTask(orderIndex: inout Int) -> Task {
        defer { orderIndex += 1 }
        let taskDue: TaskDue? = due.map {
            let date = $0.date.flatMap {
                ISO8601DateFormatter().date(from: $0) ??
                    DateFormatter.todoistDate.date(from: $0)
            }
            return TaskDue(date: date, string: $0.string, isRecurring: $0.isRecurring)
        }
        return Task(
            id: id, content: content, description: description,
            projectID: projectID, projectName: "", // Populated by calling context
            due: taskDue,
            priority: TaskPriority(todoistPriority: priority),
            isCompleted: false, isCompleting: false,
            createdAt: nil, orderIndex: orderIndex
        )
    }
}

private struct TodoistDue: Decodable {
    let date: String?
    let string: String
    let isRecurring: Bool

    enum CodingKeys: String, CodingKey {
        case date, string
        case isRecurring = "is_recurring"
    }
}

private extension DateFormatter {
    static let todoistDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
