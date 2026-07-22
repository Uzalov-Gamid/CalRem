import Foundation

struct CalendarDateService {
    var calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    func monthGrid(containing date: Date) -> [Date] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: date),
            let firstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start)
        else {
            return []
        }

        var days: [Date] = []
        var current = firstWeek.start

        while days.count < 42 {
            days.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else {
                break
            }
            current = next
        }

        return days
    }

    func week(containing date: Date) -> [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return []
        }

        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekInterval.start)
        }
    }

    func multiDay(containing date: Date, count: Int = 5) -> [Date] {
        let start = calendar.startOfDay(for: date)
        return (0..<count).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
    }

    func nextDate(from date: Date, mode: CalendarMode) -> Date {
        switch mode {
        case .month:
            calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .week:
            calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .multiDay:
            calendar.date(byAdding: .day, value: 5, to: date) ?? date
        case .day:
            calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
    }

    func previousDate(from date: Date, mode: CalendarMode) -> Date {
        switch mode {
        case .month:
            calendar.date(byAdding: .month, value: -1, to: date) ?? date
        case .week:
            calendar.date(byAdding: .weekOfYear, value: -1, to: date) ?? date
        case .multiDay:
            calendar.date(byAdding: .day, value: -5, to: date) ?? date
        case .day:
            calendar.date(byAdding: .day, value: -1, to: date) ?? date
        }
    }

    func title(for date: Date, mode: CalendarMode) -> String {
        switch mode {
        case .month:
            return date.formatted(.dateTime.month(.wide).year())
        case .week:
            let days = week(containing: date)
            guard let first = days.first, let last = days.last else {
                return date.formatted(.dateTime.month(.wide).year())
            }
            return "\(first.formatted(.dateTime.month(.abbreviated).day())) - \(last.formatted(.dateTime.month(.abbreviated).day().year()))"
        case .multiDay:
            let days = multiDay(containing: date)
            guard let first = days.first, let last = days.last else {
                return date.formatted(.dateTime.month(.wide).year())
            }
            return "\(first.formatted(.dateTime.month(.abbreviated).day())) - \(last.formatted(.dateTime.month(.abbreviated).day().year()))"
        case .day:
            return date.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
        }
    }

    func minutesFromStartOfDay(for date: Date) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    func merge(date: Date, time: Date) -> Date {
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var merged = DateComponents()
        merged.year = dateComponents.year
        merged.month = dateComponents.month
        merged.day = dateComponents.day
        merged.hour = timeComponents.hour
        merged.minute = timeComponents.minute
        return calendar.date(from: merged) ?? date
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    func isSameMonth(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, equalTo: rhs, toGranularity: .month)
    }
}
