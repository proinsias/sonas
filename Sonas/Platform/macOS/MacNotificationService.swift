import AppKit
import Foundation
import UserNotifications

protocol UserNotificationCenterProtocol: Sendable {
    var delegate: UNUserNotificationCenterDelegate? { get set }
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func setNotificationCategories(_ categories: Set<UNNotificationCategory>)
    func notificationSettings() async -> UNNotificationSettings
    func add(_ request: UNNotificationRequest) async throws
    func getNotificationCategories() async -> Set<UNNotificationCategory>
}

extension UNUserNotificationCenter: UserNotificationCenterProtocol {}

protocol MacNotificationServiceProtocol: Sendable {
    func register() async
    func scheduleLocationArrival(memberName: String, placeName: String) async
    func scheduleCalendarReminder(eventTitle: String, startDate: Date) async
}

final class MacNotificationService: NSObject, MacNotificationServiceProtocol {
    static let shared = MacNotificationService()

    private var center: UserNotificationCenterProtocol

    private enum Category {
        static let location = "com.sonas.location.arrival"
        static let calendar = "com.sonas.calendar.upcoming"
    }

    private enum Action {
        static let showMap = "show-map"
        static let openCalendar = "open-calendar"
    }

    init(center: UserNotificationCenterProtocol = UNUserNotificationCenter.current()) {
        self.center = center
        super.init()
        self.center.delegate = self
    }

    func register() async {
        // Request authorisation
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            SonasLogger.error(SonasLogger.app, "MacNotificationService: auth request failed", error: error)
        }

        // Register categories
        let locationAction = UNNotificationAction(
            identifier: Action.showMap,
            title: "Show on Map",
            options: .foreground
        )
        let locationCategory = UNNotificationCategory(
            identifier: Category.location,
            actions: [locationAction],
            intentIdentifiers: [],
            options: []
        )

        let calendarAction = UNNotificationAction(
            identifier: Action.openCalendar,
            title: "Open Calendar",
            options: .foreground
        )
        let calendarCategory = UNNotificationCategory(
            identifier: Category.calendar,
            actions: [calendarAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([locationCategory, calendarCategory])
    }

    func scheduleLocationArrival(memberName: String, placeName: String) async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(memberName) arrived"
        content.body = "At \(placeName)"
        content.categoryIdentifier = Category.location
        content.userInfo = ["section": AppSection.location.rawValue]
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "location-\(memberName)-\(Date.now.timeIntervalSince1970)",
            content: content,
            trigger: nil // Immediate
        )

        do {
            try await center.add(request)
        } catch {
            SonasLogger.error(
                SonasLogger.location,
                "MacNotificationService: failed to schedule location arrival",
                error: error
            )
        }
    }

    func scheduleCalendarReminder(eventTitle: String, startDate: Date) async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        else { return }

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event"
        content.body = eventTitle
        content.categoryIdentifier = Category.calendar
        content.userInfo = ["section": AppSection.calendar.rawValue]
        content.sound = .default

        // Fire 15 minutes before
        let triggerDate = startDate.addingTimeInterval(-15 * 60)
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "calendar-\(eventTitle)-\(startDate.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            SonasLogger.error(
                SonasLogger.calendar,
                "MacNotificationService: failed to schedule calendar reminder",
                error: error
            )
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension MacNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let sectionRaw = userInfo["section"] as? String,
           let section = AppSection(rawValue: sectionRaw) {
            DispatchQueue.main.async {
                // Post navigation request
                NotificationCenter.default.post(name: .sonasNavigationRequested, object: section)

                // Bring app to front
                NSApplication.shared.activate(ignoringOtherApps: true)

                // Open window
                NotificationCenter.default.post(name: .sonasWindowOpenRequested, object: nil)
            }
        }
        completionHandler()
    }
}
