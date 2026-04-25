import Foundation

// MARK: - TaskServiceProtocol (T053)

@MainActor
protocol TaskServiceProtocol: AnyObject, Sendable {
    func fetchTasks() async throws -> [TodoTask]
    func fetchProjects() async throws -> [TaskProject]
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

// Todoist API v1 — personal API token auth, cursor pagination, optimistic complete + rollback.

@MainActor
final class TodoistService: TaskServiceProtocol {
    private enum Endpoint {
        static let base = "https://api.todoist.com/api/v1"
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

    func fetchTasks() async throws -> [TodoTask] {
        guard let token = resolvedToken else {
            throw TaskServiceError.notConnected
        }
        SonasLogger.tasks.info("TodoistService: fetchTasks")

        let allProjects = try await fetchProjects()
        let selected = AppConfiguration.shared.selectedTodoistProjectIDs
        let projects = selected.isEmpty ? allProjects : allProjects.filter { selected.contains($0.id) }
        var allTasks: [TodoTask] = []

        for project in projects {
            try await Task.sleep(nanoseconds: 300_000_000) // 300ms inter-request delay
            let tasks = try await fetchTasksForProject(id: project.id, token: token)
            allTasks.append(contentsOf: tasks.map { task in
                TodoTask(
                    id: task.id, content: task.content, description: task.description,
                    projectID: task.projectID, projectName: project.name,
                    due: task.due, priority: task.priority,
                    isCompleted: task.isCompleted, isCompleting: task.isCompleting,
                    createdAt: task.createdAt, orderIndex: task.orderIndex
                )
            })
        }
        return allTasks
    }

    func fetchProjects() async throws -> [TaskProject] {
        guard let token = resolvedToken else {
            throw TaskServiceError.notConnected
        }
        var allProjects: [TaskProject] = []
        var cursor: String?

        repeat {
            var urlString = Endpoint.projects
            if let cursor { urlString += "?cursor=\(cursor)" }
            guard let url = URL(string: urlString) else {
                throw TaskServiceError.networkError(NSError(domain: "Todoist", code: -1))
            }
            var request = URLRequest(url: url)
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw TaskServiceError.networkError(NSError(domain: "Todoist", code: -1))
            }
            switch http.statusCode {
            case 200:
                let decoded = try JSONDecoder().decode(
                    TodoistPagedResponse<TodoistProjectResponse>.self, from: data
                )
                allProjects.append(contentsOf: decoded.results.map { TaskProject(id: $0.id, name: $0.name) })
                cursor = decoded.nextCursor
            case 401:
                throw TaskServiceError.authenticationFailed
            default:
                throw TaskServiceError.networkError(NSError(domain: "Todoist", code: http.statusCode))
            }
        } while cursor != nil

        return allProjects
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
        case 200, 204:
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

    private func fetchTasksForProject(id: String, token: String) async throws -> [TodoTask] {
        var tasks: [TodoTask] = []
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

            let decoded = try JSONDecoder().decode(TodoistPagedResponse<TodoistTask>.self, from: data)
            tasks.append(contentsOf: decoded.results.map { $0.toTodoTask(orderIndex: &orderIndex) })
            cursor = decoded.nextCursor
        } while cursor != nil

        return tasks
    }
}

// MARK: - Todoist API response types

private struct TodoistPagedResponse<T: Decodable>: Decodable {
    let results: [T]
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case results
        case nextCursor = "next_cursor"
    }
}

private struct TodoistProjectResponse: Decodable {
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

    func toTodoTask(orderIndex: inout Int) -> TodoTask {
        defer { orderIndex += 1 }
        let taskDue: TaskDue? = due.map {
            let date = $0.date.flatMap {
                ISO8601DateFormatter().date(from: $0) ??
                    DateFormatter.todoistDate.date(from: $0)
            }
            return TaskDue(date: date, string: $0.string, isRecurring: $0.isRecurring)
        }
        return TodoTask(
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
