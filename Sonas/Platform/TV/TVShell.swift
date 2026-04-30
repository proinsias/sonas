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
    private(set) var calendarLastUpdated: Date?
    private(set) var calendarFetchFailed = false

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
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.weatherVM.start() }
            group.addTask { await self.locationVM.start() }
            group.addTask { await self.photoVM.load() }
        }

        isCalendarLoading = true
        do {
            calendarEvents = try await calendarService.fetchUpcomingEvents(hours: 48)
            calendarLastUpdated = .now
            calendarFetchFailed = false
        } catch {
            calendarNeedsAuth = calendarService.needsReauth
            if !calendarService.needsReauth {
                calendarFetchFailed = true
            }
        }
        isCalendarLoading = false

        currentTrack = try? await spotifyService.fetchCurrentlyPlaying()

        // Write snapshot for Top Shelf after data refresh
        writeTopShelfSnapshot()
    }

    func writeTopShelfSnapshot() {
        #if os(tvOS)
            let photo = photoVM.photos.first
            let nextEvent = calendarEvents.first { $0.startDate > .now }

            Task {
                do {
                    var photoURL: URL?
                    if let photo {
                        let data = try await self.photoVM.loadFullImage(for: photo)
                        if let containerURL = FileManager.default.containerURL(
                            forSecurityApplicationGroupIdentifier: "group.com.sonas.topshelf"
                        ) {
                            let targetURL = containerURL.appendingPathComponent("topshelf_photo.jpg")
                            try data.write(to: targetURL)
                            photoURL = targetURL
                        }
                    }

                    let snapshot = TVTopShelfSnapshot(
                        photoFileURL: photoURL,
                        nextEventTitle: nextEvent?.title,
                        nextEventStart: nextEvent?.startDate,
                        updatedAt: .now
                    )

                    let encoder = JSONEncoder()
                    let snapshotData = try encoder.encode(snapshot)
                    let userDefaults = UserDefaults(suiteName: "group.com.sonas.topshelf")
                    userDefaults?.set(snapshotData, forKey: "TopShelfSnapshot")
                } catch {
                    // Fail silently for Top Shelf updates to avoid disrupting main dashboard
                    print("Failed to write Top Shelf snapshot: \(error.localizedDescription)")
                }
            }
        #endif
    }
}

// MARK: - TVShellView

struct TVShellView: View {
    @State private var shell = TVShell.makeDefault()
    @State private var selectedPanel: AppSection?

    var body: some View {
        NavigationStack {
            Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                GridRow {
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
                            needsAuth: shell.calendarNeedsAuth,
                            isFetchFailed: shell.calendarFetchFailed,
                            lastUpdated: shell.calendarLastUpdated
                        ) { Task { await shell.loadAll() } }
                    }
                    .tvCardStyle()
                    .accessibilityIdentifier("EventsPanel")
                }

                GridRow {
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
                        TVSpotifyJamPanel(track: shell.currentTrack)
                    }
                    .tvCardStyle()
                    .accessibilityIdentifier("JamPanel")
                }

                GridRow {
                    // Row 3: Photos — spanning all 3 columns
                    Button { selectedPanel = .photos } label: {
                        TVSlideshowPanelView(vm: shell.photoVM)
                    }
                    .tvCardStyle()
                    .accessibilityIdentifier("PhotosPanel")
                    .gridCellColumns(3)
                }
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
        PanelView(title: "Weather", icon: "cloud.sun.fill", lastUpdated: vm.liveDataFailed ? vm.lastUpdated : nil) {
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
        .staleIfNeeded(lastUpdated: vm.liveDataFailed ? vm.lastUpdated : nil) {
            Task { await vm.refresh() }
        }
    }
}

private struct TVEventsPanel: View {
    let events: [CalendarEvent]
    let isLoading: Bool
    let needsAuth: Bool
    let isFetchFailed: Bool
    let lastUpdated: Date?
    let onRetry: () -> Void

    var body: some View {
        PanelView(title: "Coming Up", icon: "calendar", lastUpdated: isFetchFailed ? lastUpdated : nil) {
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
        .staleIfNeeded(lastUpdated: isFetchFailed ? lastUpdated : nil, onRetry: onRetry)
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

    @ViewBuilder
    func staleIfNeeded(lastUpdated: Date?, onRetry: @escaping () -> Void) -> some View {
        if let lastUpdated {
            staleDataBadge(lastUpdated: lastUpdated, onRetry: onRetry)
        } else {
            self
        }
    }
}

private struct TVSpotifyJamPanel: View {
    let track: TVCurrentTrack?

    var body: some View {
        PanelView(title: "Now Playing", icon: "music.note") {
            if let track {
                HStack(spacing: 12) {
                    AsyncImage(url: track.albumArtURL) { phase in
                        switch phase {
                        case .empty:
                            Image(systemName: "music.note")
                                .font(.title)
                                .foregroundStyle(Color.accent)
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            Image(systemName: "music.note")
                                .font(.title)
                                .foregroundStyle(Color.accent)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title)
                            .font(.headline)
                            .lineLimit(2)
                        Text(track.artistName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
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
