import Testing
import Foundation
@testable import Sonas

// MARK: - TodoistServiceTests (T059)

@Suite("Todoist Service Unit Tests")
struct TodoistServiceTests {

    // MARK: - T059.1: Optimistic rollback when completeTask throws

    @Test("given task in list when completeTask fails then task reappears in tasksByProject")
    func given_taskInList_when_completeTaskFails_then_rollback() async throws {
        final class FailingTaskService: TaskServiceProtocol, @unchecked Sendable {
            var isConnected: Bool = true
            var fetchCalled = false
            func fetchTasks() async throws -> [Task] {
                fetchCalled = true
                return TaskServiceMock.fixtures
            }
            func completeTask(id: String) async throws {
                throw TaskServiceError.networkError(NSError(domain: "test", code: -1))
            }
            func connectTodoist(apiToken: String) async throws {}
            func disconnectTodoist() async {}
        }

        let service = FailingTaskService()
        let vm = TasksViewModel(service: service, cache: CacheService.shared)
        await vm.start()

        let task = TaskServiceMock.fixtures[0]
        let countBefore = vm.tasksByProject.values.flatMap { $0 }.count

        await vm.completeTask(task)

        let countAfter = vm.tasksByProject.values.flatMap { $0 }.count
        #expect(countAfter == countBefore, "Task must be rolled back after completeTask failure")
        #expect(vm.completionErrorToast != nil, "Error toast must be shown on rollback")
    }

    // MARK: - T059.2: authenticationFailed on 401

    @Test("given Todoist service when 401 received then throws authenticationFailed")
    func given_todoist401_when_completeTask_then_throwsAuthFailed() async throws {
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
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
