import SwiftUI

// MARK: - ClockPanelView (T035)

// Live date/time display using TimelineView, updating every second.

struct ClockPanelView: View {
    var body: some View {
        PanelView(title: "Clock", icon: Icon.clock) {
            TimelineView(.everyMinute) { context in
                clockContent(date: context.date)
            }
        }
    }

    private func clockContent(date: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Day + date line
            Text(date, format: .dateTime.weekday(.wide).month().day())
                .font(.sectionHeader)
                .foregroundStyle(Color.secondaryLabel)
                .accessibilityLabel(date.formatted(.dateTime.weekday(.wide).month().day()))

            // Time — large prominent display, updates every second via inner TimelineView
            TimelineView(.periodic(from: date, by: 1)) { inner in
                Text(inner.date, format: .dateTime.hour().minute().second())
                    .font(.dataLarge)
                    .foregroundStyle(Color.panelForeground)
                    .monospacedDigit()
                    .accessibilityLabel("Current time: \(inner.date.formatted(.dateTime.hour().minute()))")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
