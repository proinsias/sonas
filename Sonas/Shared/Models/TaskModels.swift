import Foundation

// MARK: - Task

/// A single Todoist task from a family project.
struct Task: Identifiable, Equatable, Sendable {
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
    let orderIndex: Int  // For stable list ordering within a project
}

// MARK: - TaskDue

struct TaskDue: Equatable, Sendable {
    let date: Date?
    let string: String  // Human-readable from Todoist (e.g., "tomorrow", "every Monday")
    let isRecurring: Bool
}

// MARK: - TaskPriority

enum TaskPriority: Int, CaseIterable, Sendable, Equatable, Comparable {
    case normal = 1
    case medium = 2
    case high   = 3
    case urgent = 4

    public static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .normal: return "Normal"
        case .medium: return "Medium"
        case .high:   return "High"
        case .urgent: return "Urgent"
        }
    }

    /// Todoist API priority value → TaskPriority (Todoist uses 4 for urgent, 1 for normal)
    init(todoistPriority: Int) {
        self = TaskPriority(rawValue: todoistPriority) ?? .normal
    }
}
