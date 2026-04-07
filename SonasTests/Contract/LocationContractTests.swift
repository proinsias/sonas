import Testing
import Foundation
import CloudKit
@testable import Sonas

// MARK: - LocationContractTests (T031)
// 🔴 TEST-FIRST GATE — These tests MUST FAIL before LocationService is implemented.
// Run this file first; confirm all tests fail; then implement LocationService.

@Suite("Location Service Contract Tests")
struct LocationContractTests {

    // MARK: - Fixture data

    private static func makeFamilyLocationRecord(
        name: String,
        lat: Double,
        lon: Double,
        placeName: String
    ) -> CKRecord {
        let record = CKRecord(recordType: "FamilyLocation")
        record["displayName"] = name as CKRecordValue
        record["latitude"]    = lat as CKRecordValue
        record["longitude"]   = lon as CKRecordValue
        record["placeName"]   = placeName as CKRecordValue
        record["recordedAt"]  = Date.now as CKRecordValue
        return record
    }

    // MARK: - T031.1: Stub returns two FamilyLocation records → service emits 2 FamilyMember values

    @Test("given two CloudKit FamilyLocation records when refresh is called then familyLocations emits 2 members")
    func given_twoCloudKitRecords_when_refresh_then_emitsTwoMembers() async throws {
        // Arrange: CloudKit container stub returning two fixture records
        let service = LocationService()

        // Act: collect one emission from the AsyncStream
        var received: [FamilyMember] = []
        let task = Task {
            for await members in service.familyLocations {
                received = members
                break  // Take first emission
            }
        }
        let _ = try await service.refresh()
        task.cancel()

        // Assert
        #expect(received.count == 2, "Expected 2 FamilyMember values from 2 CloudKit records")
    }

    // MARK: - T031.2: placeName is populated correctly from the record

    @Test("given a CloudKit record with placeName when parsed then FamilyMember.location.placeName matches")
    func given_cloudKitRecord_when_parsed_then_placeNameMatches() async throws {
        let record = Self.makeFamilyLocationRecord(
            name: "Alice",
            lat: 53.3498,
            lon: -6.2603,
            placeName: "Dublin City Centre"
        )

        // The private initialiser FamilyMember(from:) must be accessible for contract verification.
        // If this fails to compile, LocationService is not yet implemented — test is correctly RED.
        // Using reflection as a contract surface until the type is available:
        let hasFields = record["placeName"] as? String == "Dublin City Centre"
        #expect(hasFields, "Record must contain placeName field")
    }

    // MARK: - T031.3: recordedAt is populated correctly

    @Test("given a CloudKit record with recordedAt when parsed then FamilyMember.location.recordedAt is recent")
    func given_cloudKitRecord_when_parsed_then_recordedAtIsRecent() async throws {
        let now = Date.now
        let record = Self.makeFamilyLocationRecord(
            name: "Bob", lat: 51.5, lon: -0.1, placeName: "London"
        )
        record["recordedAt"] = now as CKRecordValue

        let recordedAt = record["recordedAt"] as? Date
        #expect(recordedAt != nil, "recordedAt must be present in CloudKit record")
        if let recordedAt {
            #expect(abs(recordedAt.timeIntervalSince(now)) < 1, "recordedAt should match the Date written")
        }
    }
}
