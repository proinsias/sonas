import CloudKit
import Foundation
@testable import Sonas
import Testing

// MARK: - LocationCloudKitTests (T042)

// Covers FR-017: location updates reflected within 60 seconds via CKQuerySubscription.
// Requires iCloud sign-in in the Simulator + CloudKit test container.
// Run in SonasIntegrationTests scheme; NOT included in standard SonasTests CI run.
// Set CLOUDKIT_CONTAINER_ID in the integration test scheme environment variables if your
// container differs from the default derived from the app's bundle identifier.

@MainActor
@Suite("Location CloudKit Integration Tests", .disabled("Requires CloudKit entitlement and iCloud sign-in"))
struct LocationCloudKitTests {
    private static var cloudKitContainerID: String {
        ProcessInfo.processInfo.environment["CLOUDKIT_CONTAINER_ID"]
            ?? "iCloud.\(Bundle.main.bundleIdentifier ?? "com.example.sonas")"
    }

    // MARK: - T042a: Write record → refresh returns member

    @Test
    func `given FamilyLocation record written when refresh called then service returns that member`() async throws {
        let container = CKContainer(identifier: Self.cloudKitContainerID)
        let db = container.privateCloudDatabase

        let record = CKRecord(recordType: "FamilyLocation")
        record["displayName"] = "IntegrationTestUser" as CKRecordValue
        record["latitude"] = 53.3498 as CKRecordValue
        record["longitude"] = -6.2603 as CKRecordValue
        record["placeName"] = "Dublin" as CKRecordValue
        record["recordedAt"] = Date.now as CKRecordValue

        let saved = try await db.save(record)

        // Act
        let service = LocationService()
        let members = try await service.refresh()

        // Assert
        let found = members.first { $0.id == saved.recordID.recordName }
        #expect(found != nil, "Saved member must appear in refresh results")
        #expect(found?.location?.placeName == "Dublin", "placeName must match written value")

        // Cleanup
        try await db.deleteRecord(withID: saved.recordID)
    }

    // MARK: - T042b: Second device writes → AsyncStream emits within 60s (subscription latency)

    @Test(
        .timeLimit(.minutes(2)),
    )
    func `given CKQuerySubscription active when second record written then stream emits update within 60s`(
    ) async throws {
        let service = LocationService()
        await service.startPublishing()

        // Simulate second-device write
        let container = CKContainer(identifier: Self.cloudKitContainerID)
        let db = container.privateCloudDatabase

        let record = CKRecord(recordType: "FamilyLocation")
        record["displayName"] = "SecondDevice" as CKRecordValue
        record["latitude"] = 51.5074 as CKRecordValue
        record["longitude"] = -0.1278 as CKRecordValue
        record["placeName"] = "London" as CKRecordValue
        record["recordedAt"] = Date.now as CKRecordValue
        let saved = try await db.save(record)

        // Collect next emission from the stream within 60s
        var received: [FamilyMember] = []
        let deadline = Date.now.addingTimeInterval(60)
        for await members in service.familyLocations {
            if members.contains(where: { $0.id == saved.recordID.recordName }) {
                received = members
                break
            }
            if Date.now > deadline {
                break
            }
        }
        await service.stopPublishing()

        #expect(
            received.contains { $0.id == saved.recordID.recordName },
            "CKQuerySubscription must deliver the new record within 60 seconds (FR-017)",
        )

        // Cleanup
        try await db.deleteRecord(withID: saved.recordID)
    }
}

// MARK: - Test tag

extension Tag {
    @Tag static var integration: Self
}
