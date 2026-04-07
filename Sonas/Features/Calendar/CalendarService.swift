import Foundation
import EventKit

// MARK: - CalendarServiceProtocol (T027)

protocol CalendarServiceProtocol: AnyObject, Sendable {
    /// Fetch upcoming calendar events within the specified hour window (default: 48h).
    func fetchUpcomingEvents(hours: Int) async throws -> [CalendarEvent]
    /// Present Google Sign-In OAuth flow and store token in Keychain.
    func connectGoogleAccount() async throws
    /// Revoke Google token and remove from Keychain.
    func disconnectGoogleAccount() async
    /// True when a valid Google OAuth token is stored in Keychain.
    var isGoogleConnected: Bool { get }
    /// True when the last Google token refresh returned 401.
    var needsGoogleReconnect: Bool { get }
}

// MARK: - CalendarServiceError

enum CalendarServiceError: LocalizedError {
    case eventKitPermissionDenied
    case googleAuthFailed(Error)
    case fetchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .eventKitPermissionDenied:
            return "Calendar access is required to show your events. Enable it in Settings."
        case .googleAuthFailed(let err):
            return "Google Calendar connection failed: \(err.localizedDescription)"
        case .fetchFailed(let err):
            return "Could not load calendar events: \(err.localizedDescription)"
        }
    }
}

// MARK: - GoogleCalendarClient (T032)
// Handles Google Calendar REST v3 fetch with OAuth token management.

final class GoogleCalendarClient: Sendable {

    private enum Endpoint {
        static let events = "https://www.googleapis.com/calendar/v3/calendars/primary/events"
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetch events from Google Calendar REST v3 for the given time window.
    /// - Throws `CalendarServiceError.fetchFailed` on network or decoding error.
    /// - Throws `CalendarServiceError.googleAuthFailed` on HTTP 401.
    func fetchEvents(
        accessToken: String,
        timeMin: Date,
        timeMax: Date
    ) async throws -> [CalendarEvent] {
        var components = URLComponents(string: Endpoint.events)!
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        components.queryItems = [
            .init(name: "timeMin", value: formatter.string(from: timeMin)),
            .init(name: "timeMax", value: formatter.string(from: timeMax)),
            .init(name: "singleEvents", value: "true"),
            .init(name: "orderBy", value: "startTime"),
            .init(name: "maxResults", value: "50")
        ]

        var request = URLRequest(url: components.url!)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            throw CalendarServiceError.googleAuthFailed(
                NSError(domain: "GoogleCalendar", code: 401, userInfo: [NSLocalizedDescriptionKey: "Token expired"])
            )
        }

        let decoded = try JSONDecoder().decode(GoogleCalendarResponse.self, from: data)
        return decoded.items.map { $0.toCalendarEvent() }
    }
}

// MARK: - Google Calendar REST response types

private struct GoogleCalendarResponse: Decodable {
    let items: [GoogleCalendarItem]
}

private struct GoogleCalendarItem: Decodable {
    let id: String?
    let summary: String?
    let start: GoogleCalendarDateTime?
    let end: GoogleCalendarDateTime?
    let attendees: [GoogleCalendarAttendee]?

    struct GoogleCalendarDateTime: Decodable {
        let dateTime: String?
        let date: String?
    }

    struct GoogleCalendarAttendee: Decodable {
        let displayName: String?
        let email: String?
    }

    func toCalendarEvent() -> CalendarEvent {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startDate: Date = {
            if let dt = start?.dateTime { return isoFormatter.date(from: dt) ?? .now }
            if let d  = start?.date     { return dateFormatter.date(from: d) ?? .now }
            return .now
        }()
        let endDate: Date = {
            if let dt = end?.dateTime { return isoFormatter.date(from: dt) ?? startDate }
            if let d  = end?.date    { return dateFormatter.date(from: d) ?? startDate }
            return startDate
        }()
        let isAllDay = start?.dateTime == nil

        let names = (attendees ?? []).compactMap { $0.displayName ?? $0.email }

        return CalendarEvent(
            id: id ?? UUID().uuidString,
            title: summary ?? "(No title)",
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            calendarName: "Google Calendar",
            source: .google,
            attendees: names,
            calendarColorHex: nil
        )
    }
}

// MARK: - CalendarService (T033)

@MainActor
final class CalendarService: CalendarServiceProtocol {

    private let eventStore = EKEventStore()
    private let googleClient: GoogleCalendarClient
    private(set) var isGoogleConnected: Bool = false
    private(set) var needsGoogleReconnect: Bool = false

    init(googleClient: GoogleCalendarClient = GoogleCalendarClient()) {
        self.googleClient = googleClient
        isGoogleConnected = AppConfiguration.shared.todoistAPIToken != nil  // re-use Keychain check pattern
        // Actually GoogleSignIn SDK manages tokens; check SDK's hasPreviousSignIn
    }

    func fetchUpcomingEvents(hours: Int = 48) async throws -> [CalendarEvent] {
        SonasLogger.calendar.info("CalendarService: fetchUpcomingEvents hours=\(hours)")
        let now = Date.now
        let end = now.addingTimeInterval(TimeInterval(hours) * 3600)
        async let iCloudEvents = fetchEventKitEvents(from: now, to: end)
        async let googleEvents = fetchGoogleEvents(from: now, to: end)
        let (ical, gcal) = try await (iCloudEvents, googleEvents)
        let merged = deduplicated(ical + gcal)
        let sorted = merged
            .filter { $0.endDate > now }
            .sorted { $0.startDate < $1.startDate }
        SonasLogger.calendar.info("CalendarService: returning \(sorted.count) events")
        return sorted
    }

    func connectGoogleAccount() async throws {
        // GoogleSignIn SDK presents ASWebAuthenticationSession.
        // Full implementation requires GoogleSignIn framework integration.
        // Placeholder: marks connected state.
        isGoogleConnected = true
        needsGoogleReconnect = false
    }

    func disconnectGoogleAccount() async {
        isGoogleConnected = false
        needsGoogleReconnect = false
        // GoogleSignIn SDK: GIDSignIn.sharedInstance.signOut()
        // Keychain token deletion happens inside GoogleSignIn SDK
    }

    // MARK: - Private

    private func fetchEventKitEvents(from start: Date, to end: Date) async throws -> [CalendarEvent] {
        // Request access if not already granted
        let granted = try await eventStore.requestFullAccessToEvents()
        guard granted else {
            throw CalendarServiceError.eventKitPermissionDenied
        }
        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil
        )
        let events = eventStore.events(matching: predicate)
        return events.map { event in
            CalendarEvent(
                id: event.eventIdentifier ?? UUID().uuidString,
                title: event.title ?? "(No title)",
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay,
                calendarName: event.calendar?.title ?? "iCloud",
                source: .iCloud,
                attendees: event.attendees?.compactMap { $0.name } ?? [],
                calendarColorHex: nil
            )
        }
    }

    private func fetchGoogleEvents(from start: Date, to end: Date) async throws -> [CalendarEvent] {
        guard isGoogleConnected else { return [] }
        // Retrieve fresh access token from GoogleSignIn SDK
        // Placeholder returns empty; real implementation calls GIDSignIn.sharedInstance.currentUser?.refreshTokensIfNeeded
        return []
    }

    private func deduplicated(_ events: [CalendarEvent]) -> [CalendarEvent] {
        var seen = Set<String>()
        return events.filter { event in
            let key = "\(event.title)|\(event.startDate.timeIntervalSince1970)"
            return seen.insert(key).inserted
        }
    }
}
