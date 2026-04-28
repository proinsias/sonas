import Foundation
import Observation

// MARK: - EventsViewModel (T038)

@Observable
@MainActor
final class EventsViewModel {
    // MARK: Published state

    private(set) var events: [CalendarEvent] = []
    private(set) var isLoading: Bool = true
    private(set) var error: PanelError?
    private(set) var isGoogleConnected: Bool
    private(set) var needsGoogleReconnect: Bool = false

    // MARK: Dependencies

    private let service: any CalendarServiceProtocol

    init(service: any CalendarServiceProtocol) {
        self.service = service
        isGoogleConnected = service.isGoogleConnected
    }

    // MARK: - Data loading

    func load() async {
        isLoading = true
        error = nil
        do {
            events = try await service.fetchUpcomingEvents(hours: 48)
            isGoogleConnected = service.isGoogleConnected
            needsGoogleReconnect = service.needsGoogleReconnect

            #if os(macOS)
                for event in events {
                    Task {
                        await MacNotificationService.shared.scheduleCalendarReminder(
                            eventTitle: event.title,
                            startDate: event.startDate
                        )
                    }
                }
            #endif
        } catch CalendarServiceError.eventKitPermissionDenied {
            error = .permissionDenied
        } catch {
            self.error = PanelError(
                title: "Calendar Unavailable",
                message: error.localizedDescription,
                isRetryable: true,
            )
        }
        isLoading = false
    }

    func refresh() async {
        await load()
    }

    func disconnectGoogle() async {
        await service.disconnectGoogleAccount()
        isGoogleConnected = false
        needsGoogleReconnect = false
        events = []
    }

    func reconnectGoogle() async {
        do {
            try await service.connectGoogleAccount()
            isGoogleConnected = true
            needsGoogleReconnect = false
            await load()
        } catch {
            self.error = PanelError(
                title: "Google Connection Failed",
                message: error.localizedDescription,
                isRetryable: true,
            )
        }
    }
}
