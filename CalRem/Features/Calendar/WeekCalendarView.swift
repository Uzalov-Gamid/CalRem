import SwiftUI

struct WeekCalendarView: View {
    let tasks: [TaskItem]
    @Binding var selectedDate: Date
    let onEditTask: (TaskItem) -> Void

    private let calendarService = CalendarDateService()
    private let hourHeight: CGFloat = 54

    var body: some View {
        VStack(spacing: 0) {
            weekHeader
            allDayRow
            Divider()

            ScrollView {
                HStack(alignment: .top, spacing: 0) {
                    hourLabels
                    ForEach(calendarService.week(containing: selectedDate), id: \.self) { day in
                        dayTimeline(day)
                    }
                }
                .padding(.trailing, 12)
            }
        }
    }

    private var weekHeader: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 52)
            ForEach(calendarService.week(containing: selectedDate), id: \.self) { day in
                VStack(spacing: 3) {
                    Text(day.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(day.formatted(.dateTime.day()))
                        .font(.headline.weight(calendarService.isToday(day) ? .bold : .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            calendarService.isToday(day) ? Color.accentColor.opacity(0.18) : Color.clear,
                            in: Capsule()
                        )
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedDate = day
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var allDayRow: some View {
        HStack(alignment: .top, spacing: 0) {
            Text("all-day")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .trailing)
                .padding(.top, 7)
                .padding(.trailing, 8)

            ForEach(calendarService.week(containing: selectedDate), id: \.self) { day in
                VStack(spacing: 4) {
                    let allDayTasks = tasksFor(day: day).filter(\.isAllDay)
                    if allDayTasks.isEmpty {
                        Color.clear.frame(height: 28)
                    } else {
                        ForEach(allDayTasks.prefix(2)) { task in
                            CalendarTaskChip(task: task, compact: true)
                                .onTapGesture {
                                    onEditTask(task)
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 34, alignment: .top)
                .padding(.horizontal, 4)
            }
        }
        .padding(.bottom, 6)
    }

    private var hourLabels: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                Text("\(hour):00")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: hourHeight, alignment: .topTrailing)
                    .padding(.trailing, 8)
            }
        }
    }

    private func dayTimeline(_ day: Date) -> some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { _ in
                    Rectangle()
                        .fill(Color(nsColor: .separatorColor).opacity(0.28))
                        .frame(height: 1)
                    Color.clear.frame(height: hourHeight - 1)
                }
            }

            if calendarService.isToday(day) {
                currentTimeLine
            }

            ForEach(tasksFor(day: day).filter(\.isTimed)) { task in
                CalendarTaskBlock(task: task)
                    .frame(height: blockHeight(for: task))
                    .padding(.horizontal, 4)
                    .offset(y: blockOffset(for: task))
                    .onTapGesture {
                        onEditTask(task)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: hourHeight * 24)
        .background(calendarService.calendar.isDate(day, inSameDayAs: selectedDate) ? Color.accentColor.opacity(0.045) : Color.clear)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.35))
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

    private func tasksFor(day: Date) -> [TaskItem] {
        tasks
            .filter { $0.occurs(on: day) }
            .sorted { ($0.calendarStart ?? .distantFuture) < ($1.calendarStart ?? .distantFuture) }
    }

    private func blockOffset(for task: TaskItem) -> CGFloat {
        guard let start = task.calendarStart else { return 0 }
        return CGFloat(calendarService.minutesFromStartOfDay(for: start)) / 60 * hourHeight
    }

    private func blockHeight(for task: TaskItem) -> CGFloat {
        max(CGFloat(task.duration / 3600) * hourHeight, 28)
    }
}
