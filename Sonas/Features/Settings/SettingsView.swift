import CoreLocation
import SwiftUI

// MARK: - SettingsView (T092)

struct SettingsView: View {
    var tasksVM: TasksViewModel
    var eventsVM: EventsViewModel
    var jamVM: JamViewModel
    var photoVM: PhotoViewModel

    @State private var config = AppConfiguration.shared
    @State private var isSearchingLocation: Bool = false
    @State private var isSelectingAlbum: Bool = false
    @State private var todoistInput: String = ""
    @State private var isConnectingTodoist: Bool = false
    @State private var todoistConnectError: String?
    @State private var selectedProjectIDs: Set<String> = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                homeLocationSection
                googleCalendarSection
                todoistSection
                todoistProjectsSection
                spotifySection
                photoAlbumSection
                temperatureSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .accessibilityInfo("Done", hint: "Close settings")
                }
            }
            .task {
                selectedProjectIDs = Set(config.selectedTodoistProjectIDs)
            }
            .onChange(of: tasksVM.availableProjects) { _, _ in
                selectedProjectIDs = Set(config.selectedTodoistProjectIDs)
            }
        }
        // Sheets attached to the NavigationStack root rather than to sections inside the Form,
        // so SwiftUI routes presentation from the correct hosting controller and avoids the
        // "already presenting" warning that occurs when presenting from a Form's subview.
        .sheet(isPresented: $isSearchingLocation) {
            LocationSearchView { coordinate, name in
                config.homeLocation = coordinate
                config.homeLocationName = name
                isSearchingLocation = false
            }
        }
        .sheet(isPresented: $isSelectingAlbum) {
            AlbumPickerView(photoVM: photoVM, isPresented: $isSelectingAlbum)
        }
    }

    // MARK: - Home Location

    private var homeLocationSection: some View {
        Section("Home Location") {
            if !config.homeLocationName.isEmpty {
                HStack {
                    Image(systemName: Icon.location)
                        .foregroundStyle(Color.accent)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(config.homeLocationName)
                            .font(.body)
                        if let coord = config.homeLocation {
                            Text(String(format: "%.4f, %.4f", coord.latitude, coord.longitude))
                                .font(.caption)
                                .foregroundStyle(Color.secondaryLabel)
                        }
                    }
                    Spacer()
                    Button("Change") { isSearchingLocation = true }
                        .font(.buttonLabel)
                        .foregroundStyle(Color.accent)
                        .accessibilityInfo("Change home location", hint: "Search for a new home location")
                }
            } else {
                Button {
                    isSearchingLocation = true
                } label: {
                    Label("Set Home Location", systemImage: Icon.location)
                        .foregroundStyle(Color.accent)
                }
                .accessibilityInfo("Set Home Location", hint: "Search for your home location for weather")
            }
        }
    }

    // MARK: - Google Calendar

    private var googleCalendarSection: some View {
        Section("Google Calendar") {
            if eventsVM.isGoogleConnected {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                    Text("Connected")
                    Spacer()
                    Button("Disconnect") {
                        Task { await eventsVM.disconnectGoogle() }
                    }
                    .foregroundStyle(.red)
                    .accessibilityInfo("Disconnect Google Calendar", hint: "Remove your Google account")
                }
            } else {
                HStack {
                    Image(systemName: "g.circle.fill")
                        .foregroundStyle(Color.accent)
                        .accessibilityHidden(true)
                    Text("Google Calendar")
                    Spacer()
                    Text("Not Connected")
                        .font(.caption)
                        .foregroundStyle(Color.secondaryLabel)
                }
                Button("Connect Google Calendar") {
                    Task { await eventsVM.reconnectGoogle() }
                }
                .foregroundStyle(Color.accent)
                .accessibilityInfo("Connect Google Calendar", hint: "Sign in with your Google account to sync events")
            }
        }
    }
}

// MARK: - SettingsView sections (Todoist, Spotify, Photos, Temperature)

private extension SettingsView {
    // MARK: - Todoist

    var todoistSection: some View {
        Section("Todoist") {
            if tasksVM.isConnected {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                    Text("Connected")
                    Spacer()
                    Button("Disconnect") {
                        Task { await tasksVM.disconnectTodoist() }
                    }
                    .foregroundStyle(.red)
                    .accessibilityInfo("Disconnect Todoist", hint: "Remove your Todoist API token")
                }
            } else {
                SecureField("API token", text: $todoistInput)
                    .textContentType(.password)
                    .accessibilityLabel("Todoist API token")
                if let err = todoistConnectError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Button {
                    guard !todoistInput.isEmpty else {
                        todoistConnectError = "Enter your Todoist API token."
                        return
                    }
                    isConnectingTodoist = true
                    todoistConnectError = nil
                    Task {
                        do {
                            try await tasksVM.connectTodoist(apiToken: todoistInput)
                            todoistInput = ""
                        } catch {
                            todoistConnectError = error.localizedDescription
                        }
                        isConnectingTodoist = false
                    }
                } label: {
                    if isConnectingTodoist {
                        ProgressView()
                    } else {
                        Text("Connect Todoist")
                    }
                }
                .foregroundStyle(Color.accent)
                .disabled(isConnectingTodoist)
                .accessibilityInfo("Connect Todoist", hint: "Validate and store your Todoist API token")
            }
        }
    }

    // MARK: - Todoist project picker

    @ViewBuilder
    var todoistProjectsSection: some View {
        if tasksVM.isConnected {
            Section {
                if tasksVM.isLoadingProjects {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading projects…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if tasksVM.projectsLoadFailed {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Could not load projects.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            Task { await tasksVM.reloadProjects() }
                        }
                        .font(.caption)
                        .foregroundStyle(Color.accent)
                        .accessibilityInfo("Retry loading projects", hint: "Fetch your Todoist project list again")
                    }
                } else {
                    ForEach(tasksVM.availableProjects) { project in
                        projectToggleRow(project)
                    }
                }
            } header: {
                Text("Todoist Projects")
            } footer: {
                Text("Selected projects appear in Tasks. Leave all unselected to show everything.")
            }
        }
    }

    private func projectToggleRow(_ project: TaskProject) -> some View {
        Button {
            if selectedProjectIDs.contains(project.id) {
                selectedProjectIDs.remove(project.id)
            } else {
                selectedProjectIDs.insert(project.id)
            }
            config.selectedTodoistProjectIDs = Array(selectedProjectIDs)
        } label: {
            HStack {
                Text(project.name)
                    .foregroundStyle(.primary)
                Spacer()
                if selectedProjectIDs.contains(project.id) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accent)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityIdentifier("todoistProject_\(project.id)")
        .accessibilityLabel(project.name)
        .accessibilityValue(selectedProjectIDs.contains(project.id) ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to toggle project selection")
    }

    // MARK: - Spotify

    var spotifySection: some View {
        Section("Spotify") {
            if jamVM.isSpotifyConnected {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                    Text("Connected")
                }
            } else if jamVM.isSpotifyInstalled {
                Button("Connect Spotify") {
                    Task { await jamVM.connectSpotify() }
                }
                .foregroundStyle(Color.accent)
                .accessibilityInfo("Connect Spotify", hint: "Authenticate with your Spotify account to start jams")
            } else {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(Color.secondaryLabel)
                        .accessibilityHidden(true)
                    Text("Spotify app not installed")
                        .foregroundStyle(Color.secondaryLabel)
                }
            }
        }
    }

    // MARK: - Photo Album

    var photoAlbumSection: some View {
        Section("Photo Album") {
            if let albumName = config.selectedAlbumName {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .foregroundStyle(Color.accent)
                        .accessibilityHidden(true)
                    Text(albumName)
                    Spacer()
                    Button("Change") { isSelectingAlbum = true }
                        .font(.buttonLabel)
                        .foregroundStyle(Color.accent)
                        .accessibilityInfo("Change photo album", hint: "Select a different shared album")
                }
            } else {
                Button {
                    isSelectingAlbum = true
                } label: {
                    Label("Select Album", systemImage: "photo.on.rectangle")
                        .foregroundStyle(Color.accent)
                }
                .accessibilityInfo("Select Album", hint: "Choose an iCloud shared album to display in the gallery")
            }
        }
    }

    // MARK: - Temperature Unit

    var temperatureSection: some View {
        Section("Temperature") {
            Toggle("Use Fahrenheit", isOn: $config.useFahrenheit)
                .accessibilityInfo("Use Fahrenheit", hint: "Display temperatures in Fahrenheit instead of Celsius")
        }
    }
}

// MARK: - LocationSearchView (placeholder — MKLocalSearchCompleter integration pending)

private struct LocationSearchView: View {
    let onSelect: (CLLocationCoordinate2D, String) -> Void
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // TODO: Integrate MKLocalSearchCompleter for location autocomplete
                Text("Location search coming soon")
                    .foregroundStyle(Color.secondaryLabel)
            }
            .searchable(text: $searchText, prompt: "Search for a city or address")
            .accessibilityLabel("Location Search")
            .navigationTitle("Set Home Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
