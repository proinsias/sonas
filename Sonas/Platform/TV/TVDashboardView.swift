import SwiftUI

// MARK: - TVDashboardView (T079)
// Lean-back full-screen layout for Apple TV.
// Self-contained: uses only Sonas/Platform/TV + Sonas/Shared (excluding Mocks, which the
// TV target omits). Fixture data is inlined here rather than pulled from mock classes.

struct TVDashboardView: View {

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: .init(.flexible(), spacing: 20), count: 3),
            spacing: 20
        ) {
            TVClockPanel()
            TVWeatherPanel()
            TVEventsPanel()
        }
        .padding(40)
        .background(Color.dashboardBackground.ignoresSafeArea())
    }
}

// MARK: - Clock

private struct TVClockPanel: View {
    var body: some View {
        PanelView(title: "Now", icon: "clock") {
            TimelineView(.everyMinute) { context in
                VStack(spacing: 8) {
                    Text(context.date, format: .dateTime.hour().minute())
                        .font(.system(size: 56, weight: .thin, design: .rounded))
                        .foregroundStyle(Color.panelForeground)
                    Text(context.date, format: .dateTime.weekday(.wide).month().day())
                        .font(.headline)
                        .foregroundStyle(Color.secondaryLabel)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .focusable()
    }
}

// MARK: - Weather
// Fixture data inlined — the TV target excludes Sonas/Shared/Mocks.

private struct TVWeatherPanel: View {

    // Static fixture — replaced by a real WeatherService call when the TV target
    // gains WeatherKit entitlement support.
    private static let fixture = TVWeatherFixture(
        temperature: 18.5,
        conditionDescription: "Partly Cloudy",
        conditionSymbolName: "cloud.sun.fill",
        humidity: 0.72,
        windSpeed: 22.0
    )

    var body: some View {
        PanelView(title: "Weather", icon: "cloud.sun.fill") {
            let w = Self.fixture
            VStack(spacing: 12) {
                Image(systemName: w.conditionSymbolName)
                    .font(.system(size: 44))
                    .foregroundStyle(Color.accent)
                Text(String(format: "%.0f°", w.temperature))
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .foregroundStyle(Color.panelForeground)
                Text(w.conditionDescription)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryLabel)
                HStack(spacing: 16) {
                    Label(String(format: "%.0f%%", w.humidity * 100), systemImage: "humidity")
                    Label(String(format: "%.0f km/h", w.windSpeed), systemImage: "wind")
                }
                .font(.caption)
                .foregroundStyle(Color.secondaryLabel)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .focusable()
        .accessibilityIdentifier("WeatherPanel")
    }
}

private struct TVWeatherFixture {
    let temperature: Double
    let conditionDescription: String
    let conditionSymbolName: String
    let humidity: Double
    let windSpeed: Double
}

// MARK: - Events
// Fixture data inlined — the TV target excludes Sonas/Shared/Mocks.

private struct TVEventsPanel: View {

    private static let fixtures: [TVEventFixture] = [
        TVEventFixture(title: "Family Dinner",
                       time: Calendar.current.date(byAdding: .hour, value: 3, to: .now)!),
        TVEventFixture(title: "School Run",
                       time: Calendar.current.date(byAdding: .hour, value: 8, to: .now)!),
        TVEventFixture(title: "Weekend Hiking",
                       time: Calendar.current.date(byAdding: .day, value: 1, to: .now)!),
    ]

    var body: some View {
        PanelView(title: "Coming Up", icon: "calendar") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Self.fixtures) { event in
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(Color.accent)
                            .frame(width: 3)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.subheadline)
                                .foregroundStyle(Color.panelForeground)
                                .lineLimit(1)
                            Text(event.time, format: .dateTime.weekday(.abbreviated).hour().minute())
                                .font(.caption)
                                .foregroundStyle(Color.secondaryLabel)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
        .focusable()
        .accessibilityIdentifier("EventsPanel")
    }
}

private struct TVEventFixture: Identifiable {
    let id = UUID()
    let title: String
    let time: Date
}
