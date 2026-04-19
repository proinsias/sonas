import Foundation

// MARK: - TaskServiceMock (T054)

final class TaskServiceMock: TaskServiceProtocol, @unchecked Sendable {
    private(set) var isConnected: Bool = true

    func fetchTasks() async throws -> [Task] {
        Self.fixtures
    }

    func completeTask(id _: String) async throws {
        // Immediate success
    }

    func connectTodoist(apiToken _: String) async throws {
        isConnected = true
    }

    func disconnectTodoist() async {
        isConnected = false
    }

    static let fixtures: [Task] = [
        Task(
            id: "task-1", content: "Buy groceries", description: "",
            projectID: "proj-1", projectName: "Home",
            due: TaskDue(
                date: Calendar.current.date(byAdding: .day, value: 1, to: .now),
                string: "tomorrow",
                isRecurring: false,
            ),
            priority: .medium, isCompleted: false, isCompleting: false,
            createdAt: .now, orderIndex: 0,
        ),
        Task(
            id: "task-2", content: "School pickup at 3pm", description: "",
            projectID: "proj-1", projectName: "Home",
            due: TaskDue(date: .now, string: "today", isRecurring: true),
            priority: .high, isCompleted: false, isCompleting: false,
            createdAt: .now, orderIndex: 1,
        ),
        Task(
            id: "task-3", content: "Review insurance policy", description: "",
            projectID: "proj-2", projectName: "Admin",
            due: nil, priority: .normal, isCompleted: false, isCompleting: false,
            createdAt: .now, orderIndex: 0,
        ),
    ]
}
