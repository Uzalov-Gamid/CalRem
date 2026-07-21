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
}
