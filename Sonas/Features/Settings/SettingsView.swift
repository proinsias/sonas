import CoreLocation
import Photos
import SwiftUI

// MARK: - SettingsView (T092)

struct SettingsView: View {
    var tasksVM: TasksViewModel
    var jamVM: JamViewModel
    var photoVM: PhotoViewModel

    @State private var config = AppConfiguration.shared
    @State private var isSearchingLocation: Bool = false
    @State private var isSelectingAlbum: Bool = false
    @State private var todoistInput: String = ""
    @State private var isConnectingTodoist: Bool = false
    @State private var todoistConnectError: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                homeLocationSection
                googleCalendarSection
                todoistSection
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
            // Full GoogleSignIn flow integrated once GoogleSignIn SDK is linked (T032/T033).
            HStack {
                Image(systemName: "g.circle.fill")
                    .foregroundStyle(Color.accent)
                    .accessibilityHidden(true)
                Text("Google Calendar")
                Spacer()
                Text(!config.homeLocationName.isEmpty ? "Connected" : "Not Connected")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryLabel)
            }
            Button("Connect Google Calendar") {
                // CalendarService.connectGoogleAccount() called here once SDK is linked
            }
            .foregroundStyle(Color.accent)
            .accessibilityInfo("Connect Google Calendar", hint: "Sign in with your Google account to sync events")
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
                        Swift.Task { await tasksVM.disconnectTodoist() }
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
                    Swift.Task {
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
                    Swift.Task { await jamVM.connectSpotify() }
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

// MARK: - AlbumPickerView

private struct AlbumItem: Identifiable {
    let id: String
    let name: String
    let count: Int
}

private struct AlbumPickerView: View {
    var photoVM: PhotoViewModel
    @Binding var isPresented: Bool
    @State private var albums: [AlbumItem] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading albums…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if albums.isEmpty {
                    ContentUnavailableView(
                        "No Albums Found",
                        systemImage: "photo.on.rectangle",
                        description: Text("Grant photo access in Settings to see your albums."),
                    )
                } else {
                    List(albums) { album in
                        Button {
                            AppConfiguration.shared.selectedAlbumIdentifier = album.id
                            AppConfiguration.shared.selectedAlbumName = album.name
                            Swift.Task { await photoVM.reload() }
                            isPresented = false
                        } label: {
                            HStack {
                                Text(album.name)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                Text("\(album.count)")
                                    .foregroundStyle(Color.secondaryLabel)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
        .task { await loadAlbums() }
    }

    private func loadAlbums() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else {
            isLoading = false
            return
        }

        var result: [AlbumItem] = []

        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        userAlbums.enumerateObjects { collection, _, _ in
            let count = PHAsset.fetchAssets(in: collection, options: nil).count
            // swiftlint:disable:next empty_count
            if count > 0, let title = collection.localizedTitle { // SONAS-001
                result.append(AlbumItem(id: collection.localIdentifier, name: title, count: count))
            }
        }

        let smartAlbums = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumUserLibrary,
            options: nil,
        )
        smartAlbums.enumerateObjects { collection, _, _ in
            let count = PHAsset.fetchAssets(in: collection, options: nil).count
            // swiftlint:disable:next empty_count
            if count > 0, let title = collection.localizedTitle { // SONAS-001
                result.append(AlbumItem(id: collection.localIdentifier, name: title, count: count))
            }
        }

        albums = result.sorted { $0.name < $1.name }
        isLoading = false
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
