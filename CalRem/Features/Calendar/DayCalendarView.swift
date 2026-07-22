import SwiftUI

struct DayCalendarView: View {
    let tasks: [TaskItem]
    @Binding var selectedDate: Date
    let onEditTask: (CalendarTaskOccurrence) -> Void
    let onUpdateTaskSchedule: (CalendarTaskOccurrence, Date, Date) -> Void
    let onCreateTaskSchedule: (CalendarTaskDraftSchedule) -> Void
    let onScheduleExistingTask: (UUID, Date, Date) -> Void
    let makeTaskMenuActions: (CalendarTaskOccurrence) -> CalendarTaskMenuActions

    private let calendarService = CalendarDateService()
    private let hourHeight = CalRemControlStyle.calendarHourHeight
    private let timeColumnWidth = CalRemControlStyle.calendarTimeColumnWidth
    @State private var creationPreview: CalendarTaskDraftSchedule?
    @State private var dropPreview: CalendarTaskDraftSchedule?

    var body: some View {
        VStack(spacing: 0) {
            allDaySection
            Divider()

            ScrollViewReader { scrollProxy in
                ScrollView {
                    HStack(alignment: .top, spacing: 0) {
                        hourLabels
                        timeline
                    }
                    .padding(.trailing, 12)
                }
                .background(Color(nsColor: .textBackgroundColor))
                .onAppear {
                    scrollToInitialHour(with: scrollProxy)
                }
                .onChange(of: selectedDate) { _, _ in
                    scrollToInitialHour(with: scrollProxy)
                }
            }
        }
    }

    private var allDaySection: some View {
        let allDayTasks = dayOccurrences.filter(\.isAllDay)

        return HStack(alignment: .top, spacing: 10) {
            Text("all-day")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: timeColumnWidth, alignment: .trailing)
                .frame(minHeight: 44)
                .padding(.trailing, 10)

            if allDayTasks.isEmpty {
                Spacer(minLength: 0)
            } else {
                VStack(spacing: 5) {
                    ForEach(allDayTasks) { occurrence in
                        CalendarTaskChip(occurrence: occurrence, menuActions: makeTaskMenuActions(occurrence))
                            .contentShape(RoundedRectangle(cornerRadius: CalRemControlStyle.calendarCellRadius, style: .continuous))
                            .onTapGesture {
                                onEditTask(occurrence)
                            }
                    }
                }
                .padding(.vertical, 10)
            }

            Spacer()
        }
        .padding(.horizontal, 0)
        .frame(minHeight: 44)
        .background(Color(nsColor: .textBackgroundColor))
        .contentShape(Rectangle())
        .gesture(
            TapGesture(count: 2)
                .onEnded {
                    onCreateTaskSchedule(.allDay(on: selectedDate))
                }
        )
    }

    private var hourLabels: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                Text(String(format: "%02d:00", hour))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: timeColumnWidth, height: hourHeight, alignment: .topTrailing)
                    .padding(.trailing, 10)
                    .id(hourAnchor(hour))
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var timeline: some View {
        let timedOccurrences = dayOccurrences.filter(\.isTimed)
        let placements = layoutPlacements(for: timedOccurrences)

        return ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { _ in
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor).opacity(0.16))
                        .frame(height: 1)
                    Color.clear.frame(height: hourHeight - 1)
                }
            }
            .contentShape(Rectangle())
            .gesture(createTaskTapGesture(on: selectedDate))
            .simultaneousGesture(dragToCreateGesture(on: selectedDate))

            if calendarService.isToday(selectedDate) {
                currentTimeLine
            }

            GeometryReader { proxy in
                if let preview = activePreview, let end = preview.end {
                    CalendarTaskCreationPreviewBlock(start: preview.start, end: end)
                        .frame(
                            width: max(proxy.size.width - 16, 52),
                            height: previewHeight(for: preview)
                        )
                        .offset(x: 8, y: previewOffset(for: preview))
                        .zIndex(18)
                }

                ForEach(timedOccurrences) { occurrence in
                    let placement = placements[occurrence.id] ?? TimedTaskPlacement(id: occurrence.id, column: 0, columnCount: 1)
                    let gutter: CGFloat = 8
                    let availableWidth = max(proxy.size.width - gutter * 2, 80)
                    let columnWidth = availableWidth * placement.widthFraction
                    let x = gutter + availableWidth * placement.xFraction

                    InteractiveCalendarTaskBlock(
                        occurrence: occurrence,
                        width: max(columnWidth - gutter, 52),
                        height: max(blockHeight(for: occurrence) - 3, 30),
                        hourHeight: hourHeight,
                        dayWidth: nil,
                        onEditTask: onEditTask,
                        onUpdateSchedule: onUpdateTaskSchedule,
                        menuActions: makeTaskMenuActions(occurrence)
                    )
                    .offset(x: x, y: blockOffset(for: occurrence) + 1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: hourHeight * 24)
        .background(Color(nsColor: .textBackgroundColor))
        .onDrop(
            of: [.plainText],
            delegate: CalendarTaskTimelineDropDelegate(
                day: selectedDate,
                hourHeight: hourHeight,
                preview: $dropPreview,
                onScheduleTaskID: onScheduleExistingTask
            )
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.18))
                .frame(width: 1)
        }
    }

    private func createTaskTapGesture(on day: Date) -> some Gesture {
        SpatialTapGesture(count: 2)
            .onEnded { value in
                let range = CalendarInteractionService.newTaskRange(
                    on: day,
                    locationY: value.location.y,
                    hourHeight: hourHeight
                )
                onCreateTaskSchedule(.timed(start: range.start, end: range.end))
        }
    }

    private func dragToCreateGesture(on day: Date) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .local)
            .onChanged { value in
                let range = CalendarInteractionService.newTaskRange(
                    on: day,
                    startY: value.startLocation.y,
                    currentY: value.location.y,
                    hourHeight: hourHeight
                )
                creationPreview = .timed(start: range.start, end: range.end)
            }
            .onEnded { value in
                let range = CalendarInteractionService.newTaskRange(
                    on: day,
                    startY: value.startLocation.y,
                    currentY: value.location.y,
                    hourHeight: hourHeight
                )
                creationPreview = nil
                onCreateTaskSchedule(.timed(start: range.start, end: range.end))
            }
    }

    private var currentTimeLine: some View {
        let minutes = calendarService.minutesFromStartOfDay(for: .now)
        let y = CGFloat(minutes) / 60 * hourHeight

        return Rectangle()
            .fill(Color.red.opacity(0.75))
            .frame(height: 1)
            .offset(y: y)
    }

    private var dayOccurrences: [CalendarTaskOccurrence] {
        CalendarRecurrenceService.occurrences(for: tasks, on: selectedDate, calendar: calendarService.calendar)
    }

    private var activePreview: CalendarTaskDraftSchedule? {
        creationPreview ?? dropPreview
    }

    private func blockOffset(for occurrence: CalendarTaskOccurrence) -> CGFloat {
        guard let start = occurrence.calendarStart else { return 0 }
        return CGFloat(calendarService.minutesFromStartOfDay(for: start)) / 60 * hourHeight
    }

    private func blockHeight(for occurrence: CalendarTaskOccurrence) -> CGFloat {
        max(CGFloat(occurrence.duration / 3600) * hourHeight, 32)
    }

    private func previewOffset(for preview: CalendarTaskDraftSchedule) -> CGFloat {
        CGFloat(calendarService.minutesFromStartOfDay(for: preview.start)) / 60 * hourHeight
    }

    private func previewHeight(for preview: CalendarTaskDraftSchedule) -> CGFloat {
        guard let end = preview.end else { return 32 }
        return max(CGFloat(end.timeIntervalSince(preview.start) / 3600) * hourHeight, 32)
    }

    private func layoutPlacements(for occurrences: [CalendarTaskOccurrence]) -> [String: TimedTaskPlacement] {
        let inputs = occurrences.compactMap { occurrence -> TimedTaskLayoutInput? in
            guard let start = occurrence.calendarStart, let end = occurrence.calendarEnd else {
                return nil
            }
            return TimedTaskLayoutInput(id: occurrence.id, startDate: start, endDate: end)
        }

        return CalendarTaskLayoutService.placements(for: inputs)
    }

    private func scrollToInitialHour(with proxy: ScrollViewProxy) {
        let targetHour = calendarService.calendar.isDateInToday(selectedDate)
            ? max(calendarService.calendar.component(.hour, from: .now) - 1, 0)
            : 7

        DispatchQueue.main.async {
            withAnimation(.snappy(duration: 0.2)) {
                proxy.scrollTo(hourAnchor(targetHour), anchor: .top)
            }
        }
    }

    private func hourAnchor(_ hour: Int) -> String {
        "day-hour-\(hour)"
    }
}
