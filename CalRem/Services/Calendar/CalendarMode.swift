import Foundation

enum CalendarMode: String, CaseIterable, Identifiable {
    case month
    case week
    case day

    var id: String { rawValue }

    var title: String {
        switch self {
        case .month:
            "Month"
        case .week:
            "Week"
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
        case .day:
            "rectangle"
        }
    }
}
