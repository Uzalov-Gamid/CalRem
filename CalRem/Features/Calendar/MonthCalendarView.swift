import SwiftUI

struct MonthCalendarView: View {
    let tasks: [TaskItem]
    @Binding var selectedDate: Date
    let onEditTask: (CalendarTaskOccurrence) -> Void
    let onCreateTaskSchedule: (CalendarTaskDraftSchedule) -> Void
    let makeTaskMenuActions: (CalendarTaskOccurrence) -> CalendarTaskMenuActions

    private let calendarService = CalendarDateService()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)

    var body: some View {
        GeometryReader { proxy in
            calendarGrid(availableHeight: proxy.size.height)
        }
        .background(Color(nsColor: .textBackgroundColor))
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

    private func calendarGrid(availableHeight: CGFloat) -> some View {
        let outerPadding: CGFloat = 12
        let headerHeight: CGFloat = 32
        let rowHeight = max((availableHeight - headerHeight - outerPadding * 2 - 5) / 6, 82)

        return VStack(spacing: 0) {
            weekdayHeader
                .frame(height: headerHeight)

            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(calendarService.monthGrid(containing: selectedDate), id: \.self) { day in
                    dayCell(day, height: rowHeight)
                }
            }
        }
        .padding(outerPadding)
    }

    private func dayCell(_ day: Date, height: CGFloat) -> some View {
        let dayTasks = CalendarRecurrenceService.occurrences(for: tasks, on: day, calendar: calendarService.calendar)
        let visible = Array(dayTasks.prefix(4))

        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(day.formatted(.dateTime.day()))
                    .font(.caption.weight(calendarService.isToday(day) || isSelected(day) ? .bold : .semibold))
                    .frame(minWidth: 26, minHeight: 24)
                    .background(dayBadgeBackground(for: day), in: Capsule())
                    .foregroundStyle(isSelected(day) || calendarService.isToday(day) ? Color.white : dayTextColor(for: day))
                Spacer()
            }

            ForEach(visible) { occurrence in
                CalendarTaskChip(occurrence: occurrence, compact: true, menuActions: makeTaskMenuActions(occurrence))
                    .onTapGesture {
                        onEditTask(occurrence)
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
        .frame(height: height, alignment: .topLeading)
        .background(backgroundColor(for: day), in: RoundedRectangle(cornerRadius: CalRemControlStyle.calendarCellRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CalRemControlStyle.calendarCellRadius, style: .continuous)
                .stroke(borderColor(for: day), lineWidth: isSelected(day) ? 1.4 : 1)
        }
        .contentShape(Rectangle())
        .gesture(
            TapGesture(count: 2)
                .onEnded {
                    selectedDate = day
                    onCreateTaskSchedule(.allDay(on: day))
                }
        )
        .onTapGesture {
            selectedDate = day
        }
    }

    private func backgroundColor(for day: Date) -> Color {
        if isSelected(day) {
            return Color.accentColor.opacity(0.075)
        }

        if calendarService.isSameMonth(day, selectedDate) {
            return Color(nsColor: .textBackgroundColor)
        }

        return Color(nsColor: .controlBackgroundColor).opacity(0.38)
    }

    private func borderColor(for day: Date) -> Color {
        if isSelected(day) {
            return .accentColor.opacity(0.65)
        }

        return Color(nsColor: .separatorColor).opacity(0.24)
    }

    private func dayBadgeBackground(for day: Date) -> Color {
        if calendarService.isToday(day) {
            return .red
        }

        if isSelected(day) {
            return .accentColor
        }

        return .clear
    }

    private func dayTextColor(for day: Date) -> Color {
        calendarService.isSameMonth(day, selectedDate) ? .primary : .secondary
    }

    private func isSelected(_ day: Date) -> Bool {
        calendarService.calendar.isDate(day, inSameDayAs: selectedDate)
    }
}
