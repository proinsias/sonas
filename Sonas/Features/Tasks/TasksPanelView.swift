import SwiftUI

// MARK: - TasksPanelView (T058)

struct TasksPanelView: View {
    @State var viewModel: TasksViewModel

    var body: some View {
        PanelView(title: "Tasks", icon: Icon.tasks, lastUpdated: viewModel.lastUpdated) {
            content
        }
        .task { await viewModel.start() }
        .onDisappear { viewModel.stop() }
        .overlay(alignment: .bottom) {
            if let toast = viewModel.completionErrorToast {
                ToastView(message: toast) { viewModel.dismissToast() }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 8)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.completionErrorToast)
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.isConnected {
            connectPrompt
        } else if viewModel.isLoading, viewModel.tasksByProject.isEmpty {
            LoadingStateView(rows: 3)
        } else if let error = viewModel.error {
            ErrorStateView(error: error) { Task { await viewModel.refresh() } }
        } else if viewModel.tasksByProject.isEmpty {
            emptyState
        } else {
            taskList
                .staleDataBadge(lastUpdated: viewModel.lastUpdated ?? .now) {
                    Task { await viewModel.refresh() }
                }
        }
    }

    // MARK: - Task list grouped by project

    private var taskList: some View {
        RefreshableScrollView { await viewModel.refresh() } content: {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.tasksByProject.keys.sorted(), id: \.self) { project in
                    projectSection(project: project)
                }
            }
        }
    }

    private func projectSection(project: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project)
                .font(.sectionHeader)
                .foregroundStyle(Color.secondaryLabel)

            ForEach(viewModel.tasksByProject[project] ?? []) { task in
                TaskRow(task: task) {
                    Task { await viewModel.completeTask(task) }
                }
            }
        }
    }

    // MARK: - Empty / connect states

    private var emptyState: some View {
        Text("No open tasks")
            .font(.caption)
            .foregroundStyle(Color.secondaryLabel)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
    }

    private var connectPrompt: some View {
        VStack(spacing: 8) {
            Image(systemName: Icon.connect)
                .font(.title2)
                .foregroundStyle(Color.secondaryLabel)
                .accessibilityHidden(true)
            Text("Connect Todoist")
                .font(.headline)
                .foregroundStyle(Color.panelForeground)
            Text("Enter your API token in Settings.")
                .font(.caption)
                .foregroundStyle(Color.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Connect Todoist: Enter your API token in Settings")
    }
}

// MARK: - TaskRow

private struct TaskRow: View {
    let task: TodoTask
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onComplete) {
                Image(systemName: task.isCompleting ? "circle.dashed" : Icon.incomplete)
                    .font(.title3)
                    .foregroundStyle(Color.accent)
            }
            .disabled(task.isCompleting)
            .accessibilityInfo("Mark '\(task.content)' complete", hint: "Removes task from the list")

            VStack(alignment: .leading, spacing: 2) {
                Text(task.content)
                    .font(.body)
                    .foregroundStyle(Color.panelForeground)
                    .strikethrough(task.isCompleting)

                if let due = task.due {
                    Text(due.string)
                        .font(.caption)
                        .foregroundStyle(Color.secondaryLabel)
                }
            }

            Spacer()

            if task.priority >= .high {
                Circle()
                    .fill(task.priority == .urgent ? Color.errorRed : Color.accent)
                    .frame(width: 6, height: 6)
                    .accessibilityLabel("\(task.priority.label) priority")
            }
        }
    }
}

// MARK: - ToastView

private struct ToastView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Text(message)
                .font(.caption)
                .foregroundStyle(.white)
            Spacer()
            Button("Dismiss", action: onDismiss)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.errorRed, in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
    }
}
