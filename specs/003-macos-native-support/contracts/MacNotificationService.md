# Interface Contract: MacNotificationService

**Component**: `MacNotificationService` — macOS Notification Centre integration  
**File**: `Sonas/Platform/macOS/MacNotificationService.swift`

## Responsibilities

- Registers `UNNotificationCategory` instances with action buttons at app launch
- Requests notification authorisation (`alert + sound + badge`)
- Schedules local notifications for location arrivals and upcoming calendar events
- Handles action button taps via `UNUserNotificationCenterDelegate` by posting `.sonasNavigationRequested`

## Protocol

```swift
protocol MacNotificationServiceProtocol: Sendable {
    /// Call once at app startup — registers categories and requests authorisation.
    func register() async

    /// Schedule a location arrival notification for a family member.
    func scheduleLocationArrival(memberName: String, placeName: String) async

    /// Schedule a calendar event reminder (fires 15 minutes before the event).
    func scheduleCalendarReminder(eventTitle: String, startDate: Date) async
}
```

## Notification Categories

| Category                      | Trigger                   | Action          | Deep-link   |
| ----------------------------- | ------------------------- | --------------- | ----------- |
| `com.sonas.location.arrival`  | Location service update   | "Show on Map"   | `.location` |
| `com.sonas.calendar.upcoming` | 15 min before event start | "Open Calendar" | `.calendar` |

## Delegate Behaviour

On `UNUserNotificationCenterDelegate.didReceive(_:withCompletionHandler:)`:

1. Extract `section` string from `notification.request.content.userInfo`
2. Map to `AppSection` (`.location` or `.calendar`)
3. Post `Notification(name: .sonasNavigationRequested, object: appSection)`
4. Call `NSApplication.shared.activate(ignoringOtherApps: true)` to bring app to front
5. Call `openWindow(id: "main")` to ensure a window exists

## Contract Tests (required before implementation)

- `test_register_requestsAuthorisation` — first launch → `requestAuthorization` called with `[.alert, .sound]`
- `test_register_registersCategories` — after `register()` → both categories present in `getNotificationCategories()`
- `test_scheduleLocationArrival_createsRequest` — member + place provided → request has correct title, body, and
  category ID
- `test_didReceiveLocationAction_navigatesToLocation` — action ID `show-map` → `.sonasNavigationRequested` posted with
  `.location`
- `test_didReceiveCalendarAction_navigatesToCalendar` — action ID `open-calendar` → `.sonasNavigationRequested` posted
  with `.calendar`

## Error Handling

- If authorisation is denied: `scheduleLocationArrival` and `scheduleCalendarReminder` are no-ops (checked via
  `UNUserNotificationCenter.notificationSettings()`)
- If a duplicate notification identifier is scheduled: the new request replaces the prior one (`.replace` delivery
  option)
