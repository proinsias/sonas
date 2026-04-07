import SwiftUI
import CoreLocation

// MARK: - SettingsView (T093 — minimal shell; expanded in T092)
// T093 scope: home location search + coordinate picker + Google Calendar connect/disconnect.
// T092 (Phase 9) adds: Todoist token, Spotify, photo album picker, temperature unit toggle.

struct SettingsView: View {

    @State private var config = AppConfiguration.shared
    @State private var locationSearchText: String = ""
    @State private var isSearchingLocation: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                homeLocationSection
                googleCalendarSection
                // T092 sections added here in Phase 9:
                // - Todoist API token entry
                // - Spotify connect/disconnect
                // - Photo album picker
                // - Temperature unit toggle
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
    }

    // MARK: - Home Location

    private var homeLocationSection: some View {
        Section("Home Location") {
            if let name = config.homeLocationName, !name.isEmpty {
                HStack {
                    Image(systemName: Icon.location)
                        .foregroundStyle(Color.accent)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
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
        .sheet(isPresented: $isSearchingLocation) {
            LocationSearchView(
                onSelect: { coordinate, name in
                    config.homeLocation = coordinate
                    config.homeLocationName = name
                    isSearchingLocation = false
                }
            )
        }
    }

    // MARK: - Google Calendar

    private var googleCalendarSection: some View {
        Section("Google Calendar") {
            // Full GoogleSignIn flow integrated here once GoogleSignIn SDK is linked.
            // Placeholder shows connection status with connect/disconnect actions.
            HStack {
                Image(systemName: "g.circle.fill")
                    .foregroundStyle(Color.accent)
                    .accessibilityHidden(true)
                Text("Google Calendar")
                Spacer()
                Text(config.homeLocationName != nil ? "Connected" : "Not Connected")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryLabel)
            }
            Button("Connect Google Calendar") {
                // T032/T033: CalendarService.connectGoogleAccount() called here
            }
            .foregroundStyle(Color.accent)
            .accessibilityInfo("Connect Google Calendar", hint: "Sign in with your Google account to sync events")
        }
    }
}

// MARK: - LocationSearchView (placeholder)

private struct LocationSearchView: View {
    let onSelect: (CLLocationCoordinate2D, String) -> Void
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // TODO: Integrate MKLocalSearchCompleter for location autocomplete
                Text("Location search coming in T092 expansion")
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
