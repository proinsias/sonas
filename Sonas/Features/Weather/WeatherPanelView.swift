import SwiftUI

// MARK: - WeatherPanelView (T050)

// All 8 required attributes visible without scroll on standard iPhone.
// 7-day forecast strip with high/low + SF Symbol per day.

struct WeatherPanelView: View {
    @State var viewModel: WeatherViewModel

    var body: some View {
        PanelView(
            title: "Weather",
            icon: Icon.weather,
            lastUpdated: viewModel.lastUpdated,
        ) {
            content
        }
        .task { await viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading, viewModel.snapshot == nil {
            LoadingStateView(rows: 4, showsLargeBlock: true)
        } else if let error = viewModel.error, viewModel.snapshot == nil {
            ErrorStateView(error: error) { Swift.Task { await viewModel.refresh() } }
        } else if let snapshot = viewModel.snapshot {
            weatherContent(snapshot: snapshot)
                .staleDataBadge(
                    lastUpdated: viewModel.lastUpdated ?? .now,
                ) { Swift.Task { await viewModel.refresh() } }
        }
    }

    // MARK: - Main weather content

    private func weatherContent(snapshot: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            currentConditionsRow(snapshot: snapshot)
            Divider().background(Color.divider)
            attributeGrid(snapshot: snapshot)
            Divider().background(Color.divider)
            forecastStrip
        }
    }

    // MARK: - Current temperature + condition

    private func currentConditionsRow(snapshot: WeatherSnapshot) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(formattedTemperature(snapshot.temperature))
                    .font(.dataLarge)
                    .foregroundStyle(Color.panelForeground)
                    .accessibilityLabel("Temperature: \(formattedTemperature(snapshot.temperature))")

                Text(snapshot.conditionDescription)
                    .font(.dataMedium)
                    .foregroundStyle(Color.secondaryLabel)

                Text("Feels like \(formattedTemperature(snapshot.feelsLike))")
                    .font(.dataSmall)
                    .foregroundStyle(Color.secondaryLabel)
            }

            Spacer()

            Image(systemName: snapshot.conditionSymbolName)
                .font(.system(size: 48))
                .symbolRenderingMode(.multicolor)
                .accessibilityLabel(snapshot.conditionDescription)
        }
    }

    // MARK: - 6-attribute grid (humidity, wind, pressure, AQI, sunrise, sunset)

    private func attributeGrid(snapshot: WeatherSnapshot) -> some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible())], spacing: 10) {
            WeatherAttributeCell(
                icon: Icon.humidity,
                label: "Humidity",
                value: String(format: "%.0f%%", snapshot.humidity * 100),
            )
            WeatherAttributeCell(
                icon: Icon.windSpeed,
                label: "Wind",
                value: "\(String(format: "%.0f", snapshot.windSpeed)) km/h \(snapshot.windCompassLabel)",
            )
            WeatherAttributeCell(
                icon: Icon.pressure,
                label: "Pressure",
                value: "\(String(format: "%.0f", snapshot.pressure)) hPa",
            )
            if let aqi = snapshot.airQualityIndex {
                WeatherAttributeCell(
                    icon: Icon.airQuality,
                    label: "AQI",
                    value: "\(aqi) – \(snapshot.aiqCategory?.label ?? "")",
                )
            }
            WeatherAttributeCell(
                icon: Icon.sunrise,
                label: "Sunrise",
                value: snapshot.sunriseTime.formatted(.dateTime.hour().minute()),
            )
            WeatherAttributeCell(
                icon: Icon.sunset,
                label: "Sunset",
                value: snapshot.sunsetTime.formatted(.dateTime.hour().minute()),
            )
            WeatherAttributeCell(
                icon: snapshot.moonPhase.symbolName,
                label: "Moon",
                value: snapshot.moonPhase.displayName,
            )
        }
    }

    // MARK: - 7-day forecast strip

    private var forecastStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.forecast) { day in
                    ForecastDayCell(day: day)
                }
            }
        }
    }

    // MARK: - Unit formatting

    private func formattedTemperature(_ celsius: Double) -> String {
        let config = AppConfiguration.shared
        if config.useFahrenheit {
            return String(format: "%.0f°F", celsius * 9 / 5 + 32)
        }
        return String(format: "%.0f°C", celsius)
    }
}

// MARK: - WeatherAttributeCell

private struct WeatherAttributeCell: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(.body))
                .foregroundStyle(Color.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(.dataSmall)
                .foregroundStyle(Color.panelForeground)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.timestamp)
                .foregroundStyle(Color.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - ForecastDayCell

private struct ForecastDayCell: View {
    let day: DayForecast

    var body: some View {
        VStack(spacing: 4) {
            Text(day.date, format: .dateTime.weekday(.abbreviated))
                .font(.timestamp)
                .foregroundStyle(Color.secondaryLabel)

            Image(systemName: day.conditionSymbolName)
                .font(.system(.callout))
                .symbolRenderingMode(.multicolor)
                .accessibilityLabel(day.conditionDescription)

            Text(String(format: "%.0f°", day.highTemperature))
                .font(.dataSmall)
                .foregroundStyle(Color.panelForeground)

            Text(String(format: "%.0f°", day.lowTemperature))
                .font(.timestamp)
                .foregroundStyle(Color.secondaryLabel)
        }
        .frame(width: 48)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(day.date.formatted(.dateTime.weekday(.wide))): "
                + "high \(String(format: "%.0f", day.highTemperature)) "
                + "low \(String(format: "%.0f", day.lowTemperature)) degrees, "
                + day.conditionDescription,
        )
    }
}
