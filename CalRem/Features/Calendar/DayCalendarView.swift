import SwiftUI

struct DayCalendarView: View {
    let tasks: [TaskItem]
    @Binding var selectedDate: Date
    let onEditTask: (TaskItem) -> Void

    private let calendarService = CalendarDateService()
    private let hourHeight: CGFloat = 60

    var body: some View {
        VStack(spacing: 0) {
            allDaySection
            Divider()

            ScrollView {
                HStack(alignment: .top, spacing: 0) {
                    hourLabels
                    timeline
                }
                .padding(.trailing, 20)
            }
        }
    }

    private var allDaySection: some View {
        let allDayTasks = dayTasks.filter(\.isAllDay)

        return HStack(alignment: .top, spacing: 10) {
            Text("all-day")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .trailing)
                .padding(.top, 14)

            if allDayTasks.isEmpty {
                Text("No all-day tasks")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 14)
            } else {
                VStack(spacing: 5) {
                    ForEach(allDayTasks) { task in
                        CalendarTaskChip(task: task)
                            .onTapGesture {
                                onEditTask(task)
                            }
                    }
                }
                .padding(.vertical, 10)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 52)
    }

    private var hourLabels: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                Text("\(hour):00")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 52, height: hourHeight, alignment: .topTrailing)
                    .padding(.trailing, 8)
            }
        }
    }

    private var timeline: some View {
        let timedTasks = dayTasks.filter(\.isTimed)
        let placements = layoutPlacements(for: timedTasks)

        return ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { _ in
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor).opacity(0.28))
                        .frame(height: 1)
                    Color.clear.frame(height: hourHeight - 1)
                }
            }

            if calendarService.isToday(selectedDate) {
                currentTimeLine
            }

            GeometryReader { proxy in
                ForEach(timedTasks) { task in
                    let placement = placements[task.id] ?? TimedTaskPlacement(id: task.id, column: 0, columnCount: 1)
                    let gutter: CGFloat = 8
                    let availableWidth = max(proxy.size.width - gutter * 2, 80)
                    let columnWidth = availableWidth * placement.widthFraction
                    let x = gutter + availableWidth * placement.xFraction

                    CalendarTaskBlock(task: task)
                        .frame(width: max(columnWidth - gutter, 52), height: blockHeight(for: task))
                        .offset(x: x, y: blockOffset(for: task))
                        .onTapGesture {
                            onEditTask(task)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: hourHeight * 24)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }

    private var currentTimeLine: some View {
        let minutes = calendarService.minutesFromStartOfDay(for: .now)
        let y = CGFloat(minutes) / 60 * hourHeight

        return Rectangle()
            .fill(Color.red.opacity(0.75))
            .frame(height: 1)
            .offset(y: y)
    }

    private var dayTasks: [TaskItem] {
        tasks
            .filter { $0.occurs(on: selectedDate) }
            .sorted { ($0.calendarStart ?? .distantFuture) < ($1.calendarStart ?? .distantFuture) }
    }

    private func blockOffset(for task: TaskItem) -> CGFloat {
        guard let start = task.calendarStart else { return 0 }
        return CGFloat(calendarService.minutesFromStartOfDay(for: start)) / 60 * hourHeight
    }

    private func blockHeight(for task: TaskItem) -> CGFloat {
        max(CGFloat(task.duration / 3600) * hourHeight, 32)
    }

    private func layoutPlacements(for tasks: [TaskItem]) -> [UUID: TimedTaskPlacement] {
        let inputs = tasks.compactMap { task -> TimedTaskLayoutInput? in
            guard let start = task.calendarStart, let end = task.calendarEnd else {
                return nil
            }
            return TimedTaskLayoutInput(id: task.id, startDate: start, endDate: end)
        }

        return CalendarTaskLayoutService.placements(for: inputs)
    }
}
