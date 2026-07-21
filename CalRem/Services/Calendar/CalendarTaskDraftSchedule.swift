import Foundation

struct CalendarTaskDraftSchedule: Equatable {
    let start: Date
    let end: Date?
    let isAllDay: Bool

    static func timed(start: Date, end: Date) -> CalendarTaskDraftSchedule {
        CalendarTaskDraftSchedule(start: start, end: end, isAllDay: false)
    }

    static func allDay(on day: Date, calendar: Calendar = .current) -> CalendarTaskDraftSchedule {
        CalendarTaskDraftSchedule(
            start: calendar.startOfDay(for: day),
            end: nil,
            isAllDay: true
        )
    }
}
