import XCTest
@testable import CalRem

final class TaskScheduleValidatorTests: XCTestCase {
    func testUndatedTaskHasNoCalendarDates() {
        let schedule = TaskScheduleValidator.normalized(
            hasDate: false,
            date: .now,
            isAllDay: false,
            startTime: .now,
            endTime: .now
        )

        XCTAssertNil(schedule.dueDate)
        XCTAssertNil(schedule.startDate)
        XCTAssertNil(schedule.endDate)
        XCTAssertFalse(schedule.isAllDay)
    }

    func testAllDayTaskUsesStartOfDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: 14, minute: 30))!

        let schedule = TaskScheduleValidator.normalized(
            hasDate: true,
            date: date,
            isAllDay: true,
            startTime: date,
            endTime: date,
            calendar: calendar
        )

        XCTAssertEqual(schedule.dueDate, calendar.startOfDay(for: date))
        XCTAssertNil(schedule.startDate)
        XCTAssertNil(schedule.endDate)
        XCTAssertTrue(schedule.isAllDay)
    }

    func testTimedTaskGetsDefaultDurationWhenEndIsTooEarly() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: 9, minute: 0))!
        let start = calendar.date(from: DateComponents(year: 2020, month: 1, day: 1, hour: 10, minute: 0))!
        let end = calendar.date(from: DateComponents(year: 2020, month: 1, day: 1, hour: 9, minute: 0))!

        let schedule = TaskScheduleValidator.normalized(
            hasDate: true,
            date: date,
            isAllDay: false,
            startTime: start,
            endTime: end,
            calendar: calendar
        )

        XCTAssertEqual(schedule.endDate?.timeIntervalSince(schedule.startDate!), TaskScheduleValidator.defaultDuration)
    }

    func testWeekdayRecurrenceSkipsWeekend() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let friday = calendar.date(from: DateComponents(year: 2026, month: 7, day: 24, hour: 9, minute: 0))!

        let nextDate = TaskRecurrenceRule.weekdays.nextDate(after: friday, calendar: calendar)

        XCTAssertEqual(calendar.component(.weekday, from: nextDate!), 2)
        XCTAssertEqual(calendar.component(.day, from: nextDate!), 27)
    }

    func testNextRecurringInstancePreservesScheduleAndMetadata() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: 9, minute: 0))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: 10, minute: 30))!
        let reminder = calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: 8, minute: 45))!
        let list = TaskList(name: "Work")
        let task = TaskItem(
            title: "Daily planning",
            notes: "Keep the day tidy",
            list: list,
            dueDate: start,
            startDate: start,
            endDate: end,
            reminderDate: reminder,
            priority: .high,
            recurrenceRule: .daily
        )

        let nextTask = task.nextRecurringInstance(calendar: calendar)

        XCTAssertEqual(nextTask?.title, task.title)
        XCTAssertEqual(nextTask?.notes, task.notes)
        XCTAssertEqual(nextTask?.list?.id, list.id)
        XCTAssertEqual(nextTask?.priority, .high)
        XCTAssertEqual(nextTask?.recurrenceRule, .daily)
        XCTAssertFalse(nextTask?.isCompleted ?? true)
        XCTAssertEqual(nextTask?.startDate, calendar.date(byAdding: .day, value: 1, to: start))
        XCTAssertEqual(nextTask?.endDate, calendar.date(byAdding: .day, value: 1, to: end))
        XCTAssertEqual(nextTask?.reminderDate, calendar.date(byAdding: .day, value: 1, to: reminder))
        XCTAssertNotNil(nextTask?.notificationIdentifier)
    }
}
