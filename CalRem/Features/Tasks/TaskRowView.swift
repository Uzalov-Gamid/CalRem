import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17))
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                    .frame(width: CalRemControlStyle.compactHitSize, height: CalRemControlStyle.compactHitSize)
                    .contentShape(Circle())
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

            Menu {
                Button("Edit", action: onEdit)
                Button(task.isCompleted ? "Mark Incomplete" : "Complete", action: onToggle)
                Divider()
                Button("Delete", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: CalRemControlStyle.minimumHitSize, height: CalRemControlStyle.minimumHitSize)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help("Task actions")
            .opacity(isHovering ? 1 : 0.55)
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            isHovering ? Color.accentColor.opacity(0.055) : Color.clear,
            in: RoundedRectangle(cornerRadius: CalRemControlStyle.rowRadius, style: .continuous)
        )
        .clipShape(RoundedRectangle(cornerRadius: CalRemControlStyle.rowRadius, style: .continuous))
        .contextMenu {
            Button("Edit", action: onEdit)
            Button(task.isCompleted ? "Mark Incomplete" : "Complete", action: onToggle)
            Divider()
            Button("Delete", role: .destructive, action: onDelete)
        }
        .onTapGesture(count: 2, perform: onEdit)
        .onHover { isHovering = $0 }
    }
}
