import SwiftUI

struct PlannerCalendarView: View {
    let tasks: [TaskItem]
    @Binding var selectedDate: Date
    @Binding var mode: CalendarMode
    let onEditTask: (CalendarTaskOccurrence) -> Void
    let onUpdateTaskSchedule: (CalendarTaskOccurrence, Date, Date) -> Void
    let onCreateTaskSchedule: (CalendarTaskDraftSchedule) -> Void
    let onScheduleExistingTask: (UUID, Date, Date) -> Void
    let makeTaskMenuActions: (CalendarTaskOccurrence) -> CalendarTaskMenuActions

    var body: some View {
        Group {
            switch mode {
            case .month:
                MonthCalendarView(
                    tasks: tasks,
                    selectedDate: $selectedDate,
                    onEditTask: onEditTask,
                    onCreateTaskSchedule: onCreateTaskSchedule,
                    makeTaskMenuActions: makeTaskMenuActions
                )
            case .week:
                WeekCalendarView(
                    tasks: tasks,
                    selectedDate: $selectedDate,
                    onEditTask: onEditTask,
                    onUpdateTaskSchedule: onUpdateTaskSchedule,
                    onCreateTaskSchedule: onCreateTaskSchedule,
                    onScheduleExistingTask: onScheduleExistingTask,
                    makeTaskMenuActions: makeTaskMenuActions
                )
            case .multiDay:
                WeekCalendarView(
                    tasks: tasks,
                    visibleDays: CalendarDateService().multiDay(containing: selectedDate),
                    selectedDate: $selectedDate,
                    onEditTask: onEditTask,
                    onUpdateTaskSchedule: onUpdateTaskSchedule,
                    onCreateTaskSchedule: onCreateTaskSchedule,
                    onScheduleExistingTask: onScheduleExistingTask,
                    makeTaskMenuActions: makeTaskMenuActions
                )
            case .day:
                DayCalendarView(
                    tasks: tasks,
                    selectedDate: $selectedDate,
                    onEditTask: onEditTask,
                    onUpdateTaskSchedule: onUpdateTaskSchedule,
                    onCreateTaskSchedule: onCreateTaskSchedule,
                    onScheduleExistingTask: onScheduleExistingTask,
                    makeTaskMenuActions: makeTaskMenuActions
                )
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
