import Foundation

// MARK: - Photo

/// Metadata for a single photo from the iCloud Shared Album.
/// Full pixel data is loaded on demand via PhotoService; only metadata is persisted.
struct Photo: Identifiable, Equatable, Sendable {
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
struct JamSession: Identifiable, Equatable, Sendable {
    let id: String
    /// The URL guests scan/tap to join the session
    let joinURL: URL
    let status: JamStatus
    let startedAt: Date
}

// MARK: - JamStatus

enum JamStatus: String, Sendable, Equatable {
    case none    = "none"     // No session
    case active  = "active"   // Session running, QR visible
    case ending  = "ending"   // Stop command sent, waiting for confirmation
    case ended   = "ended"    // Session over, QR removed
}
