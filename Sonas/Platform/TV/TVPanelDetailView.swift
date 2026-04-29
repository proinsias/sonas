import SwiftUI

// MARK: - TVPanelDetailView (T020)

struct TVPanelDetailView: View {
    let section: AppSection
    let shell: TVShell

    var body: some View {
        Group {
            switch section {
            case .weather:
                TVWeatherDetailView(vm: shell.weatherVM)
                    .navigationTitle("Weather")
                    .accessibilityIdentifier("WeatherDetailView")
            case .calendar:
                TVCalendarDetailView(
                    events: shell.calendarEvents,
                    isLoading: shell.isCalendarLoading
                )
                .navigationTitle("Coming Up")
                .accessibilityIdentifier("CalendarDetailView")
            case .location:
                TVLocationDetailView(vm: shell.locationVM)
                    .navigationTitle("Family")
                    .accessibilityIdentifier("LocationDetailView")
            case .photos:
                TVPhotoDetailView(vm: shell.photoVM)
                    .navigationTitle("Photos")
                    .accessibilityIdentifier("PhotoDetailView")
            case .jam:
                TVJamDetailView(track: shell.currentTrack)
                    .navigationTitle("Now Playing")
                    .accessibilityIdentifier("JamDetailView")
            case .tasks, .settings, .dashboard:
                EmptyView()
            }
        }
    }
}

// MARK: - Weather Detail (T021)

private struct TVWeatherDetailView: View {
    let vm: WeatherViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 48) {
                if let snapshot = vm.snapshot {
                    currentConditions(snapshot)
                    if !vm.forecast.isEmpty {
                        Divider()
                        forecastStrip(vm.forecast)
                    }
                } else if vm.isLoading {
                    ProgressView("Loading weather…")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    Text("Weather unavailable")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                }
            }
            .padding(60)
        }
    }

    private func currentConditions(_ snapshot: WeatherSnapshot) -> some View {
        HStack(alignment: .top, spacing: 60) {
            TVWeatherCurrentView(snapshot: snapshot)
            Spacer()
            TVWeatherConditionsPanel(snapshot: snapshot)
        }
    }

    private func forecastStrip(_ days: [DayForecast]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("7-Day Forecast")
                .font(.title2)
                .fontWeight(.semibold)
            HStack(spacing: 0) {
                ForEach(days.prefix(7)) { day in
                    TVForecastDayView(day: day)
                }
            }
        }
    }
}

private struct TVWeatherCurrentView: View {
    let snapshot: WeatherSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(Int(snapshot.temperature.rounded()))°")
                    .font(.system(size: 96, weight: .thin))
                Image(systemName: snapshot.conditionSymbolName)
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
            }
            Text(snapshot.conditionDescription)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Feels like \(Int(snapshot.feelsLike.rounded()))°")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct TVWeatherConditionsPanel: View {
    let snapshot: WeatherSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            TVWeatherMetric(
                icon: "humidity",
                label: "Humidity",
                value: "\(Int(snapshot.humidity * 100))%"
            )
            TVWeatherMetric(
                icon: "wind",
                label: "Wind",
                value: "\(Int(snapshot.windSpeed)) km/h \(snapshot.windCompassLabel)"
            )
            TVWeatherMetric(
                icon: "gauge",
                label: "Pressure",
                value: "\(Int(snapshot.pressure)) hPa · \(snapshot.pressureTrend.rawValue)"
            )
            TVWeatherMetric(
                icon: "sunrise.fill",
                label: "Sunrise",
                value: snapshot.sunriseTime.formatted(.dateTime.hour().minute())
            )
            TVWeatherMetric(
                icon: "sunset.fill",
                label: "Sunset",
                value: snapshot.sunsetTime.formatted(.dateTime.hour().minute())
            )
        }
    }
}

private struct TVWeatherMetric: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 28)
                .foregroundStyle(Color.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
}

private struct TVForecastDayView: View {
    let day: DayForecast

    var body: some View {
        VStack(spacing: 10) {
            Text(day.date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.headline)
                .foregroundStyle(.secondary)
            Image(systemName: day.conditionSymbolName)
                .font(.title)
                .foregroundStyle(Color.accent)
            Text("\(Int(day.highTemperature.rounded()))°")
                .font(.title2)
                .fontWeight(.medium)
            Text("\(Int(day.lowTemperature.rounded()))°")
                .font(.headline)
                .foregroundStyle(.secondary)
            if day.precipitationChance > 0.1 {
                Text("\(Int(day.precipitationChance * 100))%")
                    .font(.caption)
                    .foregroundStyle(.blue)
            } else {
                Text(" ")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// MARK: - Calendar Detail (T022)

private struct TVCalendarDetailView: View {
    let events: [CalendarEvent]
    let isLoading: Bool

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading events…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if events.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 72))
                        .foregroundStyle(.secondary)
                    Text("Nothing Coming Up")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(events) { event in
                            TVCalendarEventRow(event: event)
                        }
                    }
                    .padding(60)
                }
            }
        }
    }
}

private struct TVCalendarEventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 24) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(event.startDate.formatted(.dateTime.weekday(.abbreviated).month().day()))
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(event.formattedTime)
                    .font(.subheadline)
                    .foregroundStyle(Color.accent)
            }
            .frame(width: 160, alignment: .trailing)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.title3)
                    .fontWeight(.medium)
                    .lineLimit(2)
                if !event.calendarName.isEmpty {
                    Text(event.calendarName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if !event.attendees.isEmpty {
                    Text(event.attendees.prefix(3).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .background(Color.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
