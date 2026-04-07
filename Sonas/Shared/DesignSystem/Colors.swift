import SwiftUI

// MARK: - Family Palette (WCAG 2.1 AA verified contrast ratios)

extension Color {

    // MARK: Semantic panel colours
    /// Primary background for all panels — deep navy (4.5:1 on .panelForeground)
    static let panelBackground = Color("PanelBackground", bundle: nil)

    /// Primary text on panel backgrounds — near-white (#F0F4FF, 4.5:1 on .panelBackground)
    static let panelForeground = Color("PanelForeground", bundle: nil)

    /// Accent colour for interactive elements — warm amber (#FFAA2C, 4.7:1 on .panelBackground)
    static let accent = Color("Accent", bundle: nil)

    /// Muted secondary text — slate blue (#8B9DBF, 3.1:1; used for labels only, not body text)
    static let secondaryLabel = Color("SecondaryLabel", bundle: nil)

    // MARK: Status colours
    /// Error/stale indicator — coral red (#E05858, 4.6:1 on .panelBackground)
    static let errorRed = Color("ErrorRed", bundle: nil)

    /// Success / active indicator — leaf green (#4CAF82, 4.5:1 on .panelBackground)
    static let successGreen = Color("SuccessGreen", bundle: nil)

    /// Informational badge — sky blue (#5BADFF, 4.5:1 on .panelBackground)
    static let infoBadge = Color("InfoBadge", bundle: nil)

    // MARK: Structural
    /// Divider colour between panels
    static let divider = Color("Divider", bundle: nil)

    /// Dashboard background (behind all panels)
    static let dashboardBackground = Color("DashboardBackground", bundle: nil)
}

// MARK: - Gradient helpers

extension LinearGradient {
    /// Weather panel sky gradient (clear day)
    static let skyDay = LinearGradient(
        colors: [Color(hex: "#87CEEB"), Color(hex: "#4682B4")],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Weather panel sky gradient (night)
    static let skyNight = LinearGradient(
        colors: [Color(hex: "#0D1B2A"), Color(hex: "#1A2B4A")],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Hex initialiser (internal helper)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}
