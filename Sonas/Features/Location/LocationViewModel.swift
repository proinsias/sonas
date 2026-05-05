import Foundation
import Observation

// MARK: - LocationViewModel (T036)

@Observable
@MainActor
final class LocationViewModel {
    // MARK: Published state

    private(set) var members: [FamilyMember] = []
    private(set) var isLoading: Bool = true
    private(set) var error: PanelError?

    // MARK: Dependencies

    private let service: any LocationServiceProtocol
    private var streamTask: Task<Void, Never>?

    #if os(macOS)
        private var lastKnownPlaces: [String: String] = [:]
    #endif

    init(service: any LocationServiceProtocol) {
        self.service = service
    }

    // MARK: - Lifecycle

    func start() async {
        isLoading = true
        error = nil
        await service.startPublishing()
        let stream = service.familyLocations
        // withCheckedContinuation suspends start() entirely, releasing the
        // @MainActor so streamTask can run and deliver its first value.
        // Task.yield() spin-loops are unreliable on @MainActor in Swift Testing.
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            streamTask = Task { [weak self] in
                var signaled = false
                for await updated in stream {
                    guard !Task.isCancelled else { break }
                    let sorted = updated.sorted { $0.displayName < $1.displayName }

                    #if os(macOS)
                        for member in sorted {
                            if let newPlace = member.location?.placeName,
                               !newPlace.isEmpty,
                               newPlace != self?.lastKnownPlaces[member.id] {
                                self?.lastKnownPlaces[member.id] = newPlace
                                Task {
                                    await MacNotificationService.shared.scheduleLocationArrival(
                                        memberName: member.displayName,
                                        placeName: newPlace
                                    )
                                }
                            }
                        }
                    #endif

                    self?.members = sorted
                    self?.isLoading = false
                    if !signaled {
                        signaled = true
                        cont.resume()
                    }
                }
                // Resume in case the stream finished before yielding any value.
                if !signaled {
                    cont.resume()
                }
            }
        }
    }

    func stop() async {
        streamTask?.cancel()
        streamTask = nil
        await service.stopPublishing()
    }

    func refresh() async {
        do {
            _ = try await service.refresh()
        } catch {
            self.error = PanelError(
                title: "Location Unavailable",
                message: error.localizedDescription,
                isRetryable: true,
            )
        }
    }

    // MARK: - Computed helpers

    /// Returns true when at least one member has an unavailable/stale location.
    var hasUnavailableMembers: Bool {
        members.contains { $0.isStale }
    }
}
