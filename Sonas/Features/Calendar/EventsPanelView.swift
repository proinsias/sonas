import SwiftUI

// MARK: - EventsPanelView (T039)

struct EventsPanelView: View {
    @State var viewModel: EventsViewModel

    var body: some View {
        PanelView(title: "Events", icon: Icon.calendar) {
            content
        }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            LoadingStateView(rows: 3)
        } else if let error = viewModel.error {
            ErrorStateView(error: error) {
                Swift.Task { await viewModel.refresh() }
            }
        } else if viewModel.needsGoogleReconnect {
            googleReconnectPrompt
        } else if viewModel.events.isEmpty {
            emptyState
        } else {
            eventList
        }
    }

    // MARK: - Event list (max 3 shown)

    private var eventList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(viewModel.events.prefix(3)) { event in
                EventRow(event: event)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        Text("Nothing scheduled")
            .font(.caption)
            .foregroundStyle(Color.secondaryLabel)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
            .accessibilityLabel("No upcoming events")
    }

    // MARK: - Google reconnect prompt

    private var googleReconnectPrompt: some View {
        VStack(spacing: 8) {
            Text("Google Calendar needs reconnecting.")
                .font(.caption)
                .foregroundStyle(Color.secondaryLabel)
                .multilineTextAlignment(.center)
            Button("Reconnect Google") {
                Swift.Task { await viewModel.reconnectGoogle() }
            }
            .font(.buttonLabel)
            .foregroundStyle(Color.accent)
            .accessibilityInfo("Reconnect Google Calendar", hint: "Re-authorise Google Calendar access")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

// MARK: - EventRow

private struct EventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Calendar colour dot
            Circle()
                .fill(event.calendarColorHex.map { Color(hex: $0) } ?? Color.accent)
                .frame(width: 8, height: 8)
                .padding(.top, 4)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.body)
                    .foregroundStyle(Color.panelForeground)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(event.formattedDateRange)
                        .font(.caption)
                        .foregroundStyle(Color.secondaryLabel)

                    if !event.attendees.isEmpty {
                        Text("· \(event.attendees.prefix(2).joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(Color.secondaryLabel)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Source badge
            Image(systemName: event.source == .google ? "g.circle.fill" : "applelogo")
                .font(.caption2)
                .foregroundStyle(Color.secondaryLabel)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.title), \(event.formattedDateRange)")
    }
}
