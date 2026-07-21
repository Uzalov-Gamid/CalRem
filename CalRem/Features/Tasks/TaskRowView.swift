import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17))
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Circle()
                        .fill(ListColor.named(task.list?.colorName).color)
                        .frame(width: 7, height: 7)

                    Text(task.list?.name ?? "No List")
                        .lineLimit(1)

                    if task.isScheduled {
                        Text(DateFormatters.taskSchedule(task))
                            .lineLimit(1)
                    }

                    if task.reminderDate != nil {
                        Image(systemName: "bell")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .padding(.vertical, 7)
        .contextMenu {
            Button("Edit", action: onEdit)
            Button(task.isCompleted ? "Mark Incomplete" : "Complete", action: onToggle)
            Divider()
            Button("Delete", role: .destructive, action: onDelete)
        }
        .onTapGesture(count: 2, perform: onEdit)
    }
}
