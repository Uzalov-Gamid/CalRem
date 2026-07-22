import SwiftUI

enum CalRemControlStyle {
    static let minimumHitSize: CGFloat = 32
    static let compactHitSize: CGFloat = 28
    static let toolbarRadius: CGFloat = 8
    static let rowRadius: CGFloat = 7
    static let sidebarCardRadius: CGFloat = 12
    static let sidebarInset: CGFloat = 14
    static let calendarCellRadius: CGFloat = 6
    static let calendarTimeColumnWidth: CGFloat = 64
    static let calendarHourHeight: CGFloat = 64
}

struct CalRemIconButtonStyle: ButtonStyle {
    var size: CGFloat = CalRemControlStyle.minimumHitSize

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .frame(width: size, height: size)
            .background(
                configuration.isPressed
                    ? Color.accentColor.opacity(0.18)
                    : Color(nsColor: .controlBackgroundColor).opacity(0.62),
                in: RoundedRectangle(cornerRadius: CalRemControlStyle.toolbarRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: CalRemControlStyle.toolbarRadius, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.24), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: CalRemControlStyle.toolbarRadius, style: .continuous))
    }
}

struct CalRemPillButtonStyle: ButtonStyle {
    var isProminent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(isProminent ? .semibold : .regular))
            .padding(.horizontal, 13)
            .frame(minHeight: CalRemControlStyle.minimumHitSize)
            .background(backgroundColor(isPressed: configuration.isPressed), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(borderColor, lineWidth: isProminent ? 0 : 1)
            }
            .foregroundStyle(isProminent ? Color.white : Color.primary)
            .contentShape(Capsule())
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isProminent {
            return isPressed ? Color.accentColor.opacity(0.82) : Color.accentColor
        }

        return isPressed
            ? Color.accentColor.opacity(0.16)
            : Color(nsColor: .controlBackgroundColor).opacity(0.66)
    }

    private var borderColor: Color {
        isProminent ? .clear : Color(nsColor: .separatorColor).opacity(0.24)
    }
}

extension View {
    func calRemHitTarget(
        minWidth: CGFloat = CalRemControlStyle.minimumHitSize,
        minHeight: CGFloat = CalRemControlStyle.minimumHitSize
    ) -> some View {
        frame(minWidth: minWidth, minHeight: minHeight)
            .contentShape(Rectangle())
    }
}
