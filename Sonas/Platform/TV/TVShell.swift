import Foundation
import SwiftUI

// MARK: - TVShell

@MainActor
final class TVShell: Observable {}

// MARK: - TVShellView

struct TVShellView: View {
    @State private var shell = TVShell()
    @State private var selectedPanel: AppSection?

    var body: some View {
        NavigationStack {
            LazyVGrid(
                columns: Array(repeating: .init(.flexible(), spacing: 20), count: 3),
                spacing: 20
            ) {
                // Clock Panel
                PanelView(title: "Now", icon: "clock") {
                    TimelineView(.everyMinute) { ctx in
                        VStack(spacing: 8) {
                            Text(ctx.date, format: .dateTime.hour().minute())
                                .font(.system(size: 56, weight: .thin, design: .rounded))
                            Text(ctx.date, format: .dateTime.weekday(.wide).month().day())
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
                .focusable()

                // Weather Panel (stub)
                PanelView(title: "Weather", icon: "cloud.sun.fill") {
                    Text("--°")
                        .font(.system(size: 48, weight: .light))
                }
                .focusable()
                .onTapGesture { selectedPanel = .weather }

                // Calendar Panel
                PanelView(title: "Coming Up", icon: "calendar") {
                    Text("Calendar service ready")
                }
                .focusable()
                .onTapGesture { selectedPanel = .calendar }
            }
            .padding(40)
            .background(Color.dashboardBackground.ignoresSafeArea())
            .navigationDestination(item: $selectedPanel) { section in
                TVPanelDetailView(section: section, shell: shell)
            }
        }
    }
}

// MARK: - AppSection

enum AppSection: String, CaseIterable, Identifiable {
    case weather, calendar, tasks, location, jam, photos, settings

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .weather: "Weather"
        case .calendar: "Calendar"
        case .tasks: "Tasks"
        case .location: "Location"
        case .jam: "Jam"
        case .photos: "Photos"
        case .settings: "Settings"
        }
    }
}
