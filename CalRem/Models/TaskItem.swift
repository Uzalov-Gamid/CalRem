import Foundation
import SwiftData

@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String
    var isCompleted: Bool
    var completedAt: Date?
    var dueDate: Date?
    var startDate: Date?
    var endDate: Date?
    var isAllDay: Bool
    var reminderDate: Date?
    var notificationIdentifier: String?
    var priorityRawValue: Int
    var createdAt: Date
    var updatedAt: Date

    var list: TaskList?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        list: TaskList? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        dueDate: Date? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        isAllDay: Bool = false,
        reminderDate: Date? = nil,
        notificationIdentifier: String? = nil,
        priority: TaskPriority = .none,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.list = list
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.reminderDate = reminderDate
        self.notificationIdentifier = notificationIdentifier
        self.priorityRawValue = priority.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRawValue) ?? .none }
        set {
            priorityRawValue = newValue.rawValue
            touch()
        }
    }

    var calendarStart: Date? {
        if isAllDay {
            dueDate ?? startDate
        } else {
            startDate ?? dueDate
        }
    }

    var calendarEnd: Date? {
        guard !isAllDay else { return nil }
        guard let start = calendarStart else { return nil }
        if let endDate, endDate > start {
            return endDate
        }
        return Calendar.current.date(byAdding: .minute, value: 30, to: start)
    }

    var isScheduled: Bool {
        calendarStart != nil
    }

    var isTimed: Bool {
        !isAllDay && calendarStart != nil
    }

    var duration: TimeInterval {
        guard let start = calendarStart, let end = calendarEnd else {
            return 0
        }
        return max(end.timeIntervalSince(start), 30 * 60)
    }

    var notificationID: String {
        "calrem.task.\(id.uuidString)"
    }

    func occurs(on day: Date, calendar: Calendar = .current) -> Bool {
        guard let start = calendarStart else { return false }
        return calendar.isDate(start, inSameDayAs: day)
    }

    func toggleCompletion() {
        isCompleted.toggle()
        completedAt = isCompleted ? .now : nil
        touch()
    }

    func apply(schedule: TaskSchedule) {
        dueDate = schedule.dueDate
        startDate = schedule.startDate
        endDate = schedule.endDate
        isAllDay = schedule.isAllDay
        touch()
    }

    func touch() {
        updatedAt = .now
    }
}
