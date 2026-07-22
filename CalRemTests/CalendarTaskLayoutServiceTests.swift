import XCTest
@testable import CalRem

final class CalendarTaskLayoutServiceTests: XCTestCase {
    func testNonOverlappingTasksShareSingleColumn() {
        let calendar = calendar()
        let first = "first"
        let second = "second"

        let placements = CalendarTaskLayoutService.placements(for: [
            input(first, 9, 0, 10, 0, calendar),
            input(second, 10, 0, 11, 0, calendar)
        ])

        XCTAssertEqual(placements[first]?.column, 0)
        XCTAssertEqual(placements[first]?.columnCount, 1)
        XCTAssertEqual(placements[second]?.column, 0)
        XCTAssertEqual(placements[second]?.columnCount, 1)
    }

    func testFullyOverlappingTasksUseSeparateColumns() {
        let calendar = calendar()
        let first = "first"
        let second = "second"

        let placements = CalendarTaskLayoutService.placements(for: [
            input(first, 9, 0, 10, 0, calendar),
            input(second, 9, 30, 10, 30, calendar)
        ])

        XCTAssertEqual(placements[first]?.columnCount, 2)
        XCTAssertEqual(placements[second]?.columnCount, 2)
        XCTAssertNotEqual(placements[first]?.column, placements[second]?.column)
    }

    func testPartiallyOverlappingClusterKeepsStableColumnCount() {
        let calendar = calendar()
        let first = "first"
        let second = "second"
        let third = "third"

        let placements = CalendarTaskLayoutService.placements(for: [
            input(first, 9, 0, 10, 0, calendar),
            input(second, 9, 30, 10, 30, calendar),
            input(third, 10, 0, 11, 0, calendar)
        ])

        XCTAssertEqual(placements[first]?.columnCount, 2)
        XCTAssertEqual(placements[second]?.columnCount, 2)
        XCTAssertEqual(placements[third]?.columnCount, 2)
        XCTAssertEqual(placements[third]?.column, 0)
    }

    private func calendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func input(
        _ id: String,
        _ startHour: Int,
        _ startMinute: Int,
        _ endHour: Int,
        _ endMinute: Int,
        _ calendar: Calendar
    ) -> TimedTaskLayoutInput {
        let start = calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: startHour, minute: startMinute))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: endHour, minute: endMinute))!
        return TimedTaskLayoutInput(id: id, startDate: start, endDate: end)
    }
}
