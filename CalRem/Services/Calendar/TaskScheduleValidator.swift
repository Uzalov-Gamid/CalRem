import Foundation

struct TaskSchedule: Equatable {
    var dueDate: Date?
    var startDate: Date?
    var endDate: Date?
    var isAllDay: Bool
}

enum TaskScheduleValidator {
    static let defaultDuration: TimeInterval = 30 * 60
    static let minimumDuration: TimeInterval = 15 * 60

    static func normalized(
        hasDate: Bool,
        date: Date,
        isAllDay: Bool,
        startTime: Date,
        endTime: Date,
        calendar: Calendar = .current
    ) -> TaskSchedule {
        guard hasDate else {
            return TaskSchedule(dueDate: nil, startDate: nil, endDate: nil, isAllDay: false)
        }

        let dateService = CalendarDateService(calendar: calendar)

        if isAllDay {
            return TaskSchedule(
                dueDate: calendar.startOfDay(for: date),
                startDate: nil,
                endDate: nil,
                isAllDay: true
            )
        }

        let start = dateService.merge(date: date, time: startTime)
        var end = dateService.merge(date: date, time: endTime)

        if end.timeIntervalSince(start) < minimumDuration {
            end = start.addingTimeInterval(defaultDuration)
        }

        return TaskSchedule(
            dueDate: start,
            startDate: start,
            endDate: end,
            isAllDay: false
        )
    }
}
