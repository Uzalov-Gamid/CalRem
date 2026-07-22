import Foundation

enum CalendarMode: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case multiDay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .month:
            "Month"
        case .week:
            "Week"
        case .multiDay:
            "Multi-Day"
        case .day:
            "Day"
        }
    }

    var systemImage: String {
        switch self {
        case .month:
            "calendar"
        case .week:
            "rectangle.split.3x1"
        case .multiDay:
            "rectangle.split.3x1.fill"
        case .day:
            "rectangle"
        }
    }

    var shortcutHint: String {
        switch self {
        case .day:
            "Cmd-1"
        case .week:
            "Cmd-2"
        case .month:
            "Cmd-3"
        case .multiDay:
            "5 Days"
        }
    }
}
