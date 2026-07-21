import SwiftUI

struct TaskRowView: View {
    let task: TaskItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                completionMark
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(.callout)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                HStack(spacing: 7) {
                    Circle()
                        .fill(ListColor.named(task.list?.colorName).color)
                        .frame(width: 7, height: 7)

                    Text(task.list?.name ?? "No List")
                        .lineLimit(1)

                    if task.isScheduled {
                        metadataPill(
                            title: DateFormatters.taskSchedule(task),
                            systemImage: task.isAllDay ? "calendar" : "clock"
                        )
                    }

                    if task.reminderDate != nil {
                        metadataPill(title: "Alert", systemImage: "bell")
                    }

                    if task.isRepeating {
                        metadataPill(title: task.recurrenceRule.shortTitle, systemImage: "repeat")
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
        .padding(.horizontal, 6)
        .padding(.vertical, 11)
        .background(
            isHovering ? Color.accentColor.opacity(0.055) : Color.clear,
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .contextMenu {
            Button("Edit", action: onEdit)
            Button(task.isCompleted ? "Mark Incomplete" : "Complete", action: onToggle)
            Divider()
            Button("Delete", role: .destructive, action: onDelete)
        }
        .onTapGesture(count: 2, perform: onEdit)
        .onHover { isHovering = $0 }
    }

    private var completionMark: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    task.isCompleted ? Color.green : Color.secondary.opacity(0.55),
                    lineWidth: 1.7
                )
                .background(
                    Circle()
                        .fill(task.isCompleted ? Color.green : Color.clear)
                )

            if task.isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 22, height: 22)
        .frame(width: CalRemControlStyle.minimumHitSize, height: CalRemControlStyle.minimumHitSize)
        .contentShape(Circle())
    }

    private func metadataPill(title: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .medium))
            Text(title)
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .frame(minHeight: 21)
        .background(Color.secondary.opacity(0.10), in: Capsule())
    }
}
