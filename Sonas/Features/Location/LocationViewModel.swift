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
    private var streamTask: Swift.Task<Void, Never>?

    init(service: any LocationServiceProtocol) {
        self.service = service
    }

    // MARK: - Lifecycle

    func start() async {
        isLoading = true
        error = nil
        await service.startPublishing()
        streamTask = Swift.Task { [weak self] in
            for await updated in service.familyLocations {
                guard !Swift.Task<Never, Never>.isCancelled else { break }
                await MainActor.run {
                    self?.members = updated.sorted { $0.displayName < $1.displayName }
                    self?.isLoading = false
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
                isRetryable: true
            )
        }
    }

    // MARK: - Computed helpers

    /// Returns true when at least one member has an unavailable/stale location.
    var hasUnavailableMembers: Bool {
        members.contains { $0.isStale }
    }
}
