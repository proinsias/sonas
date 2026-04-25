@preconcurrency import CloudKit
@preconcurrency import CoreLocation
import Foundation

// MARK: - LocationServiceProtocol (T026)

@MainActor
protocol LocationServiceProtocol: AnyObject, Sendable {
    /// Continuous stream of the current family member list (all members, including own device).
    var familyLocations: AsyncStream<[FamilyMember]> { get }

    /// Start publishing this device's location to CloudKit and subscribing for others.
    func startPublishing() async
    /// Stop publishing and cancel all subscriptions.
    func stopPublishing() async
    /// One-shot fetch of the latest family member locations from CloudKit.
    func refresh() async throws -> [FamilyMember]
}

// MARK: - LocationServiceError

enum LocationServiceError: LocalizedError {
    case permissionDenied
    case cloudKitUnavailable
    case geocodingFailed(Error)
    case subscriptionSetupFailed(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Location permission is required to show family members on the map."
        case .cloudKitUnavailable:
            "iCloud is unavailable. Family locations cannot be synced."
        case let .geocodingFailed(err):
            "Could not determine place name: \(err.localizedDescription)"
        case let .subscriptionSetupFailed(err):
            "Could not subscribe to location updates: \(err.localizedDescription)"
        }
    }
}

// MARK: - LocationService (T030)

@MainActor
final class LocationService: NSObject, LocationServiceProtocol {
    // MARK: Constants

    private enum Constants {
        static let recordType = "FamilyLocation"
        static let containerID = "iCloud.\(Bundle.main.bundleIdentifier ?? "com.example.sonas")"
        static let zoneID = CKRecordZone.default().zoneID
        static let minDistance: CLLocationDistance = 50 // metres
        static let maxInterval: TimeInterval = 60 // seconds
        static let subscriptionID = "sonas-family-location-sub"
    }

    // MARK: AsyncStream bookkeeping

    private var continuation: AsyncStream<[FamilyMember]>.Continuation?
    private(set) var familyLocations: AsyncStream<[FamilyMember]>

    // MARK: Private state

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var _container: CKContainer?
    private let _containerIdentifier: String
    private var container: CKContainer {
        if let existing = _container { return existing }
        let new = CKContainer(identifier: _containerIdentifier)
        _container = new
        return new
    }

    private var lastPublishedLocation: CLLocation?
    private var lastPublishDate: Date = .distantPast
    private var members: [String: FamilyMember] = [:]

    // MARK: Init

    init(containerIdentifier: String = Constants.containerID) {
        _containerIdentifier = containerIdentifier
        var continuation: AsyncStream<[FamilyMember]>.Continuation?
        familyLocations = AsyncStream { cont in continuation = cont }
        super.init()
        self.continuation = continuation
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = Constants.minDistance
    }

    // MARK: - LocationServiceProtocol

    func startPublishing() async {
        SonasLogger.location.info("LocationService: startPublishing")
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
        await setupCloudKitSubscription()
        _ = try? await refresh()
    }

    func stopPublishing() async {
        locationManager.stopUpdatingLocation()
        continuation?.finish()
        SonasLogger.location.info("LocationService: stopped")
    }

    func refresh() async throws -> [FamilyMember] {
        SonasLogger.location.info("LocationService: refresh")
        let query = CKQuery(
            recordType: Constants.recordType,
            predicate: NSPredicate(value: true),
        )
        let (results, _) = try await container.privateCloudDatabase.records(matching: query)
        let fetchedMembers: [FamilyMember] = results.compactMap { _, result in
            guard case let .success(record) = result else { return nil }
            return FamilyMember(from: record)
        }
        for member in fetchedMembers {
            members[member.id] = member
        }
        let all = Array(members.values)
        continuation?.yield(all)
        return all
    }

    // MARK: - CloudKit Subscription

    private func setupCloudKitSubscription() async {
        do {
            let predicate = NSPredicate(value: true)
            let subscription = CKQuerySubscription(
                recordType: Constants.recordType,
                predicate: predicate,
                subscriptionID: Constants.subscriptionID,
                options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion],
            )
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo
            _ = try await container.privateCloudDatabase.save(subscription)
            SonasLogger.location.info("LocationService: CKQuerySubscription saved")
        } catch {
            // Duplicate subscription is expected on re-launch; log and continue
            SonasLogger.error(SonasLogger.location, "LocationService: subscription setup", error: error)
        }
    }

    // MARK: - Location throttle

    private func shouldPublish(newLocation: CLLocation) -> Bool {
        if let last = lastPublishedLocation,
           newLocation.distance(from: last) < Constants.minDistance,
           Date.now.timeIntervalSince(lastPublishDate) < Constants.maxInterval {
            return false
        }
        return true
    }

    private func publish(location: CLLocation) async {
        guard shouldPublish(newLocation: location) else { return }
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let placeName = placemarks.first.map {
                [$0.locality, $0.administrativeArea].compactMap(\.self).joined(separator: ", ")
            } ?? "Unknown"

            let record = CKRecord(recordType: Constants.recordType)
            record["displayName"] = AppConfiguration.shared.homeLocationName as CKRecordValue
            record["latitude"] = location.coordinate.latitude as CKRecordValue
            record["longitude"] = location.coordinate.longitude as CKRecordValue
            record["placeName"] = placeName as CKRecordValue
            record["recordedAt"] = Date.now as CKRecordValue

            _ = try await container.privateCloudDatabase.save(record)
            lastPublishedLocation = location
            lastPublishDate = .now
            SonasLogger.locationUpdate(memberID: record.recordID.recordName, placeName: placeName)
        } catch {
            SonasLogger.error(SonasLogger.location, "LocationService: publish failed", error: error)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_: CLLocationManager) {
        Task { @MainActor [self] in
            if locationManager.authorizationStatus == .authorizedWhenInUse ||
                locationManager.authorizationStatus == .authorizedAlways {
                locationManager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(
        _: CLLocationManager,
        didUpdateLocations locations: [CLLocation],
    ) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            await publish(location: loc)
        }
    }
}

// MARK: - CKRecord → FamilyMember

private extension FamilyMember {
    init?(from record: CKRecord) {
        guard
            let name = record["displayName"] as? String,
            let lat = record["latitude"] as? Double,
            let lon = record["longitude"] as? Double,
            let place = record["placeName"] as? String,
            let date = record["recordedAt"] as? Date
        else { return nil }

        self.init(
            id: record.recordID.recordName,
            displayName: name,
            location: LocationSnapshot(
                coordinate: .init(latitude: lat, longitude: lon),
                placeName: place,
                recordedAt: date,
            ),
        )
    }
}
