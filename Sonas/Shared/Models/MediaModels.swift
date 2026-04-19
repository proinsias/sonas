import Foundation

// MARK: - Photo

/// Metadata for a single photo from the iCloud Shared Album.
/// Full pixel data is loaded on demand via PhotoService; only metadata is persisted.
struct Photo: Identifiable, Equatable {
    /// `PHAsset.localIdentifier`
    let id: String
    let creationDate: Date?
    let width: Int
    let height: Int
    /// Contributor display name (from `PHAsset.creatorBundleIdentifier` or album member info)
    let contributorName: String?
}

// MARK: - JamSession

/// An active or recently ended Spotify Group Session (Jam).
struct JamSession: Identifiable, Equatable {
    let id: String
    /// The URL guests scan/tap to join the session
    let joinURL: URL
    let status: JamStatus
    let startedAt: Date
}

// MARK: - JamStatus

enum JamStatus: String, Equatable {
    case none // No session
    case active // Session running, QR visible
    case ending // Stop command sent, waiting for confirmation
    case ended // Session over, QR removed
}
