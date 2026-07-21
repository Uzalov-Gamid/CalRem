import XCTest
@testable import CalRem

final class CalendarDateServiceTests: XCTestCase {
    func testMonthGridAlwaysReturnsSixWeeks() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let service = CalendarDateService(calendar: calendar)
        let date = date(year: 2026, month: 7, day: 21, calendar: calendar)

        XCTAssertEqual(service.monthGrid(containing: date).count, 42)
    }

    func testWeekReturnsSevenDays() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let service = CalendarDateService(calendar: calendar)
        let date = date(year: 2026, month: 7, day: 21, calendar: calendar)

        XCTAssertEqual(service.week(containing: date).count, 7)
    }

    func testMergeKeepsDateAndUsesTime() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let service = CalendarDateService(calendar: calendar)
        let baseDate = date(year: 2026, month: 7, day: 21, hour: 9, minute: 0, calendar: calendar)
        let time = date(year: 2001, month: 1, day: 1, hour: 14, minute: 45, calendar: calendar)

        let merged = service.merge(date: baseDate, time: time)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: merged)

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 7)
        XCTAssertEqual(components.day, 21)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 45)
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        minute: Int = 0,
        calendar: Calendar
    ) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
