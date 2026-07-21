import SwiftUI

struct PlannerCalendarView: View {
    let tasks: [TaskItem]
    @Binding var selectedDate: Date
    @Binding var mode: CalendarMode
    let onEditTask: (TaskItem) -> Void
    let onUpdateTaskSchedule: (TaskItem, Date, Date) -> Void
    let onCreateTaskSchedule: (CalendarTaskDraftSchedule) -> Void
    let onScheduleExistingTask: (UUID, Date, Date) -> Void

    var body: some View {
        Group {
            switch mode {
            case .month:
                MonthCalendarView(
                    tasks: tasks,
                    selectedDate: $selectedDate,
                    onEditTask: onEditTask,
                    onCreateTaskSchedule: onCreateTaskSchedule
                )
            case .week:
                WeekCalendarView(
                    tasks: tasks,
                    selectedDate: $selectedDate,
                    onEditTask: onEditTask,
                    onUpdateTaskSchedule: onUpdateTaskSchedule,
                    onCreateTaskSchedule: onCreateTaskSchedule,
                    onScheduleExistingTask: onScheduleExistingTask
                )
            case .day:
                DayCalendarView(
                    tasks: tasks,
                    selectedDate: $selectedDate,
                    onEditTask: onEditTask,
                    onUpdateTaskSchedule: onUpdateTaskSchedule,
                    onCreateTaskSchedule: onCreateTaskSchedule,
                    onScheduleExistingTask: onScheduleExistingTask
                )
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
