import Foundation

struct CalendarTaskOccurrence: Identifiable {
    let id: String
    let task: TaskItem
    let startDate: Date?
    let endDate: Date?
    let isAllDay: Bool
    let isGenerated: Bool

    init(
        task: TaskItem,
        startDate: Date?,
        endDate: Date?,
        isAllDay: Bool,
        isGenerated: Bool
    ) {
        self.task = task
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.isGenerated = isGenerated

        let occurrenceKey = startDate?.timeIntervalSinceReferenceDate
            ?? task.calendarStart?.timeIntervalSinceReferenceDate
            ?? task.createdAt.timeIntervalSinceReferenceDate
        self.id = "\(task.id.uuidString)-\(Int(occurrenceKey))"
    }

    init?(task: TaskItem) {
        guard task.isScheduled else { return nil }
        self.init(
            task: task,
            startDate: task.calendarStart,
            endDate: task.calendarEnd,
            isAllDay: task.isAllDay,
            isGenerated: false
        )
    }

    var title: String {
        task.title
    }

    var notes: String {
        task.notes
    }

    var isCompleted: Bool {
        task.isCompleted
    }

    var isRepeating: Bool {
        task.isRepeating
    }

    var recurrenceRule: TaskRecurrenceRule {
        task.recurrenceRule
    }

    var list: TaskList? {
        task.list
    }

    var calendarStart: Date? {
        startDate
    }

    var calendarEnd: Date? {
        guard !isAllDay else { return nil }
        guard let startDate else { return nil }
        if let endDate, endDate > startDate {
            return endDate
        }
        return Calendar.current.date(byAdding: .minute, value: 30, to: startDate)
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
        return max(end.timeIntervalSince(start), TaskScheduleValidator.minimumDuration)
    }

    var reminderDate: Date? {
        guard isGenerated,
              let reminderDate = task.reminderDate,
              let taskStart = task.calendarStart,
              let startDate else {
            return task.reminderDate
        }

        return reminderDate.addingTimeInterval(startDate.timeIntervalSince(taskStart))
    }
}

enum CalendarRecurrenceService {
    static func occurrences(
        for tasks: [TaskItem],
        on day: Date,
        calendar: Calendar = .current
    ) -> [CalendarTaskOccurrence] {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(24 * 60 * 60)
        return occurrences(for: tasks, from: start, to: end, calendar: calendar)
    }

    static func occurrences(
        for tasks: [TaskItem],
        from rangeStart: Date,
        to rangeEnd: Date,
        calendar: Calendar = .current
    ) -> [CalendarTaskOccurrence] {
        guard rangeStart < rangeEnd else { return [] }

        return tasks.flatMap { task in
            occurrences(for: task, from: rangeStart, to: rangeEnd, calendar: calendar)
        }
        .sorted { lhs, rhs in
            (lhs.calendarStart ?? .distantFuture) < (rhs.calendarStart ?? .distantFuture)
        }
    }

    static func occurrences(
        for task: TaskItem,
        from rangeStart: Date,
        to rangeEnd: Date,
        calendar: Calendar = .current
    ) -> [CalendarTaskOccurrence] {
        guard let taskStart = task.calendarStart else { return [] }

        if !task.isRepeating {
            guard taskStart >= rangeStart && taskStart < rangeEnd,
                  let occurrence = CalendarTaskOccurrence(task: task) else {
                return []
            }
            return [occurrence]
        }

        guard taskStart < rangeEnd else { return [] }

        let rule = task.recurrenceRule
        var occurrenceStart = taskStart
        var occurrences: [CalendarTaskOccurrence] = []
        var guardCount = 0

        while occurrenceStart < rangeEnd && guardCount < 10_000 {
            if occurrenceStart >= rangeStart,
               let occurrence = occurrence(for: task, start: occurrenceStart, originalStart: taskStart) {
                occurrences.append(occurrence)
            }

            guard let next = rule.nextDate(after: occurrenceStart, calendar: calendar),
                  next > occurrenceStart else {
                break
            }

            occurrenceStart = next
            guardCount += 1
        }

        return occurrences
    }

    private static func occurrence(
        for task: TaskItem,
        start occurrenceStart: Date,
        originalStart: Date
    ) -> CalendarTaskOccurrence? {
        let delta = occurrenceStart.timeIntervalSince(originalStart)
        let endDate = task.calendarEnd?.addingTimeInterval(delta)
        let isGenerated = occurrenceStart != originalStart

        return CalendarTaskOccurrence(
            task: task,
            startDate: occurrenceStart,
            endDate: endDate,
            isAllDay: task.isAllDay,
            isGenerated: isGenerated
        )
    }
}
