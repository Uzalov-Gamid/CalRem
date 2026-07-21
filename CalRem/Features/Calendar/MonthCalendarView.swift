import SwiftUI

struct MonthCalendarView: View {
    let tasks: [TaskItem]
    @Binding var selectedDate: Date
    let onEditTask: (TaskItem) -> Void

    private let calendarService = CalendarDateService()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            weekdayHeader
            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(calendarService.monthGrid(containing: selectedDate), id: \.self) { day in
                    dayCell(day)
                }
            }
            .padding(12)
        }
    }

    private var weekdayHeader: some View {
        let days = calendarService.week(containing: selectedDate)
        return HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                Text(day.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private func dayCell(_ day: Date) -> some View {
        let dayTasks = tasks
            .filter { $0.occurs(on: day) }
            .sorted { ($0.calendarStart ?? .distantFuture) < ($1.calendarStart ?? .distantFuture) }
        let visible = Array(dayTasks.prefix(4))

        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(day.formatted(.dateTime.day()))
                    .font(.caption.weight(calendarService.isToday(day) ? .bold : .regular))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(
                        calendarService.isToday(day)
                            ? Color.accentColor.opacity(0.18)
                            : Color.clear,
                        in: Capsule()
                    )
                Spacer()
            }

            ForEach(visible) { task in
                CalendarTaskChip(task: task, compact: true)
                    .onTapGesture {
                        onEditTask(task)
                    }
            }

            if dayTasks.count > visible.count {
                Text("+\(dayTasks.count - visible.count) more")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(minHeight: 112, maxHeight: .infinity, alignment: .topLeading)
        .background(backgroundColor(for: day), in: RoundedRectangle(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor(for: day), lineWidth: calendarService.calendar.isDate(day, inSameDayAs: selectedDate) ? 1.5 : 1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedDate = day
        }
    }

    private func backgroundColor(for day: Date) -> Color {
        if calendarService.calendar.isDate(day, inSameDayAs: selectedDate) {
            return Color.accentColor.opacity(0.08)
        }

        if calendarService.isSameMonth(day, selectedDate) {
            return Color(nsColor: .controlBackgroundColor)
        }

        return Color(nsColor: .controlBackgroundColor).opacity(0.45)
    }

    private func borderColor(for day: Date) -> Color {
        if calendarService.calendar.isDate(day, inSameDayAs: selectedDate) {
            return .accentColor.opacity(0.55)
        }

        return Color(nsColor: .separatorColor).opacity(0.35)
    }
}
