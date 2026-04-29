import SwiftUI

// MARK: - TVPanelDetailView

/// Full-screen detail view for a selected panel.
struct TVPanelDetailView: View {
    let section: AppSection
    let shell: TVShell

    var body: some View {
        Group {
            switch section {
            case .weather:
                Text("Weather Detail")
                    .font(.largeTitle)
            case .calendar:
                Text("Calendar Detail")
                    .font(.largeTitle)
            case .tasks:
                Text("Tasks Detail")
                    .font(.largeTitle)
            case .location:
                Text("Location Detail")
                    .font(.largeTitle)
            case .jam:
                Text("Jam Detail")
                    .font(.largeTitle)
            case .photos:
                Text("Photos Detail")
                    .font(.largeTitle)
            case .settings:
                Text("Settings")
                    .font(.largeTitle)
            case .dashboard:
                Text("Dashboard")
                    .font(.largeTitle)
            }
        }
    }
}
