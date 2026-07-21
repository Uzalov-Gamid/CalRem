import SwiftUI

struct InteractiveCalendarTaskBlock: View {
    let task: TaskItem
    let width: CGFloat
    let height: CGFloat
    let hourHeight: CGFloat
    let dayWidth: CGFloat?
    let onEditTask: (TaskItem) -> Void
    let onUpdateSchedule: (TaskItem, Date, Date) -> Void

    @GestureState private var moveTranslation: CGSize = .zero
    @GestureState private var resizeDeltaY: CGFloat = 0

    var body: some View {
        CalendarTaskBlock(task: task, isInteracting: isInteracting)
            .frame(width: width, height: displayedHeight)
            .offset(x: moveTranslation.width, y: moveTranslation.height)
            .overlay(alignment: .bottom) {
                resizeHandle
            }
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .gesture(moveGesture)
            .onTapGesture {
                onEditTask(task)
            }
            .zIndex(isInteracting ? 20 : 1)
            .animation(.snappy(duration: 0.14), value: isInteracting)
    }

    private var displayedHeight: CGFloat {
        max(height + resizeDeltaY, 28)
    }

    private var isInteracting: Bool {
        abs(moveTranslation.width) > 0.5
            || abs(moveTranslation.height) > 0.5
            || abs(resizeDeltaY) > 0.5
    }

    private var moveGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .updating($moveTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                guard let start = task.calendarStart, let end = task.calendarEnd else { return }

                let range = CalendarInteractionService.movedRange(
                    start: start,
                    end: end,
                    translation: value.translation,
                    hourHeight: hourHeight,
                    dayWidth: dayWidth
                )
                onUpdateSchedule(task, range.start, range.end)
            }
    }

    private var resizeHandle: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            Capsule()
                .fill(Color.primary.opacity(isInteracting ? 0.42 : 0.24))
                .frame(width: 28, height: 3)
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 15)
        .contentShape(Rectangle())
        .highPriorityGesture(resizeGesture)
        .help("Drag to change duration")
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .updating($resizeDeltaY) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                guard let start = task.calendarStart, let end = task.calendarEnd else { return }

                let range = CalendarInteractionService.resizedRange(
                    start: start,
                    end: end,
                    resizeDeltaY: value.translation.height,
                    hourHeight: hourHeight
                )
                onUpdateSchedule(task, range.start, range.end)
            }
    }
}
