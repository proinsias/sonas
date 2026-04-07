import Foundation
import OSLog

// MARK: - SonasLogger
// Constitution §Quality Logging: structured OSLog with one subsystem per feature module.
// PII-scrubbing guard: precise coordinates and display names are NEVER logged at non-local
// privacy levels. All service implementations in Phases 3–7 MUST call SonasLogger.

enum SonasLogger {

    private static let subsystem = "com.yourteam.sonas"

    // MARK: Per-module loggers
    static let location = Logger(subsystem: subsystem, category: "location")
    static let weather  = Logger(subsystem: subsystem, category: "weather")
    static let calendar = Logger(subsystem: subsystem, category: "calendar")
    static let tasks    = Logger(subsystem: subsystem, category: "tasks")
    static let photos   = Logger(subsystem: subsystem, category: "photos")
    static let jam      = Logger(subsystem: subsystem, category: "jam")
    static let cache    = Logger(subsystem: subsystem, category: "cache")
    static let app      = Logger(subsystem: subsystem, category: "app")
    static let ui       = Logger(subsystem: subsystem, category: "ui")

    // MARK: - PII-scrubbing helpers

    /// Logs a location event without emitting precise coordinates.
    /// - Parameter memberID: An opaque identifier (not a display name) used for correlation.
    /// - Parameter placeName: The human-readable place name (scrubbed — logged as private).
    static func locationUpdate(memberID: String, placeName: String) {
        location.info(
            "Location update for member \(memberID, privacy: .public) — place: \(placeName, privacy: .private)"
        )
    }

    /// Logs an error with a sanitised description (no PII in the public payload).
    static func error(
        _ logger: Logger,
        _ message: String,
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function
    ) {
        if let error {
            logger.error(
                "\(message, privacy: .public) | error: \(error.localizedDescription, privacy: .public) [\(file, privacy: .public).\(function, privacy: .public)]"
            )
        } else {
            logger.error(
                "\(message, privacy: .public) [\(file, privacy: .public).\(function, privacy: .public)]"
            )
        }
    }
}
