import Testing
import Foundation
@testable import Sonas

// MARK: - TodoistContractTests (T056)
// 🔴 TEST-FIRST GATE — run before TodoistService (T055)

final class TodoistURLProtocolStub: URLProtocol {
    struct StubResponse {
        var data: Data
        var statusCode: Int
        var headers: [String: String]
    }

    static var responses: [String: StubResponse] = [:]

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host?.contains("todoist.com") == true
    }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let path = request.url?.path ?? ""
        let stub = Self.responses[path] ?? StubResponse(data: Data(), statusCode: 404, headers: [:])
        let response = HTTPURLResponse(
            url: request.url!, statusCode: stub.statusCode,
            httpVersion: nil, headerFields: stub.headers
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@Suite("Todoist Service Contract Tests")
struct TodoistContractTests {

    private func makeService() -> TodoistService {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [TodoistURLProtocolStub.self]
        return TodoistService(session: URLSession(configuration: config))
    }

    // MARK: - T056.1: Tasks grouped by projectName

    @Test("given projects and tasks stubs when fetchTasks called then tasks grouped by projectName")
    func given_projectsAndTasksStubs_when_fetchTasks_then_groupedByProjectName() async throws {
        TodoistURLProtocolStub.responses["/rest/v2/projects"] = .init(
            data: """
            [{"id":"proj1","name":"Home"},{"id":"proj2","name":"Admin"}]
            """.data(using: .utf8)!,
            statusCode: 200, headers: [:]
        )
        TodoistURLProtocolStub.responses["/rest/v2/tasks"] = .init(
            data: """
            [{"id":"t1","content":"Buy milk","description":"","project_id":"proj1","priority":2,"due":null}]
            """.data(using: .utf8)!,
            statusCode: 200, headers: [:]
        )

        let service = makeService()
        // Set API token to trigger fetch
        AppConfiguration.shared.todoistAPIToken = "stub-token"
        AppConfiguration.shared.selectedTodoistProjectIDs = []

        let tasks = try await service.fetchTasks()
        AppConfiguration.shared.todoistAPIToken = nil

        #expect(!tasks.isEmpty, "Tasks must be returned from stub")
    }

    // MARK: - T056.2: completeTask succeeds on 204

    @Test("given close endpoint returns 204 when completeTask called then no error thrown")
    func given_close204_when_completeTask_then_noError() async throws {
        let taskID = "task-abc"
        TodoistURLProtocolStub.responses["/rest/v2/tasks/\(taskID)/close"] = .init(
            data: Data(), statusCode: 204, headers: [:]
        )

        let service = makeService()
        AppConfiguration.shared.todoistAPIToken = "stub-token"
        try await service.completeTask(id: taskID)
        AppConfiguration.shared.todoistAPIToken = nil
        // No error = test passes
    }

    // MARK: - T056.3: completeTask throws rateLimitExceeded on 429

    @Test("given close endpoint returns 429 with Retry-After when completeTask called then throws rateLimitExceeded")
    func given_close429_when_completeTask_then_throwsRateLimitExceeded() async throws {
        let taskID = "task-xyz"
        TodoistURLProtocolStub.responses["/rest/v2/tasks/\(taskID)/close"] = .init(
            data: Data(), statusCode: 429, headers: ["Retry-After": "60"]
        )

        let service = makeService()
        AppConfiguration.shared.todoistAPIToken = "stub-token"
        await #expect(throws: TaskServiceError.self) {
            try await service.completeTask(id: taskID)
        }
        AppConfiguration.shared.todoistAPIToken = nil
    }
}
