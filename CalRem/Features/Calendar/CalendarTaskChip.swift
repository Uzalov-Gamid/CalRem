import SwiftUI
import UniformTypeIdentifiers

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
        .background(color.opacity(task.isCompleted ? 0.08 : 0.14), in: RoundedRectangle(cornerRadius: CalRemControlStyle.calendarCellRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CalRemControlStyle.calendarCellRadius, style: .continuous)
                .stroke(color.opacity(task.isCompleted ? 0.12 : 0.30), lineWidth: 1)
        }
        .foregroundStyle(task.isCompleted ? .secondary : .primary)
        .opacity(task.isCompleted ? 0.65 : 1)
        .contentShape(RoundedRectangle(cornerRadius: CalRemControlStyle.calendarCellRadius, style: .continuous))
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
    var isInteracting = false

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
        .background(
            color.opacity(task.isCompleted ? 0.09 : (isInteracting ? 0.28 : 0.20)),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(width: 4)
                .padding(.vertical, 6)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(color.opacity(isInteracting ? 0.52 : 0.34), lineWidth: 1)
        }
        .shadow(color: isInteracting ? color.opacity(0.22) : .clear, radius: isInteracting ? 10 : 0, y: isInteracting ? 5 : 0)
        .foregroundStyle(task.isCompleted ? .secondary : .primary)
        .opacity(task.isCompleted ? 0.65 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(DateFormatters.taskSchedule(task))
    }

    private var color: Color {
        ListColor.named(task.list?.colorName).color
    }
}

struct CalendarTaskCreationPreviewBlock: View {
    let start: Date
    let end: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("New Task")
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            Text("\(DateFormatters.time(start)) - \(DateFormatters.time(end))")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            Color.accentColor.opacity(0.18),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.accentColor)
                .frame(width: 4)
                .padding(.vertical, 6)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.accentColor.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
        .allowsHitTesting(false)
    }
}

struct CalendarTaskTimelineDropDelegate: DropDelegate {
    let day: Date
    let hourHeight: CGFloat
    @Binding var preview: CalendarTaskDraftSchedule?
    let onScheduleTaskID: (UUID, Date, Date) -> Void

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [UTType.plainText])
    }

    func dropEntered(info: DropInfo) {
        updatePreview(for: info.location.y)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        updatePreview(for: info.location.y)
        return DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {
        preview = nil
    }

    func performDrop(info: DropInfo) -> Bool {
        let range = CalendarInteractionService.newTaskRange(
            on: day,
            locationY: info.location.y,
            hourHeight: hourHeight
        )
        let providers = info.itemProviders(for: [UTType.plainText])
        preview = nil

        guard let provider = providers.first else { return false }

        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let rawValue = object as? String,
                  let taskID = UUID(uuidString: rawValue) else {
                return
            }

            DispatchQueue.main.async {
                onScheduleTaskID(taskID, range.start, range.end)
            }
        }

        return true
    }

    private func updatePreview(for locationY: CGFloat) {
        let range = CalendarInteractionService.newTaskRange(
            on: day,
            locationY: locationY,
            hourHeight: hourHeight
        )
        preview = .timed(start: range.start, end: range.end)
    }
}
