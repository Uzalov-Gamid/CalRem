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
            quickAddField

            if tasks.isEmpty {
                ContentUnavailableView(
                    "No Tasks",
                    systemImage: "checklist",
                    description: Text("Add a task to start planning.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        Divider()
                            .padding(.leading, 58)

                    ForEach(tasks) { task in
                        TaskRowView(
                            task: task,
                            onToggle: { onToggleTask(task) },
                            onEdit: { onEditTask(task) },
                            onDelete: { onDeleteTask(task) }
                        )
                            .padding(.horizontal, 22)

                            Divider()
                                .padding(.leading, 80)
                                .padding(.trailing, 22)
                        }
                    }
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                Text(taskCountTitle)
                    .font(.callout)
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
        .padding(.horizontal, 28)
        .padding(.top, 28)
        .padding(.bottom, 14)
    }

    private var quickAddField: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            TextField("Add a task", text: $quickTitle)
                .textFieldStyle(.plain)
                .onSubmit(submitQuickTask)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.24), lineWidth: 1)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 18)
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
