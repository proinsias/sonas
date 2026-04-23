import Foundation

// MARK: - TaskProject

struct TaskProject: Identifiable, Hashable {
    let id: String
    let name: String
}

// MARK: - Task

/// A single Todoist task from a family project.
struct Task: Identifiable, Equatable {
    let id: String
    let content: String
    let description: String
    let projectID: String
    let projectName: String
    let due: TaskDue?
    let priority: TaskPriority
    let isCompleted: Bool
    /// True while an optimistic completion API call is in flight
    let isCompleting: Bool
    let createdAt: Date?
    let orderIndex: Int // For stable list ordering within a project
}

// MARK: - TaskDue

struct TaskDue: Equatable {
    let date: Date?
    let string: String // Human-readable from Todoist (e.g., "tomorrow", "every Monday")
    let isRecurring: Bool
}

// MARK: - TaskPriority

enum TaskPriority: Int, CaseIterable, Equatable, Comparable {
    case normal = 1
    case medium = 2
    case high = 3
    case urgent = 4

    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .normal: "Normal"
        case .medium: "Medium"
        case .high: "High"
        case .urgent: "Urgent"
        }
    }

    /// Todoist API priority value → TaskPriority (Todoist uses 4 for urgent, 1 for normal)
    init(todoistPriority: Int) {
        self = TaskPriority(rawValue: todoistPriority) ?? .normal
    }
}
