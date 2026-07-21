import SwiftUI

struct CalendarTaskChip: View {
    let task: TaskItem
    var compact = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: compact ? 5 : 7, height: compact ? 5 : 7)

            Text(task.title)
                .lineLimit(1)

            if !compact, task.isTimed, let start = task.calendarStart {
                Text(DateFormatters.time(start))
                    .foregroundStyle(.secondary)
            }
        }
        .font(compact ? .caption2 : .caption)
        .padding(.horizontal, compact ? 5 : 7)
        .padding(.vertical, compact ? 3 : 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(task.isCompleted ? 0.10 : 0.16), in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(color.opacity(task.isCompleted ? 0.15 : 0.28), lineWidth: 1)
        }
        .foregroundStyle(task.isCompleted ? .secondary : .primary)
        .opacity(task.isCompleted ? 0.65 : 1)
        .help(helpText)
    }

    private var color: Color {
        ListColor.named(task.list?.colorName).color
    }

    private var helpText: String {
        if task.isScheduled {
            "\(task.title) - \(DateFormatters.taskSchedule(task))"
        } else {
            task.title
        }
    }
}

struct CalendarTaskBlock: View {
    let task: TaskItem

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(task.title)
                .font(.caption.weight(.semibold))
                .lineLimit(2)

            if let start = task.calendarStart, let end = task.calendarEnd {
                Text("\(DateFormatters.time(start)) - \(DateFormatters.time(end))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(color.opacity(task.isCompleted ? 0.10 : 0.18), in: RoundedRectangle(cornerRadius: 7))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 3)
                .padding(.vertical, 5)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .stroke(color.opacity(0.30), lineWidth: 1)
        }
        .foregroundStyle(task.isCompleted ? .secondary : .primary)
        .opacity(task.isCompleted ? 0.65 : 1)
        .help(DateFormatters.taskSchedule(task))
    }

    private var color: Color {
        ListColor.named(task.list?.colorName).color
    }
}
