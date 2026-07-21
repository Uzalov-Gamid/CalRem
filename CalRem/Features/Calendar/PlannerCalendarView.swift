import SwiftUI

struct PlannerCalendarView: View {
    let tasks: [TaskItem]
    @Binding var selectedDate: Date
    @Binding var mode: CalendarMode
    let onEditTask: (TaskItem) -> Void
    let onUpdateTaskSchedule: (TaskItem, Date, Date) -> Void

    var body: some View {
        Group {
            switch mode {
            case .month:
                MonthCalendarView(
                    tasks: tasks,
                    selectedDate: $selectedDate,
                    onEditTask: onEditTask
                )
            case .week:
                WeekCalendarView(
                    tasks: tasks,
                    selectedDate: $selectedDate,
                    onEditTask: onEditTask,
                    onUpdateTaskSchedule: onUpdateTaskSchedule
                )
            case .day:
                DayCalendarView(
                    tasks: tasks,
                    selectedDate: $selectedDate,
                    onEditTask: onEditTask,
                    onUpdateTaskSchedule: onUpdateTaskSchedule
                )
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
