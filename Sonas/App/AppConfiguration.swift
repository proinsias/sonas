import CoreLocation
import Foundation
import Security

// MARK: - AppConfiguration

// UserDefaults-backed app settings. Sensitive tokens are stored in iOS Keychain.
// All computed properties call access/withMutation so @Observable tracks them correctly.

@Observable
final class AppConfiguration {
    // MARK: Shared singleton

    nonisolated(unsafe) static let shared = AppConfiguration()

    // MARK: Weather / Location

    /// Home location coordinate used by WeatherService and as the map origin.
    var homeLocation: CLLocationCoordinate2D? {
        get {
            access(keyPath: \.homeLocation)
            guard
                let lat = defaults.object(forKey: Keys.homeLat) as? Double,
                let lon = defaults.object(forKey: Keys.homeLon) as? Double
            else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        set {
            withMutation(keyPath: \.homeLocation) {
                defaults.set(newValue?.latitude, forKey: Keys.homeLat)
                defaults.set(newValue?.longitude, forKey: Keys.homeLon)
            }
        }
    }

    /// Human-readable home location name (e.g., "Dublin, Ireland")
    var homeLocationName: String {
        get {
            access(keyPath: \.homeLocationName)
            return defaults.string(forKey: Keys.homeLocationName) ?? ""
        }
        set {
            withMutation(keyPath: \.homeLocationName) {
                defaults.set(newValue, forKey: Keys.homeLocationName)
            }
        }
    }

    // MARK: Todoist

    /// Todoist API token stored securely in Keychain
    var todoistAPIToken: String? {
        get {
            access(keyPath: \.todoistAPIToken)
            return Keychain.load(service: Keys.todoistToken)
        }
        set {
            withMutation(keyPath: \.todoistAPIToken) {
                Keychain.save(newValue, service: Keys.todoistToken)
            }
        }
    }

    /// User-selected Todoist project IDs to display (comma-separated in UserDefaults)
    var selectedTodoistProjectIDs: [String] {
        get {
            access(keyPath: \.selectedTodoistProjectIDs)
            return defaults.stringArray(forKey: Keys.todoistProjects) ?? []
        }
        set {
            withMutation(keyPath: \.selectedTodoistProjectIDs) {
                defaults.set(newValue, forKey: Keys.todoistProjects)
            }
        }
    }

    // MARK: Photos

    /// Local identifier of the selected iCloud Shared Album (`PHAssetCollection.localIdentifier`)
    var selectedAlbumIdentifier: String? {
        get {
            access(keyPath: \.selectedAlbumIdentifier)
            return defaults.string(forKey: Keys.albumIdentifier)
        }
        set {
            withMutation(keyPath: \.selectedAlbumIdentifier) {
                defaults.set(newValue, forKey: Keys.albumIdentifier)
            }
        }
    }

    /// Display name of the selected album, cached for UI
    var selectedAlbumName: String? {
        get {
            access(keyPath: \.selectedAlbumName)
            return defaults.string(forKey: Keys.albumName)
        }
        set {
            withMutation(keyPath: \.selectedAlbumName) {
                defaults.set(newValue, forKey: Keys.albumName)
            }
        }
    }

    // MARK: Display preferences

    /// Temperature unit: true = Fahrenheit, false = Celsius
    var useFahrenheit: Bool {
        get {
            access(keyPath: \.useFahrenheit)
            return defaults.bool(forKey: Keys.useFahrenheit)
        }
        set {
            withMutation(keyPath: \.useFahrenheit) {
                defaults.set(newValue, forKey: Keys.useFahrenheit)
            }
        }
    }

    // MARK: Private

    private let defaults = UserDefaults.standard
    private init() {}
}

// MARK: - Keys

private enum Keys {
    static let homeLat = "sonas.home.lat"
    static let homeLon = "sonas.home.lon"
    static let homeLocationName = "sonas.home.name"
    static let todoistToken = "sonas.todoist.token"
    static let todoistProjects = "sonas.todoist.projects"
    static let albumIdentifier = "sonas.photos.albumID"
    static let albumName = "sonas.photos.albumName"
    static let useFahrenheit = "sonas.weather.fahrenheit"
}

// MARK: - Keychain helper (minimal; wraps Security framework)

private enum Keychain {
    static func save(_ value: String?, service: String) {
        let account = "sonas"
        if let value {
            let data = Data(value.utf8)
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecValueData: data
            ]
            SecItemDelete(query as CFDictionary)
            SecItemAdd(query as CFDictionary, nil)
        } else {
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account
            ]
            SecItemDelete(query as CFDictionary)
        }
    }

    static func load(service: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: "sonas",
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }
}
