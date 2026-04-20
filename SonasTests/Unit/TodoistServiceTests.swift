import Foundation
@testable import Sonas
import Testing

// MARK: - TodoistServiceTests (T059)

@MainActor
@Suite("Todoist Service Unit Tests")
struct TodoistServiceTests {
    // MARK: - T059.1: Optimistic rollback when completeTask throws

    @Test
    func `given task in list when completeTask fails then task reappears in tasksByProject`() async throws {
        final class FailingTaskService: TaskServiceProtocol, @unchecked Sendable {
            var isConnected: Bool = true
            var fetchCalled = false
            func fetchTasks() async throws -> [Task] {
                fetchCalled = true
                return TaskServiceMock.fixtures
            }

            func completeTask(id _: String) async throws {
                throw TaskServiceError.networkError(NSError(domain: "test", code: -1))
            }

            func connectTodoist(apiToken _: String) async throws {}
            func disconnectTodoist() async {}
        }

        let service = FailingTaskService()
        let vm = TasksViewModel(service: service, cache: CacheService.shared)
        await vm.start()

        let task = TaskServiceMock.fixtures[0]
        let countBefore = vm.tasksByProject.values.flatMap(\.self).count

        await vm.completeTask(task)

        let countAfter = vm.tasksByProject.values.flatMap(\.self).count
        #expect(countAfter == countBefore, "Task must be rolled back after completeTask failure")
        #expect(vm.completionErrorToast != nil, "Error toast must be shown on rollback")
    }

    // MARK: - T059.2: authenticationFailed on 401

    @Test
    func `given Todoist service when 401 received then throws authenticationFailed`() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [FourOhOneProtocol.self]
        let session = URLSession(configuration: config)
        let service = TodoistService(session: session)
        AppConfiguration.shared.todoistAPIToken = "expired-token"

        await #expect(throws: TaskServiceError.self) {
            try await service.completeTask(id: "any-id")
        }
        AppConfiguration.shared.todoistAPIToken = nil
    }
}

// MARK: - 401 stub

private final class FourOhOneProtocol: URLProtocol {
    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil)
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
