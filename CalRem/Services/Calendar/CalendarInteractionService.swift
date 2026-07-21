import Foundation
import CoreGraphics

enum CalendarInteractionService {
    static let snapIntervalMinutes = 15
    static let minimumDurationMinutes = 15

    static func movedRange(
        start: Date,
        end: Date,
        translation: CGSize,
        hourHeight: CGFloat,
        dayWidth: CGFloat?,
        calendar: Calendar = .current
    ) -> (start: Date, end: Date) {
        let duration = durationMinutes(start: start, end: end)
        let minuteDelta = snappedMinuteDelta(for: translation.height, hourHeight: hourHeight)
        let dayDelta = snappedDayDelta(for: translation.width, dayWidth: dayWidth)

        var movedStart = calendar.date(byAdding: .minute, value: minuteDelta, to: start) ?? start
        movedStart = calendar.date(byAdding: .day, value: dayDelta, to: movedStart) ?? movedStart
        movedStart = snapped(date: movedStart, calendar: calendar)
        movedStart = clampedStart(movedStart, durationMinutes: duration, calendar: calendar)

        let movedEnd = calendar.date(byAdding: .minute, value: duration, to: movedStart) ?? end
        return (movedStart, movedEnd)
    }

    static func resizedRange(
        start: Date,
        end: Date,
        resizeDeltaY: CGFloat,
        hourHeight: CGFloat,
        calendar: Calendar = .current
    ) -> (start: Date, end: Date) {
        let minuteDelta = snappedMinuteDelta(for: resizeDeltaY, hourHeight: hourHeight)
        let rawEnd = calendar.date(byAdding: .minute, value: minuteDelta, to: end) ?? end
        let snappedEnd = snapped(date: rawEnd, calendar: calendar)

        let minimumEnd = calendar.date(byAdding: .minute, value: minimumDurationMinutes, to: start) ?? end
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: start)) ?? end
        let clampedEnd = min(max(snappedEnd, minimumEnd), dayEnd)

        return (start, clampedEnd)
    }

    static func newTaskRange(
        on day: Date,
        locationY: CGFloat,
        hourHeight: CGFloat,
        calendar: Calendar = .current
    ) -> (start: Date, end: Date) {
        guard hourHeight > 0 else {
            let start = calendar.startOfDay(for: day)
            let end = calendar.date(byAdding: .minute, value: minimumDurationMinutes, to: start) ?? start
            return (start, end)
        }

        let rawMinutes = max(0, Double(locationY / hourHeight) * 60)
        let snappedMinutes = Int((rawMinutes / Double(snapIntervalMinutes)).rounded()) * snapIntervalMinutes
        let latestStartMinute = (24 * 60) - minimumDurationMinutes
        let startMinute = min(max(snappedMinutes, 0), latestStartMinute)
        let dayStart = calendar.startOfDay(for: day)
        let start = calendar.date(byAdding: .minute, value: startMinute, to: dayStart) ?? dayStart
        let end = calendar.date(byAdding: .minute, value: minimumDurationMinutes, to: start) ?? start

        return (start, end)
    }

    static func newTaskRange(
        on day: Date,
        startY: CGFloat,
        currentY: CGFloat,
        hourHeight: CGFloat,
        calendar: Calendar = .current
    ) -> (start: Date, end: Date) {
        guard hourHeight > 0 else {
            return newTaskRange(on: day, locationY: startY, hourHeight: hourHeight, calendar: calendar)
        }

        let firstMinute = snappedMinute(for: startY, hourHeight: hourHeight)
        let secondMinute = snappedMinute(for: currentY, hourHeight: hourHeight)
        let lowerMinute = min(firstMinute, secondMinute)
        let upperMinute = max(firstMinute, secondMinute)
        let startMinute = min(max(lowerMinute, 0), (24 * 60) - minimumDurationMinutes)
        let minimumEndMinute = startMinute + minimumDurationMinutes
        let endMinute = min(max(upperMinute, minimumEndMinute), 24 * 60)
        let dayStart = calendar.startOfDay(for: day)
        let start = calendar.date(byAdding: .minute, value: startMinute, to: dayStart) ?? dayStart
        let end = calendar.date(byAdding: .minute, value: endMinute, to: dayStart)
            ?? calendar.date(byAdding: .minute, value: minimumDurationMinutes, to: start)
            ?? start

        return (start, end)
    }

    private static func durationMinutes(start: Date, end: Date) -> Int {
        max(Int(end.timeIntervalSince(start) / 60), minimumDurationMinutes)
    }

    private static func snappedMinuteDelta(for points: CGFloat, hourHeight: CGFloat) -> Int {
        guard hourHeight > 0 else { return 0 }
        let rawMinutes = Double(points / hourHeight) * 60
        let snappedSteps = (rawMinutes / Double(snapIntervalMinutes)).rounded()
        return Int(snappedSteps) * snapIntervalMinutes
    }

    private static func snappedMinute(for points: CGFloat, hourHeight: CGFloat) -> Int {
        guard hourHeight > 0 else { return 0 }
        let rawMinutes = max(0, Double(points / hourHeight) * 60)
        let snappedSteps = (rawMinutes / Double(snapIntervalMinutes)).rounded()
        return Int(snappedSteps) * snapIntervalMinutes
    }

    private static func snappedDayDelta(for points: CGFloat, dayWidth: CGFloat?) -> Int {
        guard let dayWidth, dayWidth > 0 else { return 0 }
        return Int((points / dayWidth).rounded())
    }

    private static func snapped(date: Date, calendar: Calendar) -> Date {
        let dayStart = calendar.startOfDay(for: date)
        let minutes = calendar.dateComponents([.minute], from: dayStart, to: date).minute ?? 0
        let snappedMinutes = Int((Double(minutes) / Double(snapIntervalMinutes)).rounded()) * snapIntervalMinutes
        return calendar.date(byAdding: .minute, value: snappedMinutes, to: dayStart) ?? date
    }

    private static func clampedStart(_ start: Date, durationMinutes: Int, calendar: Calendar) -> Date {
        let dayStart = calendar.startOfDay(for: start)
        let latestStart = calendar.date(
            byAdding: .minute,
            value: (24 * 60) - durationMinutes,
            to: dayStart
        ) ?? dayStart

        return min(max(start, dayStart), latestStart)
    }
}
