import SwiftUI

struct WeekCalendarView: View {
    let tasks: [TaskItem]
    var visibleDays: [Date]? = nil
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
            weekHeader
            Divider()
            allDayRow
            Divider()

            ScrollViewReader { scrollProxy in
                ScrollView {
                    HStack(alignment: .top, spacing: 0) {
                        hourLabels
                        ForEach(calendarService.week(containing: selectedDate), id: \.self) { day in
                            dayTimeline(day)
                        }
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

    private var weekHeader: some View {
        HStack(spacing: 0) {
            Text("")
                .frame(width: timeColumnWidth, height: 1)

            ForEach(weekDays, id: \.self) { day in
                WeekDayHeaderCell(
                    day: day,
                    isToday: calendarService.isToday(day),
                    isSelected: calendarService.calendar.isDate(day, inSameDayAs: selectedDate)
                )
                .onTapGesture {
                    selectedDate = day
                }
            }
        }
        .frame(height: 58)
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var allDayRow: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("all-day")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: timeColumnWidth, alignment: .trailing)
                .frame(minHeight: 42)
                .padding(.trailing, 10)

            ForEach(weekDays, id: \.self) { day in
                allDayCell(for: day)
            }
        }
        .frame(minHeight: 42)
        .background(Color(nsColor: .textBackgroundColor))
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

    private func dayTimeline(_ day: Date) -> some View {
        let timedOccurrences = occurrencesFor(day: day).filter(\.isTimed)
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
            .gesture(createTaskTapGesture(on: day))
            .simultaneousGesture(dragToCreateGesture(on: day))

            if calendarService.isToday(day) {
                currentTimeLine
            }

            GeometryReader { proxy in
                if let preview = activePreview,
                   let end = preview.end,
                   calendarService.calendar.isDate(preview.start, inSameDayAs: day) {
                    CalendarTaskCreationPreviewBlock(start: preview.start, end: end)
                        .frame(
                            width: max(proxy.size.width - 8, 36),
                            height: previewHeight(for: preview)
                        )
                        .offset(x: 4, y: previewOffset(for: preview))
                        .zIndex(18)
                }

                ForEach(timedOccurrences) { occurrence in
                    let placement = placements[occurrence.id] ?? TimedTaskPlacement(id: occurrence.id, column: 0, columnCount: 1)
                    let gutter: CGFloat = 4
                    let availableWidth = max(proxy.size.width - gutter * 2, 44)
                    let columnWidth = availableWidth * placement.widthFraction
                    let x = gutter + availableWidth * placement.xFraction

                    InteractiveCalendarTaskBlock(
                        occurrence: occurrence,
                        width: max(columnWidth - gutter, 36),
                        height: max(blockHeight(for: occurrence) - 3, 26),
                        hourHeight: hourHeight,
                        dayWidth: proxy.size.width,
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
        .background(dayBackground(for: day))
        .onDrop(
            of: [.plainText],
            delegate: CalendarTaskTimelineDropDelegate(
                day: day,
                hourHeight: hourHeight,
                preview: $dropPreview,
                onScheduleTaskID: onScheduleExistingTask
            )
        )
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.20))
                .frame(width: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onCreateTaskSchedule(.allDay(on: day))
        }
        .onTapGesture {
            selectedDate = day
        }
    }

    private func allDayCell(for day: Date) -> some View {
        let allDayTasks = occurrencesFor(day: day).filter(\.isAllDay)

        return VStack(spacing: 4) {
            if allDayTasks.isEmpty {
                Spacer(minLength: 0)
            } else {
                ForEach(allDayTasks.prefix(2)) { occurrence in
                    CalendarTaskChip(occurrence: occurrence, compact: true, menuActions: makeTaskMenuActions(occurrence))
                        .contentShape(RoundedRectangle(cornerRadius: CalRemControlStyle.calendarCellRadius, style: .continuous))
                        .onTapGesture {
                            onEditTask(occurrence)
                        }
                }
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 42, maxHeight: 92, alignment: .top)
        .background(dayBackground(for: day))
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.16))
                .frame(width: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedDate = day
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

    private func occurrencesFor(day: Date) -> [CalendarTaskOccurrence] {
        CalendarRecurrenceService.occurrences(for: tasks, on: day, calendar: calendarService.calendar)
    }

    private var weekDays: [Date] {
        visibleDays ?? calendarService.week(containing: selectedDate)
    }

    private var activePreview: CalendarTaskDraftSchedule? {
        creationPreview ?? dropPreview
    }

    private func dayBackground(for day: Date) -> Color {
        calendarService.calendar.isDate(day, inSameDayAs: selectedDate)
            ? Color.accentColor.opacity(0.055)
            : Color(nsColor: .textBackgroundColor)
    }

    private func blockOffset(for occurrence: CalendarTaskOccurrence) -> CGFloat {
        guard let start = occurrence.calendarStart else { return 0 }
        return CGFloat(calendarService.minutesFromStartOfDay(for: start)) / 60 * hourHeight
    }

    private func blockHeight(for occurrence: CalendarTaskOccurrence) -> CGFloat {
        max(CGFloat(occurrence.duration / 3600) * hourHeight, 28)
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

    private func createTaskTapGesture(on day: Date) -> some Gesture {
        SpatialTapGesture(count: 2)
            .onEnded { value in
                let range = CalendarInteractionService.newTaskRange(
                    on: day,
                    locationY: value.location.y,
                    hourHeight: hourHeight
                )
                selectedDate = day
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
                selectedDate = day
                creationPreview = .timed(start: range.start, end: range.end)
            }
            .onEnded { value in
                let range = CalendarInteractionService.newTaskRange(
                    on: day,
                    startY: value.startLocation.y,
                    currentY: value.location.y,
                    hourHeight: hourHeight
                )
                selectedDate = day
                creationPreview = nil
                onCreateTaskSchedule(.timed(start: range.start, end: range.end))
            }
    }

    private func previewOffset(for preview: CalendarTaskDraftSchedule) -> CGFloat {
        CGFloat(calendarService.minutesFromStartOfDay(for: preview.start)) / 60 * hourHeight
    }

    private func previewHeight(for preview: CalendarTaskDraftSchedule) -> CGFloat {
        guard let end = preview.end else { return 28 }
        return max(CGFloat(end.timeIntervalSince(preview.start) / 3600) * hourHeight, 28)
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
        "week-hour-\(hour)"
    }
}

private struct WeekDayHeaderCell: View {
    let day: Date
    let isToday: Bool
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(day.formatted(.dateTime.weekday(.abbreviated)))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(day.formatted(.dateTime.day()))
                .font(.headline.weight(isToday || isSelected ? .bold : .semibold))
                .frame(width: 31, height: 28)
                .background(dayBadgeBackground, in: Capsule())
                .foregroundStyle(isSelected || isToday ? Color.white : Color.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }

    private var dayBadgeBackground: Color {
        if isToday {
            return .red
        }

        if isSelected {
            return .accentColor
        }

        return .clear
    }
}
