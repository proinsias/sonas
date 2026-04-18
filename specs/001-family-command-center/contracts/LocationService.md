# Contract: LocationService

**Purpose**: Publish own device location to CloudKit; subscribe to all family
members' location snapshots from the same CloudKit container.

```swift
protocol LocationServiceProtocol: AnyObject {
    /// Stream of all family members' current location snapshots.
    /// Emits on initial load and whenever CloudKit pushes an update.
    var familyLocations: AsyncStream<[FamilyMember]> { get }

    /// Begin publishing this device's location to CloudKit.
    /// Requests CoreLocation permission if not already granted.
    /// No-op if already started.
    func startPublishing() async throws

    /// Stop publishing this device's location. Does NOT delete existing CloudKit record.
    func stopPublishing()

    /// Force a one-time location refresh for all family members (pull).
    func refresh() async throws
}
```

**CloudKit Record Schema** (`FamilyLocation`): | Field | Type | Notes |
|---|---|---| | `recordName` | String | Stable per iCloud account; used as
`FamilyMember.id` | | `displayName` | String | From CloudKit
`CKCurrentUserDefaultName` | | `latitude` | Double | Raw coordinate;
reverse-geocoded on read | | `longitude` | Double | Raw coordinate | |
`placeName` | String | Reverse-geocoded label; computed on writing device | |
`recordedAt` | Date | When the position was captured |

**Error cases**:

- `LocationServiceError.permissionDenied` — CoreLocation auth denied
- `LocationServiceError.cloudKitUnavailable` — iCloud account not signed in or
  CloudKit quota exceeded
- `LocationServiceError.networkUnavailable` — returns cached data; emits stale
  snapshots

**Contract test fixture** (`LocationContractTests.swift`):

```swift
// Given: a CloudKit container returning 2 FamilyLocation records
// When: familyLocations stream is observed
// Then: emits exactly 2 FamilyMember values with correct placeName and recordedAt
```
