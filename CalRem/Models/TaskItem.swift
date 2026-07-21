import Foundation
import SwiftData

enum TaskRecurrenceRule: String, CaseIterable, Identifiable {
    case none
    case daily
    case weekdays
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            "Never"
        case .daily:
            "Daily"
        case .weekdays:
            "Weekdays"
        case .weekly:
            "Weekly"
        case .monthly:
            "Monthly"
        case .yearly:
            "Yearly"
        }
    }

    var shortTitle: String {
        switch self {
        case .none:
            "No repeat"
        case .daily:
            "Daily"
        case .weekdays:
            "Weekdays"
        case .weekly:
            "Weekly"
        case .monthly:
            "Monthly"
        case .yearly:
            "Yearly"
        }
    }

    func nextDate(after date: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .none:
            nil
        case .daily:
            calendar.date(byAdding: .day, value: 1, to: date)
        case .weekdays:
            nextWeekday(after: date, calendar: calendar)
        case .weekly:
            calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly:
            calendar.date(byAdding: .month, value: 1, to: date)
        case .yearly:
            calendar.date(byAdding: .year, value: 1, to: date)
        }
    }

    private func nextWeekday(after date: Date, calendar: Calendar) -> Date? {
        var candidate = date

        for _ in 0..<7 {
            guard let next = calendar.date(byAdding: .day, value: 1, to: candidate) else {
                return nil
            }

            candidate = next
            if !calendar.isDateInWeekend(candidate) {
                return candidate
            }
        }

        return nil
    }
}

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
    var recurrenceRuleRawValue: String?
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
        recurrenceRule: TaskRecurrenceRule = .none,
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
        self.recurrenceRuleRawValue = recurrenceRule == .none ? nil : recurrenceRule.rawValue
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

    var recurrenceRule: TaskRecurrenceRule {
        get {
            guard let recurrenceRuleRawValue else { return .none }
            return TaskRecurrenceRule(rawValue: recurrenceRuleRawValue) ?? .none
        }
        set {
            recurrenceRuleRawValue = newValue == .none ? nil : newValue.rawValue
            touch()
        }
    }

    var isRepeating: Bool {
        recurrenceRule != .none
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

    func nextRecurringInstance(calendar: Calendar = .current) -> TaskItem? {
        let rule = recurrenceRule
        guard rule != .none, let currentStart = calendarStart, let nextStart = rule.nextDate(after: currentStart, calendar: calendar) else {
            return nil
        }

        let timeDelta = nextStart.timeIntervalSince(currentStart)
        let nextTask = TaskItem(
            title: title,
            notes: notes,
            list: list,
            dueDate: dueDate.map { $0.addingTimeInterval(timeDelta) },
            startDate: startDate.map { $0.addingTimeInterval(timeDelta) },
            endDate: endDate.map { $0.addingTimeInterval(timeDelta) },
            isAllDay: isAllDay,
            reminderDate: reminderDate.map { $0.addingTimeInterval(timeDelta) },
            priority: priority,
            recurrenceRule: rule
        )
        nextTask.notificationIdentifier = nextTask.reminderDate == nil ? nil : nextTask.notificationID
        return nextTask
    }

    func touch() {
        updatedAt = .now
    }
}
