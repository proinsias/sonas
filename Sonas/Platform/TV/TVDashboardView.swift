import SwiftUI

// MARK: - TVDashboardView (T017)

// Main TV dashboard that embeds TVShell for live data from all services.
// Replaces the previous fixture-data implementation.

struct TVDashboardView: View {
    var body: some View {
        TVShellView()
    }
}
