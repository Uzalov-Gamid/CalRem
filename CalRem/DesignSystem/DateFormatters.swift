import Foundation

enum DateFormatters {
    static func date(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    static func time(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute())
    }

    static func dateTime(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }

    static func taskSchedule(_ task: TaskItem) -> String {
        guard let start = task.calendarStart else {
            return "No date"
        }

        if task.isAllDay {
            return date(start)
        }

        guard let end = task.calendarEnd else {
            return dateTime(start)
        }

        if Calendar.current.isDate(start, inSameDayAs: end) {
            return "\(date(start)), \(time(start)) - \(time(end))"
        }

        return "\(dateTime(start)) - \(dateTime(end))"
    }
}
