import SwiftUI
import UniformTypeIdentifiers

struct CalendarTaskChip: View {
    let occurrence: CalendarTaskOccurrence
    var compact = false

    init(task: TaskItem, compact: Bool = false) {
        self.occurrence = CalendarTaskOccurrence(task: task) ?? CalendarTaskOccurrence(
            task: task,
            startDate: task.calendarStart,
            endDate: task.calendarEnd,
            isAllDay: task.isAllDay,
            isGenerated: false
        )
        self.compact = compact
    }

    init(occurrence: CalendarTaskOccurrence, compact: Bool = false) {
        self.occurrence = occurrence
        self.compact = compact
    }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: compact ? 5 : 7, height: compact ? 5 : 7)

            Text(occurrence.title)
                .lineLimit(1)

            if !compact, occurrence.isTimed, let start = occurrence.calendarStart {
                Text(DateFormatters.time(start))
                    .foregroundStyle(.secondary)
            }

            if occurrence.isRepeating {
                Image(systemName: "repeat")
                    .font(.system(size: compact ? 8 : 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .font(compact ? .caption2 : .caption)
        .padding(.horizontal, compact ? 5 : 7)
        .padding(.vertical, compact ? 3 : 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(occurrence.isCompleted ? 0.08 : 0.14), in: RoundedRectangle(cornerRadius: CalRemControlStyle.calendarCellRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CalRemControlStyle.calendarCellRadius, style: .continuous)
                .stroke(color.opacity(occurrence.isCompleted ? 0.12 : 0.30), lineWidth: 1)
        }
        .foregroundStyle(occurrence.isCompleted ? .secondary : .primary)
        .opacity(occurrence.isCompleted ? 0.65 : 1)
        .contentShape(RoundedRectangle(cornerRadius: CalRemControlStyle.calendarCellRadius, style: .continuous))
        .help(helpText)
    }

    private var color: Color {
        ListColor.named(occurrence.list?.colorName).color
    }

    private var helpText: String {
        if occurrence.isScheduled {
            "\(occurrence.title) - \(DateFormatters.taskSchedule(occurrence))"
        } else {
            occurrence.title
        }
    }
}

struct CalendarTaskBlock: View {
    let occurrence: CalendarTaskOccurrence
    var isInteracting = false

    init(task: TaskItem, isInteracting: Bool = false) {
        self.occurrence = CalendarTaskOccurrence(task: task) ?? CalendarTaskOccurrence(
            task: task,
            startDate: task.calendarStart,
            endDate: task.calendarEnd,
            isAllDay: task.isAllDay,
            isGenerated: false
        )
        self.isInteracting = isInteracting
    }

    init(occurrence: CalendarTaskOccurrence, isInteracting: Bool = false) {
        self.occurrence = occurrence
        self.isInteracting = isInteracting
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(occurrence.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)

                if occurrence.isRepeating {
                    Image(systemName: "repeat")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }

            if let start = occurrence.calendarStart, let end = occurrence.calendarEnd {
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
            color.opacity(occurrence.isCompleted ? 0.09 : (isInteracting ? 0.28 : 0.20)),
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
        .foregroundStyle(occurrence.isCompleted ? .secondary : .primary)
        .opacity(occurrence.isCompleted ? 0.65 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(DateFormatters.taskSchedule(occurrence))
    }

    private var color: Color {
        ListColor.named(occurrence.list?.colorName).color
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
