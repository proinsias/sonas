import SwiftUI

// MARK: - Dynamic Type Scale Definitions

// All text styles use system font to respect user's Dynamic Type preferences.
// Custom sizes are clamped so layout remains legible at all accessibility sizes.

extension Font {
    // MARK: Panel titles

    /// Large title for panel headers (e.g., "Weather", "Tasks")
    static let panelTitle: Font = .title2.weight(.semibold)

    /// Section header within a panel
    static let sectionHeader: Font = .headline

    // MARK: Data display

    /// Primary data value — large prominent display (e.g., temperature "22°")
    static let dataLarge: Font = .system(.largeTitle, design: .rounded).weight(.bold)

    /// Secondary data value (e.g., humidity "68%")
    static let dataMedium: Font = .system(.title3, design: .rounded).weight(.medium)

    /// Supplementary data label (e.g., "Feels like 19°")
    static let dataSmall: Font = .system(.callout, design: .rounded)

    // MARK: Body and labels

    /// Standard body text for event titles, task names, member names
    static let body: Font = .body

    /// Secondary descriptive text (e.g., "at home", "due tomorrow")
    static let caption: Font = .caption

    /// Fine print — timestamps, "Last updated" badges
    static let timestamp: Font = .caption2

    // MARK: Interactive elements

    /// Button label text
    static let buttonLabel: Font = .callout.weight(.medium)
}

// MARK: - Line spacing constants

extension CGFloat {
    /// Standard line spacing for list rows in panels
    static let rowLineSpacing: CGFloat = 4
    /// Tight line spacing for data displays
    static let dataLineSpacing: CGFloat = 2
}
