# Contract: TaskService

**Purpose**: Fetch open tasks from designated Todoist family projects; mark tasks complete.

```swift
protocol TaskServiceProtocol {
    /// Fetch all open tasks across the configured family project IDs.
    /// Returns tasks grouped by project, sorted by priority then due date.
    /// Each task's projectName is populated from the project list.
    func fetchTasks() async throws -> [Task]

    /// Fetch all available Todoist projects for the authenticated user.
    /// Used to populate the project picker in SettingsView.
    func fetchProjects() async throws -> [TaskProject]

    /// Mark a task as complete in Todoist.
    /// Optimistic: caller should update local state before this resolves.
    /// Throws on network failure so caller can roll back.
    func completeTask(id: String) async throws

    /// Connect Todoist via API token entry (v1: manual token; not OAuth).
    func connectTodoist(apiToken: String) async throws

    /// Disconnect and clear the stored Todoist API token from Keychain.
    func disconnectTodoist()

    /// Whether a Todoist token is stored and valid.
    var isConnected: Bool { get }
}
```

**Todoist REST v2 endpoints**:

Fetch projects (to resolve names):

```
GET https://api.todoist.com/rest/v2/projects
Authorization: Bearer {api_token}
```

Fetch tasks per project:

```
GET https://api.todoist.com/rest/v2/tasks?project_id={id}
Authorization: Bearer {api_token}
```

Close (complete) a task:

```
POST https://api.todoist.com/rest/v2/tasks/{task_id}/close
Authorization: Bearer {api_token}
→ 204 No Content on success
```

**Response mapping** (`GET /tasks` item): | Todoist field | `Task` field | |---|---| | `id` | `id` | | `project_id` |
`projectId` | | `content` | `content` | | `description` | `description` | | `due.date` / `due.datetime` | `due.date` | |
`due.is_recurring` | `due.isRecurring` | | `assignee_id` → lookup | `assigneeName` | | `priority` | `priority` (4=p1 …
1=p4) |

**Pagination**: If project has >100 tasks, use `?cursor={next_cursor}` from response header `X-Next-Cursor`.
`TasksPanelView` renders pages with "Show more" affordance.

**Rate limiting**: 1,000 requests/15 min. `TaskService` enforces a minimum 300ms inter-request delay and surfaces
`TaskServiceError.rateLimitExceeded` (HTTP 429) with retry-after.

**Error cases**:

- `TaskServiceError.notConnected` — no API token stored
- `TaskServiceError.authenticationFailed` — HTTP 401; token invalid; prompts reconnect
- `TaskServiceError.rateLimitExceeded` — HTTP 429; backs off and retries
- `TaskServiceError.networkUnavailable` — returns cached tasks

**Contract test fixtures** (`TodoistContractTests.swift`):

```swift
// Given: URLProtocol stub returning fixture /projects and /tasks JSON
// When: fetchTasks() called
// Then: returns [Task] grouped by projectName, sorted priority-then-due
//       task content matches fixture; projectName populated from project list

// Given: URLProtocol stub returning fixture /projects JSON
// When: fetchProjects() called
// Then: returns [TaskProject] with correct id and name fields

// Given: URLProtocol stub returning 204 for /tasks/{id}/close
// When: completeTask(id: "123") called
// Then: completes without throwing

// Given: URLProtocol stub returning 429 with Retry-After: 60
// When: fetchTasks() called
// Then: throws TaskServiceError.rateLimitExceeded
```
