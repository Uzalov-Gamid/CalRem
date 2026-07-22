import XCTest
@testable import CalRem

final class CalendarRecurrenceServiceTests: XCTestCase {
    func testDailyTimedTaskAppearsOnFutureCalendarDays() {
        let calendar = calendar()
        let start = calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: 0, minute: 30))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: 8, minute: 30))!
        let task = TaskItem(
            title: "Sleep",
            dueDate: start,
            startDate: start,
            endDate: end,
            recurrenceRule: .daily
        )

        let targetDay = calendar.date(from: DateComponents(year: 2026, month: 7, day: 23))!
        let occurrences = CalendarRecurrenceService.occurrences(for: [task], on: targetDay, calendar: calendar)

        XCTAssertEqual(occurrences.count, 1)
        XCTAssertTrue(occurrences[0].isGenerated)
        XCTAssertEqual(occurrences[0].calendarStart, calendar.date(from: DateComponents(year: 2026, month: 7, day: 23, hour: 0, minute: 30)))
        XCTAssertEqual(occurrences[0].calendarEnd, calendar.date(from: DateComponents(year: 2026, month: 7, day: 23, hour: 8, minute: 30)))
    }

    func testWeekdayRecurrenceDoesNotRenderOnWeekend() {
        let calendar = calendar()
        let start = calendar.date(from: DateComponents(year: 2026, month: 7, day: 24, hour: 9, minute: 0))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 7, day: 24, hour: 9, minute: 30))!
        let task = TaskItem(
            title: "Standup",
            dueDate: start,
            startDate: start,
            endDate: end,
            recurrenceRule: .weekdays
        )
        let saturday = calendar.date(from: DateComponents(year: 2026, month: 7, day: 25))!
        let monday = calendar.date(from: DateComponents(year: 2026, month: 7, day: 27))!

        XCTAssertTrue(CalendarRecurrenceService.occurrences(for: [task], on: saturday, calendar: calendar).isEmpty)
        XCTAssertEqual(CalendarRecurrenceService.occurrences(for: [task], on: monday, calendar: calendar).count, 1)
    }

    func testWeeklyRecurrenceOnlyRendersMatchingFutureWeekday() {
        let calendar = calendar()
        let start = calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: 16, minute: 0))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: 17, minute: 0))!
        let task = TaskItem(
            title: "Review",
            dueDate: start,
            startDate: start,
            endDate: end,
            recurrenceRule: .weekly
        )
        let nextTuesday = calendar.date(from: DateComponents(year: 2026, month: 7, day: 28))!
        let nextWednesday = calendar.date(from: DateComponents(year: 2026, month: 7, day: 29))!

        XCTAssertEqual(CalendarRecurrenceService.occurrences(for: [task], on: nextTuesday, calendar: calendar).count, 1)
        XCTAssertTrue(CalendarRecurrenceService.occurrences(for: [task], on: nextWednesday, calendar: calendar).isEmpty)
    }

    func testCompletedRecurringTaskOnlyRendersItsCompletedBaseOccurrence() {
        let calendar = calendar()
        let start = calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: 0, minute: 30))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: 8, minute: 30))!
        let task = TaskItem(
            title: "Sleep",
            isCompleted: true,
            completedAt: start,
            dueDate: start,
            startDate: start,
            endDate: end,
            recurrenceRule: .daily
        )
        let nextDay = calendar.date(from: DateComponents(year: 2026, month: 7, day: 22))!

        XCTAssertEqual(CalendarRecurrenceService.occurrences(for: [task], on: start, calendar: calendar).count, 1)
        XCTAssertTrue(CalendarRecurrenceService.occurrences(for: [task], on: nextDay, calendar: calendar).isEmpty)
    }

    private func calendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
