import SwiftUI

struct MacMenuBarPopoverView: View {
    @Environment(MenuBarState.self) private var state
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            Divider()

            locationSection
            eventSection
            weatherSection

            Divider()

            footer

            if state.isOffline, let lastUpdated = state.lastUpdated {
                Text("Last updated \(lastUpdated.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .frame(width: 280)
        .task {
            await state.refresh()
        }
    }

    private var header: some View {
        HStack {
            Text("Sonas")
                .font(.headline)
            Spacer()
            if state.isOffline {
                Image(systemName: "wifi.slash")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Family Locations")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            if state.familyLocations.isEmpty {
                Text("No data yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(state.familyLocations) { member in
                    HStack {
                        Text(member.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(member.location?.placeName ?? "Unknown")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var eventSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Event")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            if let event = state.nextEvent {
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(event.formattedTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No upcoming events")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weather")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            if let weather = state.weatherSummary {
                HStack(spacing: 12) {
                    Image(systemName: weather.conditionSymbolName)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("\(Int(weather.temperature))°")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text(weather.conditionDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("No weather data")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Open Sonas") {
                openWindow(id: "main")
            }
            .buttonStyle(.borderedProminent)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .font(.caption)
        }
    }
}
