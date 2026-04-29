import Foundation
import SwiftUI

// MARK: - TVShell (T016, T019)

@Observable
@MainActor
final class TVShell {
    private(set) var calendarEvents: [CalendarEvent] = []
    private(set) var currentTrack: TVCurrentTrack?
    private(set) var isCalendarLoading = true
    private(set) var calendarNeedsAuth = false

    private let calendarService: TVCalendarServiceProtocol
    let spotifyService: any TVSpotifyReadServiceProtocol
    let weatherVM: WeatherViewModel
    let locationVM: LocationViewModel
    let photoVM: PhotoViewModel

    init(
        calendarService: TVCalendarServiceProtocol,
        spotifyService: any TVSpotifyReadServiceProtocol,
        weatherVM: WeatherViewModel,
        locationVM: LocationViewModel,
        photoVM: PhotoViewModel
    ) {
        self.calendarService = calendarService
        self.spotifyService = spotifyService
        self.weatherVM = weatherVM
        self.locationVM = locationVM
        self.photoVM = photoVM
    }

    static func makeDefault() -> TVShell {
        let useMockCalendar = ProcessInfo.processInfo.environment["USE_MOCK_CALENDAR"] == "1"
        let useMockJam = ProcessInfo.processInfo.environment["USE_MOCK_JAM"] == "1"
        let useMockLocation = ProcessInfo.processInfo.environment["USE_MOCK_LOCATION"] == "1"

        let calService: TVCalendarServiceProtocol = useMockCalendar
            ? TVCalendarServiceMock()
            : TVCalendarService()

        let spotifyService: any TVSpotifyReadServiceProtocol = useMockJam
            ? TVSpotifyReadServiceMock()
            : TVSpotifyReadService()

        let locationVM = LocationViewModel(
            service: useMockLocation ? LocationServiceMock() : LocationService()
        )

        return TVShell(
            calendarService: calService,
            spotifyService: spotifyService,
            weatherVM: WeatherViewModel.makeDefault(),
            locationVM: locationVM,
            photoVM: PhotoViewModel.makeDefault()
        )
    }

    func loadAll() async {
        Task { await weatherVM.start() }
        Task { await locationVM.start() }
        Task { await photoVM.load() }

        isCalendarLoading = true
        do {
            calendarEvents = try await calendarService.fetchUpcomingEvents(hours: 48)
        } catch {
            calendarNeedsAuth = calendarService.needsReauth
        }
        isCalendarLoading = false

        currentTrack = try? await spotifyService.fetchCurrentlyPlaying()
    }
}

// MARK: - TVShellView

struct TVShellView: View {
    @State private var shell = TVShell.makeDefault()
    @State private var selectedPanel: AppSection?

    var body: some View {
        NavigationStack {
            LazyVGrid(
                columns: Array(repeating: .init(.flexible(), spacing: 20), count: 3),
                spacing: 20
            ) {
                // Row 1: Clock, Weather, Calendar
                TVClockPanel()

                Button { selectedPanel = .weather } label: {
                    TVWeatherPanel(vm: shell.weatherVM)
                }
                .tvCardStyle()
                .accessibilityIdentifier("WeatherPanel")

                Button { selectedPanel = .calendar } label: {
                    TVEventsPanel(
                        events: shell.calendarEvents,
                        isLoading: shell.isCalendarLoading,
                        needsAuth: shell.calendarNeedsAuth
                    )
                }
                .tvCardStyle()
                .accessibilityIdentifier("EventsPanel")

                // Row 2: Tasks, Location, Jam
                Button { selectedPanel = .tasks } label: {
                    TVTasksPanel()
                }
                .tvCardStyle()
                .accessibilityIdentifier("TasksPanel")

                Button { selectedPanel = .location } label: {
                    TVLocationPanel(vm: shell.locationVM)
                }
                .tvCardStyle()
                .accessibilityIdentifier("LocationPanel")

                Button { selectedPanel = .jam } label: {
                    TVJamPanel(track: shell.currentTrack)
                }
                .tvCardStyle()
                .accessibilityIdentifier("JamPanel")
            }
            .padding(40)
            .background(Color.dashboardBackground.ignoresSafeArea())
            .navigationDestination(item: $selectedPanel) { section in
                TVPanelDetailView(section: section, shell: shell)
            }
        }
        .task { await shell.loadAll() }
    }
}

// MARK: - Inline Panel Views

private struct TVClockPanel: View {
    var body: some View {
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
    }
}

private struct TVWeatherPanel: View {
    let vm: WeatherViewModel

    var body: some View {
        PanelView(title: "Weather", icon: "cloud.sun.fill") {
            if let snapshot = vm.snapshot {
                VStack(spacing: 4) {
                    Text("\(Int(snapshot.temperature.rounded()))°")
                        .font(.system(size: 48, weight: .light))
                    Text(snapshot.conditionDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            } else if vm.isLoading {
                ProgressView()
            } else {
                Text("--°")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct TVEventsPanel: View {
    let events: [CalendarEvent]
    let isLoading: Bool
    let needsAuth: Bool

    var body: some View {
        PanelView(title: "Coming Up", icon: "calendar") {
            if isLoading {
                ProgressView()
            } else if needsAuth {
                Text("Connect Google Calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if events.isEmpty {
                Text("No upcoming events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(events.prefix(3)) { event in
                        Text(event.title)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct TVTasksPanel: View {
    var body: some View {
        PanelView(title: "Tasks", icon: "checklist") {
            Text("—")
                .font(.title)
                .foregroundStyle(.secondary)
        }
    }
}

private struct TVLocationPanel: View {
    let vm: LocationViewModel

    var body: some View {
        PanelView(title: "Family", icon: "location.fill") {
            if vm.isLoading {
                ProgressView()
            } else if vm.members.isEmpty {
                Text("—")
                    .font(.title)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(vm.members.prefix(3)) { member in
                        HStack(spacing: 6) {
                            Image(systemName: member.isStale ? "location.slash" : "location.fill")
                                .font(.caption)
                                .foregroundStyle(member.isStale ? .secondary : Color.accent)
                            Text(member.displayName)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - tvOS-specific button style helper

private extension View {
    @ViewBuilder
    func tvCardStyle() -> some View {
        #if os(tvOS)
            buttonStyle(.card)
        #else
            self
        #endif
    }
}

private struct TVJamPanel: View {
    let track: TVCurrentTrack?

    var body: some View {
        PanelView(title: "Now Playing", icon: "music.note") {
            if let track {
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(track.artistName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Nothing playing")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
