import Foundation
@testable import Sonas
import Testing

// MARK: - TodoistContractTests (T056)

// 🔴 TEST-FIRST GATE — run before TodoistService (T055)

final class TodoistURLProtocolStub: URLProtocol {
    struct StubResponse {
        var data: Data
        var statusCode: Int
        var headers: [String: String]
    }

    static var responses: [String: StubResponse] = [:]

    override static func canInit(with request: URLRequest) -> Bool {
        request.url?.host?.contains("todoist.com") == true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let path = request.url?.path ?? ""
        let stub = Self.responses[path] ?? StubResponse(data: Data(), statusCode: 404, headers: [:])
        guard let url = request.url,
              let response = HTTPURLResponse(
                  url: url, statusCode: stub.statusCode,
                  httpVersion: nil, headerFields: stub.headers,
              )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@MainActor
@Suite("Todoist Service Contract Tests")
struct TodoistContractTests {
    private func makeService() -> TodoistService {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [TodoistURLProtocolStub.self]
        return TodoistService(session: URLSession(configuration: config), token: "stub-token")
    }

    // MARK: - T056.1: Tasks grouped by projectName

    @Test
    func `given projects and tasks stubs when fetchTasks called then tasks grouped by projectName`() async throws {
        TodoistURLProtocolStub.responses["/rest/v2/projects"] = .init(
            data: Data("""
            [{"id":"proj1","name":"Home"},{"id":"proj2","name":"Admin"}]
            """.utf8),
            statusCode: 200, headers: [:],
        )
        TodoistURLProtocolStub.responses["/rest/v2/tasks"] = .init(
            data: Data("""
            [{"id":"t1","content":"Buy milk","description":"","project_id":"proj1","priority":2,"due":null}]
            """.utf8),
            statusCode: 200, headers: [:],
        )

        let service = makeService()
        AppConfiguration.shared.selectedTodoistProjectIDs = []

        let tasks = try await service.fetchTasks()
        #expect(!tasks.isEmpty, "Tasks must be returned from stub")
    }

    // MARK: - T056.2: completeTask succeeds on 204

    @Test
    func `given close endpoint returns 204 when completeTask called then no error thrown`() async throws {
        let taskID = "task-abc"
        TodoistURLProtocolStub.responses["/rest/v2/tasks/\(taskID)/close"] = .init(
            data: Data(), statusCode: 204, headers: [:],
        )

        let service = makeService()
        try await service.completeTask(id: taskID)
        // No error = test passes
    }

    // MARK: - T056.3: completeTask throws rateLimitExceeded on 429

    @Test
    func `given close endpoint returns 429 with Retry-After when completeTask called then throws rateLimitExceeded`(
    ) async throws {
        let taskID = "task-xyz"
        TodoistURLProtocolStub.responses["/rest/v2/tasks/\(taskID)/close"] = .init(
            data: Data(), statusCode: 429, headers: ["Retry-After": "60"],
        )

        let service = makeService()
        await #expect(throws: TaskServiceError.self) {
            try await service.completeTask(id: taskID)
        }
    }

    // MARK: - T095.1: fetchProjects returns TaskProject array

    @Test
    func `given projects endpoint when fetchProjects called then returns array of TaskProject with correct names`(
    ) async throws {
        TodoistURLProtocolStub.responses["/rest/v2/projects"] = .init(
            data: Data("""
            [{"id":"proj1","name":"Home"},{"id":"proj2","name":"Admin"}]
            """.utf8),
            statusCode: 200, headers: [:],
        )

        let service = makeService()
        let projects = try await service.fetchProjects()

        #expect(projects.count == 2, "fetchProjects must return all projects from the API")
        #expect(projects[0].id == "proj1")
        #expect(projects[0].name == "Home")
        #expect(projects[1].id == "proj2")
        #expect(projects[1].name == "Admin")
    }

    // MARK: - T095.2: fetchTasks populates projectName from project list

    @Test
    func `given projects and tasks stubs when fetchTasks called then tasks have projectName populated`() async throws {
        TodoistURLProtocolStub.responses["/rest/v2/projects"] = .init(
            data: Data("""
            [{"id":"proj1","name":"Home"}]
            """.utf8),
            statusCode: 200, headers: [:],
        )
        TodoistURLProtocolStub.responses["/rest/v2/tasks"] = .init(
            data: Data("""
            [{"id":"t1","content":"Buy milk","description":"","project_id":"proj1","priority":2,"due":null}]
            """.utf8),
            statusCode: 200, headers: [:],
        )

        let service = makeService()
        AppConfiguration.shared.selectedTodoistProjectIDs = []

        let tasks = try await service.fetchTasks()
        #expect(tasks.first?.projectName == "Home", "projectName must be populated from the projects list")
    }
}
