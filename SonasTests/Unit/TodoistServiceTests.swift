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

    // MARK: - T095.3: availableProjects populated after connectTodoist

    @Test
    func `given service with projects when connectTodoist called then availableProjects populated on viewModel`(
    ) async throws {
        final class ProjectService: TaskServiceProtocol, @unchecked Sendable {
            var isConnected: Bool = false
            func fetchTasks() async throws -> [Task] {
                []
            }

            func fetchProjects() async throws -> [TaskProject] {
                [TaskProject(id: "p1", name: "Work"), TaskProject(id: "p2", name: "Home")]
            }

            func completeTask(id _: String) async throws {}
            func connectTodoist(apiToken _: String) async throws {
                isConnected = true
            }

            func disconnectTodoist() async {
                isConnected = false
            }
        }

        let vm = TasksViewModel(service: ProjectService())
        try await vm.connectTodoist(apiToken: "test-token")

        #expect(vm.availableProjects.count == 2, "availableProjects must be populated after connect")
        #expect(vm.availableProjects[0].name == "Work")
        #expect(vm.availableProjects[1].name == "Home")
    }

    // MARK: - T095.4: availableProjects cleared on disconnect

    @Test
    func `given connected viewModel when disconnectTodoist called then availableProjects is empty`() async {
        final class AlwaysConnectedService: TaskServiceProtocol, @unchecked Sendable {
            var isConnected: Bool = true
            func fetchTasks() async throws -> [Task] {
                []
            }

            func fetchProjects() async throws -> [TaskProject] {
                [TaskProject(id: "p1", name: "Work")]
            }

            func completeTask(id _: String) async throws {}
            func connectTodoist(apiToken _: String) async throws {}
            func disconnectTodoist() async {
                isConnected = false
            }
        }

        let vm = TasksViewModel(service: AlwaysConnectedService())
        await vm.start()
        #expect(!vm.availableProjects.isEmpty, "precondition: projects must load on start")

        await vm.disconnectTodoist()
        #expect(vm.availableProjects.isEmpty, "availableProjects must be cleared on disconnect")
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
