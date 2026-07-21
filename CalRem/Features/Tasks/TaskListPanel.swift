import SwiftUI

struct TaskListPanel: View {
    let title: String
    let tasks: [TaskItem]
    let onQuickAdd: (String) -> Void
    let onAddTask: () -> Void
    let onEditTask: (TaskItem) -> Void
    let onToggleTask: (TaskItem) -> Void
    let onDeleteTask: (TaskItem) -> Void

    @State private var quickTitle = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            quickAddField

            if tasks.isEmpty {
                ContentUnavailableView(
                    "No Tasks",
                    systemImage: "checklist",
                    description: Text("Add a task to start planning.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(tasks) { task in
                        TaskRowView(
                            task: task,
                            onToggle: { onToggleTask(task) },
                            onEdit: { onEditTask(task) },
                            onDelete: { onDeleteTask(task) }
                        )
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title2.weight(.semibold))
                Text(taskCountTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                onAddTask()
            } label: {
                Label("New Task", systemImage: "plus.circle.fill")
            }
            .buttonStyle(CalRemPillButtonStyle(isProminent: true))
            .help("Create task")
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }

    private var quickAddField: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .foregroundStyle(.secondary)
            TextField("Add a task", text: $quickTitle)
                .textFieldStyle(.plain)
                .onSubmit(submitQuickTask)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }

    private var taskCountTitle: String {
        let count = tasks.count
        return count == 1 ? "1 task" : "\(count) tasks"
    }

    private func submitQuickTask() {
        onQuickAdd(quickTitle)
        quickTitle = ""
    }
}
