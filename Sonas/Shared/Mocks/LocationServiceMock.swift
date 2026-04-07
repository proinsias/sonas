import Foundation
import CoreLocation

// MARK: - LocationServiceMock (T028)
// Returns fixture FamilyMember data via AsyncStream.
// Active when USE_MOCK_LOCATION=1 environment variable is set.

final class LocationServiceMock: LocationServiceProtocol, @unchecked Sendable {

    private var continuation: AsyncStream<[FamilyMember]>.Continuation?
    private(set) var familyLocations: AsyncStream<[FamilyMember]>

    init() {
        var cont: AsyncStream<[FamilyMember]>.Continuation?
        familyLocations = AsyncStream { cont = $0 }
        continuation = cont
    }

    func startPublishing() async {
        continuation?.yield(Self.fixtures)
    }

    func stopPublishing() async {
        continuation?.finish()
    }

    func refresh() async throws -> [FamilyMember] {
        continuation?.yield(Self.fixtures)
        return Self.fixtures
    }

    // MARK: Fixtures

    static let fixtures: [FamilyMember] = [
        FamilyMember(
            id: "mock-alice",
            displayName: "Alice",
            location: LocationSnapshot(
                coordinate: CLLocationCoordinate2D(latitude: 53.3498, longitude: -6.2603),
                placeName: "Dublin City Centre",
                recordedAt: Date.now.addingTimeInterval(-120)
            )
        ),
        FamilyMember(
            id: "mock-bob",
            displayName: "Bob",
            location: LocationSnapshot(
                coordinate: CLLocationCoordinate2D(latitude: 53.3340, longitude: -6.2534),
                placeName: "Ranelagh, Dublin",
                recordedAt: Date.now.addingTimeInterval(-45)
            )
        ),
        FamilyMember(
            id: "mock-carol",
            displayName: "Carol",
            location: nil  // Simulates "Location unavailable" state
        )
    ]
}
