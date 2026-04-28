@preconcurrency import EventKit
import Foundation
@preconcurrency import GoogleSignIn
#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

// MARK: - CalendarServiceProtocol (T027)

@MainActor
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
    case missingConfiguration(String)

    var errorDescription: String? {
        switch self {
        case .eventKitPermissionDenied:
            "Calendar access is required to show your events. Enable it in Settings."
        case let .googleAuthFailed(err):
            "Google Calendar connection failed: \(err.localizedDescription)"
        case let .fetchFailed(err):
            "Could not load calendar events: \(err.localizedDescription)"
        case let .missingConfiguration(key):
            "Missing configuration: \(key). See SETUP.md."
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
        timeMax: Date,
    ) async throws -> [CalendarEvent] {
        guard var components = URLComponents(string: Endpoint.events) else {
            throw CalendarServiceError.fetchFailed(NSError(domain: "GoogleCalendar", code: -1))
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        components.queryItems = [
            .init(name: "timeMin", value: formatter.string(from: timeMin)),
            .init(name: "timeMax", value: formatter.string(from: timeMax)),
            .init(name: "singleEvents", value: "true"),
            .init(name: "orderBy", value: "startTime"),
            .init(name: "maxResults", value: "50")
        ]

        guard let url = components.url else {
            throw CalendarServiceError.fetchFailed(NSError(domain: "GoogleCalendar", code: -1))
        }
        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            throw CalendarServiceError.googleAuthFailed(
                NSError(domain: "GoogleCalendar", code: 401, userInfo: [NSLocalizedDescriptionKey: "Token expired"]),
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
            if let dateTime = start?.dateTime { return isoFormatter.date(from: dateTime) ?? .now }
            if let date = start?.date { return dateFormatter.date(from: date) ?? .now }
            return .now
        }()
        let endDate: Date = {
            if let dateTime = end?.dateTime { return isoFormatter.date(from: dateTime) ?? startDate }
            if let date = end?.date { return dateFormatter.date(from: date) ?? startDate }
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
            calendarColorHex: nil,
        )
    }
}

// MARK: - CalendarService (T033)

@MainActor
final class CalendarService: CalendarServiceProtocol {
    private let eventStore = EKEventStore()
    private let googleClient: GoogleCalendarClient
    private(set) var isGoogleConnected: Bool
    private(set) var needsGoogleReconnect: Bool = false

    init(googleClient: GoogleCalendarClient = GoogleCalendarClient()) {
        self.googleClient = googleClient
        isGoogleConnected = GIDSignIn.sharedInstance.hasPreviousSignIn()
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
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
              !clientID.isEmpty
        else {
            throw CalendarServiceError.missingConfiguration("GIDClientID in Info.plist")
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        #if os(macOS)
            guard let presenting = rootWindow() else {
                throw CalendarServiceError.googleAuthFailed(
                    NSError(
                        domain: "GoogleSignIn",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "No presenting window available"]
                    )
                )
            }
        #else
            guard let presenting = rootViewController() else {
                throw CalendarServiceError.googleAuthFailed(
                    NSError(
                        domain: "GoogleSignIn",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "No presenting view controller available"]
                    )
                )
            }
        #endif

        do {
            _ = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: presenting,
                hint: nil,
                additionalScopes: ["https://www.googleapis.com/auth/calendar.readonly"]
            )
            isGoogleConnected = true
            needsGoogleReconnect = false
            SonasLogger.calendar.info("CalendarService: Google account connected")
        } catch {
            throw CalendarServiceError.googleAuthFailed(error)
        }
    }

    func disconnectGoogleAccount() async {
        GIDSignIn.sharedInstance.signOut()
        isGoogleConnected = false
        needsGoogleReconnect = false
        SonasLogger.calendar.info("CalendarService: Google account disconnected")
    }

    // MARK: - Private

    private func fetchEventKitEvents(from start: Date, to end: Date) async throws -> [CalendarEvent] {
        let granted = try await eventStore.requestFullAccessToEvents()
        guard granted else {
            throw CalendarServiceError.eventKitPermissionDenied
        }
        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil,
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
                attendees: event.attendees?.compactMap(\.name) ?? [],
                calendarColorHex: nil,
            )
        }
    }

    private func fetchGoogleEvents(from start: Date, to end: Date) async throws -> [CalendarEvent] {
        guard isGoogleConnected else { return [] }

        // Silently restore a previous sign-in if we have credentials but no active user.
        if GIDSignIn.sharedInstance.currentUser == nil {
            do {
                try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            } catch {
                needsGoogleReconnect = true
                isGoogleConnected = false
                SonasLogger.calendar.info("CalendarService: silent restore failed — reconnect needed")
                return []
            }
        }

        guard let user = GIDSignIn.sharedInstance.currentUser else {
            needsGoogleReconnect = true
            isGoogleConnected = false
            return []
        }

        do {
            let refreshedUser = try await user.refreshTokensIfNeeded()
            let token = refreshedUser.accessToken.tokenString
            return try await googleClient.fetchEvents(accessToken: token, timeMin: start, timeMax: end)
        } catch let calendarError as CalendarServiceError {
            // HTTP 401 from the REST client — token is invalid despite successful refresh
            if case .googleAuthFailed = calendarError {
                needsGoogleReconnect = true
                isGoogleConnected = false
            }
            throw calendarError
        } catch {
            // GIDSignIn token-refresh errors
            let nsError = error as NSError
            let isAuthError = nsError.domain == "com.google.GIDSignIn" &&
                (nsError.code == -4 || nsError.code == -7) // hasNoAuthInKeychain, noCurrentUser
            if isAuthError {
                needsGoogleReconnect = true
                isGoogleConnected = false
                SonasLogger.calendar.info("CalendarService: token refresh auth failure — reconnect needed")
                return []
            }
            throw CalendarServiceError.fetchFailed(error)
        }
    }

    #if os(macOS)
        private func rootWindow() -> NSWindow? {
            NSApplication.shared.windows
                .first { $0.isKeyWindow }
        }
    #else
        private func rootViewController() -> UIViewController? {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }?
                .windows
                .first(where: \.isKeyWindow)?
                .rootViewController
        }
    #endif

    private func deduplicated(_ events: [CalendarEvent]) -> [CalendarEvent] {
        var seen = Set<String>()
        return events.filter { event in
            let key = "\(event.title)|\(event.startDate.timeIntervalSince1970)"
            return seen.insert(key).inserted
        }
    }
}
