import CoreLocation
import Foundation

// MARK: - FamilyMember

/// A family member whose location is shared via the CloudKit relay.
struct FamilyMember: Identifiable, Equatable {
    /// Stable CloudKit record name
    let id: String
    /// Display name (e.g., "Alice")
    let displayName: String
    /// Latest known location snapshot; nil if never received or stale beyond threshold
    let location: LocationSnapshot?

    /// True when the last location update is older than the 5-minute stale threshold.
    var isStale: Bool {
        guard let location else { return true }
        return location.isStale
    }
}

// MARK: - LocationSnapshot

/// A single location sample for one family member at a point in time.
struct LocationSnapshot: Equatable {
    let coordinate: CLLocationCoordinate2D
    /// Human-readable place name produced by `CLGeocoder` reverse-geocoding
    let placeName: String
    let recordedAt: Date

    /// Staleness thresholds (per research.md §Decision 9 eviction policy)
    enum Staleness {
        case fresh // < 5 minutes
        case stale // 5 – 30 minutes
        case veryStale // > 30 minutes
    }

    var isStale: Bool {
        staleness != .fresh
    }

    var staleness: Staleness {
        let age = Date.now.timeIntervalSince(recordedAt)
        switch age {
        case ..<300: return .fresh
        case ..<1800: return .stale
        default: return .veryStale
        }
    }

    /// Human-readable age label for "Location unavailable" / stale banners
    var ageLabel: String {
        switch staleness {
        case .fresh: placeName
        case .stale: "Last seen \(recordedAt.formatted(.relative(presentation: .named)))"
        case .veryStale: "Location unavailable"
        }
    }
}

// MARK: - CLLocationCoordinate2D + Equatable

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
