import SwiftUI

enum ListColor: String, CaseIterable, Identifiable {
    case blue
    case green
    case indigo
    case mint
    case orange
    case pink
    case purple
    case red
    case teal
    case yellow

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .blue:
            .blue
        case .green:
            .green
        case .indigo:
            .indigo
        case .mint:
            .mint
        case .orange:
            .orange
        case .pink:
            .pink
        case .purple:
            .purple
        case .red:
            .red
        case .teal:
            .teal
        case .yellow:
            .yellow
        }
    }

    static func named(_ name: String?) -> ListColor {
        guard let name, let color = ListColor(rawValue: name) else {
            return .blue
        }
        return color
    }
}
