import Foundation

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

    init(client: TVCalendarClientProtocol, isConnected: Bool) {
        self.client = client
        isGoogleConnected = isConnected
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
