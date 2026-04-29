import Foundation

// MARK: - TVTopShelfSnapshot (T031)

struct TVTopShelfSnapshot: Codable {
    let photoFileURL: URL?
    let nextEventTitle: String?
    let nextEventStart: Date?
    let updatedAt: Date
}
