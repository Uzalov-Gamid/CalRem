import SwiftUI

struct SidebarView: View {
    let lists: [TaskList]
    let tasks: [TaskItem]
    @Binding var workspace: AppWorkspace
    @Binding var selection: SidebarSelection
    let onAddList: () -> Void
    let onEditList: (TaskList) -> Void
    let onDeleteList: (TaskList) -> Void

    private let gridColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                workspaceSwitcher
                smartGrid
                listsSection
            }
            .padding(CalRemControlStyle.sidebarInset)
        }
        .scrollContentBackground(.hidden)
        .background(sidebarBackground)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("CalRem")
                .font(.title2.weight(.bold))
                .lineLimit(1)

            Spacer()

            Button {
                onAddList()
            } label: {
                Image(systemName: "list.bullet.rectangle.portrait.badge.plus")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: CalRemControlStyle.minimumHitSize, height: CalRemControlStyle.minimumHitSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("New list")
        }
        .padding(.top, 6)
    }

    private var workspaceSwitcher: some View {
        VStack(spacing: 7) {
            workspaceRow(.tasks)
            workspaceRow(.calendar)
        }
        .padding(4)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.28), lineWidth: 1)
        }
    }

    private func workspaceRow(_ item: AppWorkspace) -> some View {
        Button {
            workspace = item
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 22)

                Text(item.title)
                    .font(.callout.weight(.medium))

                Spacer(minLength: 8)

                if item == .calendar {
                    CountBadge(count: scheduledTaskCount)
                }
            }
            .foregroundStyle(workspace == item ? Color.primary : Color.secondary)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
            .background(
                workspace == item ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.16) : Color.clear,
                in: RoundedRectangle(cornerRadius: CalRemControlStyle.rowRadius, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var smartGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 10) {
            ForEach(SmartFilter.allCases) { filter in
                Button {
                    workspace = .tasks
                    selection = .smart(filter)
                } label: {
                    SmartListCard(
                        title: filter.title,
                        systemImage: filter.systemImage,
                        count: count(for: filter),
                        tint: tint(for: filter),
                        isSelected: workspace == .tasks && selection == .smart(filter)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var listsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("My Lists")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                Button {
                    onAddList()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: CalRemControlStyle.compactHitSize, height: CalRemControlStyle.compactHitSize)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("New list")
            }
            .padding(.horizontal, 2)

            VStack(spacing: 3) {
                ForEach(lists) { list in
                    taskListRow(list)
                }
            }
        }
    }

    private func taskListRow(_ list: TaskList) -> some View {
        HStack(spacing: 4) {
            Button {
                workspace = .tasks
                selection = .list(list.id)
            } label: {
                HStack(spacing: 11) {
                    ZStack {
                        Circle()
                            .fill(ListColor.named(list.colorName).color)
                        Image(systemName: list.symbolName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 28, height: 28)

                    Text(list.name)
                        .font(.callout)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    CountBadge(count: count(for: list))
                }
                .padding(.horizontal, 9)
                .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                .background(
                    workspace == .tasks && selection == .list(list.id)
                        ? Color.accentColor.opacity(0.13)
                        : Color.clear,
                    in: RoundedRectangle(cornerRadius: CalRemControlStyle.rowRadius, style: .continuous)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                Button("Edit List") {
                    onEditList(list)
                }
                Button("Delete List", role: .destructive) {
                    onDeleteList(list)
                }
                .disabled(lists.count <= 1)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: CalRemControlStyle.compactHitSize, height: CalRemControlStyle.compactHitSize)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help("List actions")
        }
        .contextMenu {
            Button("Edit List") {
                onEditList(list)
            }
            Button("Delete List", role: .destructive) {
                onDeleteList(list)
            }
            .disabled(lists.count <= 1)
        }
    }

    private var sidebarBackground: Color {
        Color(nsColor: .windowBackgroundColor)
    }

    private var scheduledTaskCount: Int {
        tasks.filter { !$0.isCompleted && $0.isScheduled }.count
    }

    private func count(for filter: SmartFilter) -> Int {
        switch filter {
        case .today:
            tasks.filter { task in
                guard !task.isCompleted, let start = task.calendarStart else { return false }
                return Calendar.current.isDate(start, inSameDayAs: .now)
            }.count
        case .upcoming:
            tasks.filter { task in
                guard !task.isCompleted, let start = task.calendarStart else { return false }
                return start >= Calendar.current.startOfDay(for: .now)
            }.count
        case .all:
            tasks.count
        case .completed:
            tasks.filter(\.isCompleted).count
        }
    }

    private func count(for list: TaskList) -> Int {
        tasks.filter { $0.list?.id == list.id && !$0.isCompleted }.count
    }

    private func tint(for filter: SmartFilter) -> Color {
        switch filter {
        case .today:
            .accentColor
        case .upcoming:
            .orange
        case .all:
            .secondary
        case .completed:
            .green
        }
    }
}

private struct SmartListCard: View {
    let title: String
    let systemImage: String
    let count: Int
    let tint: Color
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(tint)
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 30, height: 30)

                Spacer(minLength: 8)

                Text("\(count)")
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
            }

            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: CalRemControlStyle.sidebarCardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CalRemControlStyle.sidebarCardRadius, style: .continuous)
                .stroke(isSelected ? tint.opacity(0.42) : Color(nsColor: .separatorColor).opacity(0.26), lineWidth: isSelected ? 1.4 : 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: CalRemControlStyle.sidebarCardRadius, style: .continuous))
    }

    private var cardBackground: Color {
        isSelected ? tint.opacity(0.13) : Color(nsColor: .controlBackgroundColor)
    }
}

private struct CountBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.caption.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .frame(minHeight: 20)
            .background(Color.secondary.opacity(0.10), in: Capsule())
    }
}
