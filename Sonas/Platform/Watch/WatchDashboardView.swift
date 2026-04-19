import SwiftUI

// MARK: - WatchDashboardView (T078)

// Compact glance: live clock, ≤2 family member first names + places, next event title.
// Uses TimelineView for live clock; .containerBackground for Watch complication registration.

struct WatchDashboardView: View {
    let members: [FamilyMember]
    let nextEvent: CalendarEvent?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            clockRow
            Divider()
            locationRows
            if let event = nextEvent {
                Divider()
                eventRow(event: event)
            }
        }
        #if os(watchOS)
        .containerBackground(Color.dashboardBackground.gradient, for: .tabView)
        #endif
    }

    // MARK: - Clock

    private var clockRow: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(context.date, format: .dateTime.hour().minute())
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Color.panelForeground)
                .monospacedDigit()
                .accessibilityLabel("Current time: \(context.date.formatted(.dateTime.hour().minute()))")
        }
    }

    // MARK: - Location rows (max 2)

    private var locationRows: some View {
        ForEach(members.prefix(2)) { member in
            HStack(spacing: 4) {
                Image(systemName: Icon.location)
                    .font(.caption2)
                    .foregroundStyle(member.isStale ? Color.secondaryLabel : Color.successGreen)
                    .accessibilityHidden(true)
                Text(member.displayName)
                    .font(.caption)
                    .foregroundStyle(Color.panelForeground)
                    .lineLimit(1)
                Spacer()
                Text(member.location?.ageLabel.components(separatedBy: ",").first ?? "—")
                    .font(.caption2)
                    .foregroundStyle(Color.secondaryLabel)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(member.displayName): \(member.location?.ageLabel ?? "unavailable")")
        }
    }

    // MARK: - Next event

    private func eventRow(event: CalendarEvent) -> some View {
        HStack(spacing: 4) {
            Image(systemName: Icon.calendar)
                .font(.caption2)
                .foregroundStyle(Color.accent)
                .accessibilityHidden(true)
            Text(event.title)
                .font(.caption)
                .foregroundStyle(Color.panelForeground)
                .lineLimit(1)
        }
        .accessibilityLabel("Next event: \(event.title) at \(event.formattedTime)")
    }
}
