import SwiftUI

/// Represents every navigable section in the app.
/// Used for sidebar navigation on iPad and as the backing type for keyboard shortcut registration.
enum AppSection: String, CaseIterable, Hashable, Identifiable {
    case dashboard
    case location
    case calendar
    case weather
    case tasks
    case photos
    case jam
    case settings

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .location: "Location"
        case .calendar: "Calendar"
        case .weather: "Weather"
        case .tasks: "Tasks"
        case .photos: "Photos"
        case .jam: "Jam"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: Icon.clock
        case .location: Icon.location
        case .calendar: Icon.calendar
        case .weather: Icon.weather
        case .tasks: Icon.tasks
        case .photos: Icon.photos
        case .jam: Icon.jam
        case .settings: Icon.settings
        }
    }

    #if !os(tvOS)
        var keyboardShortcut: KeyboardShortcut? {
            switch self {
            case .dashboard: KeyboardShortcut("1", modifiers: .command)
            case .location: KeyboardShortcut("2", modifiers: .command)
            case .calendar: KeyboardShortcut("3", modifiers: .command)
            case .weather: KeyboardShortcut("4", modifiers: .command)
            case .tasks: KeyboardShortcut("5", modifiers: .command)
            case .photos: KeyboardShortcut("6", modifiers: .command)
            case .jam: KeyboardShortcut("7", modifiers: .command)
            case .settings: KeyboardShortcut(",", modifiers: .command)
            }
        }
    #endif
}
