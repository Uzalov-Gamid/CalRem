import SwiftUI

struct TaskListPanel: View {
    let title: String
    let tasks: [TaskItem]
    let lists: [TaskList]
    let onQuickAdd: (String) -> Void
    let onAddTask: () -> Void
    let onEditTask: (TaskItem) -> Void
    let onToggleTask: (TaskItem) -> Void
    let onDeleteTask: (TaskItem) -> Void

    @State private var quickTitle = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Tasks")
                    .font(.headline)
                Spacer()
                Button {
                    onAddTask()
                } label: {
                    Label("New Task", systemImage: "plus.circle.fill")
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .foregroundStyle(.secondary)
                TextField("Add a task", text: $quickTitle)
                    .textFieldStyle(.plain)
                    .onSubmit(submitQuickTask)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
            .padding(16)

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

    private func submitQuickTask() {
        onQuickAdd(quickTitle)
        quickTitle = ""
    }
}
