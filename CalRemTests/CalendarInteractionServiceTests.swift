import Testing
import Foundation
@testable import CalRem

struct CalendarInteractionServiceTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test func testMoveSnapsToFifteenMinutes() throws {
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: 9)))
        let end = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: 10)))

        let result = CalendarInteractionService.movedRange(
            start: start,
            end: end,
            translation: CGSize(width: 0, height: 19),
            hourHeight: 64,
            dayWidth: nil,
            calendar: calendar
        )

        #expect(calendar.component(.hour, from: result.start) == 9)
        #expect(calendar.component(.minute, from: result.start) == 15)
        #expect(result.end.timeIntervalSince(result.start) == 60 * 60)
    }

    @Test func testWeekMoveCanShiftDays() throws {
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: 9)))
        let end = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: 10)))

        let result = CalendarInteractionService.movedRange(
            start: start,
            end: end,
            translation: CGSize(width: 130, height: 0),
            hourHeight: 64,
            dayWidth: 100,
            calendar: calendar
        )

        #expect(calendar.component(.day, from: result.start) == 22)
        #expect(calendar.component(.hour, from: result.start) == 9)
    }

    @Test func testResizeKeepsMinimumDuration() throws {
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: 9)))
        let end = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: 10)))

        let result = CalendarInteractionService.resizedRange(
            start: start,
            end: end,
            resizeDeltaY: -200,
            hourHeight: 64,
            calendar: calendar
        )

        #expect(result.end.timeIntervalSince(result.start) == 15 * 60)
    }

    @Test func testNewTaskRangeUsesClickedTimeAndMinimumDuration() throws {
        let day = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 21)))

        let result = CalendarInteractionService.newTaskRange(
            on: day,
            locationY: 4.5 * 64,
            hourHeight: 64,
            calendar: calendar
        )

        #expect(calendar.component(.hour, from: result.start) == 4)
        #expect(calendar.component(.minute, from: result.start) == 30)
        #expect(result.end.timeIntervalSince(result.start) == 15 * 60)
    }

    @Test func testNewTaskRangeClampsNearEndOfDay() throws {
        let day = try #require(calendar.date(from: DateComponents(year: 2026, month: 7, day: 21)))

        let result = CalendarInteractionService.newTaskRange(
            on: day,
            locationY: 25 * 64,
            hourHeight: 64,
            calendar: calendar
        )

        #expect(calendar.component(.hour, from: result.start) == 23)
        #expect(calendar.component(.minute, from: result.start) == 45)
        #expect(result.end == calendar.date(byAdding: .day, value: 1, to: day))
    }
}
