import Foundation

// MARK: - CalendarServiceError

enum CalendarServiceError: LocalizedError {
    case eventKitPermissionDenied
    case googleAuthFailed(Error)
    case fetchFailed(Error)
    case missingConfiguration(String)

    var errorDescription: String? {
        switch self {
        case .eventKitPermissionDenied:
            "Calendar access denied"
        case let .googleAuthFailed(error):
            "Google auth failed: \(error.localizedDescription)"
        case let .fetchFailed(error):
            "Fetch failed: \(error.localizedDescription)"
        case let .missingConfiguration(key):
            "Missing configuration: \(key)"
        }
    }
}

// MARK: - TVCalendarClientProtocol

protocol TVCalendarClientProtocol: AnyObject, Sendable {
    func fetchEvents(from start: Date, to end: Date) async throws -> [CalendarEvent]
}

// MARK: - GoogleCalendarClient

final class GoogleCalendarClient: Sendable, TVCalendarClientProtocol {
    private enum Endpoint {
        static let events = "https://www.googleapis.com/calendar/v3/calendars/primary/events"
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchEvents(from start: Date, to end: Date) async throws -> [CalendarEvent] {
        // MARK: fetch logic

        let token = UserDefaults.standard.string(forKey: "google_access_token")
        guard let accessToken = token, !accessToken.isEmpty else {
            throw CalendarServiceError.googleAuthFailed(
                NSError(domain: "GC", code: 401)
            )
        }

        guard let url = buildURL(from: start, to: end) else {
            throw CalendarServiceError.fetchFailed(NSError(domain: "GC", code: -1))
        }

        let data = try await performRequest(url: url, token: accessToken)
        return parseEvents(from: data)
    }

    // MARK: - Helper Methods

    private func buildURL(from start: Date, to end: Date) -> URL? {
        guard var components = URLComponents(string: Endpoint.events) else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        components.queryItems = [
            .init(name: "timeMin", value: formatter.string(from: start)),
            .init(name: "timeMax", value: formatter.string(from: end)),
            .init(name: "singleEvents", value: "true"),
            .init(name: "orderBy", value: "startTime"),
            .init(name: "maxResults", value: "50")
        ]

        return components.url
    }

    private func performRequest(url: URL, token: String) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CalendarServiceError.fetchFailed(NSError(domain: "GC", code: -1))
        }

        if httpResponse.statusCode == 401 {
            throw CalendarServiceError.googleAuthFailed(NSError(domain: "GC", code: 401))
        }

        guard httpResponse.statusCode == 200 else {
            throw CalendarServiceError.fetchFailed(NSError(domain: "GC", code: httpResponse.statusCode))
        }

        return data
    }

    private func parseEvents(from data: Data) -> [CalendarEvent] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]]
        else {
            return []
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        return items.compactMap { item -> CalendarEvent? in
            guard let id = item["id"] as? String,
                  let summary = item["summary"] as? String,
                  let startDict = item["start"] as? [String: Any],
                  let startString = startDict["dateTime"] as? String ?? startDict["date"] as? String,
                  let startDate = formatter.date(from: startString),
                  let endDict = item["end"] as? [String: Any],
                  let endString = endDict["dateTime"] as? String ?? endDict["date"] as? String,
                  let endDate = formatter.date(from: endString)
            else {
                return nil
            }

            return CalendarEvent(
                id: id,
                title: summary,
                startDate: startDate,
                endDate: endDate,
                isAllDay: startDict["date"] != nil,
                calendarName: "Google",
                source: .google,
                attendees: [],
                calendarColorHex: "#4285F4"
            )
        }
    }
}

// MARK: - TVCalendarServiceProtocol

@MainActor
protocol TVCalendarServiceProtocol: AnyObject, Sendable {
    func fetchUpcomingEvents(hours: Int) async throws -> [CalendarEvent]
    var isGoogleConnected: Bool { get }
    var needsReauth: Bool { get }
}

// MARK: - TVCalendarService

@MainActor
final class TVCalendarService: TVCalendarServiceProtocol {
    private let client: TVCalendarClientProtocol
    private let tokenKey = "google_access_token"

    private(set) var isGoogleConnected: Bool = false
    private(set) var needsReauth: Bool = false

    init(client: TVCalendarClientProtocol = GoogleCalendarClient()) {
        self.client = client
        isGoogleConnected = UserDefaults.standard.string(forKey: tokenKey) != nil
    }

    func fetchUpcomingEvents(hours: Int = 48) async throws -> [CalendarEvent] {
        guard isGoogleConnected else {
            throw CalendarServiceError.googleAuthFailed(
                NSError(domain: "TVCS", code: -1)
            )
        }

        let now = Date.now
        let end = now.addingTimeInterval(TimeInterval(hours) * 3600)

        do {
            let events = try await client.fetchEvents(from: now, to: end)
            needsReauth = false
            return events.sorted { $0.startDate < $1.startDate }
        } catch let error as CalendarServiceError {
            if case .googleAuthFailed = error {
                needsReauth = true
            }
            throw error
        } catch {
            let nsError = error as NSError
            if nsError.code == 401 {
                needsReauth = true
                throw CalendarServiceError.googleAuthFailed(error)
            }
            throw CalendarServiceError.fetchFailed(error)
        }
    }
}
