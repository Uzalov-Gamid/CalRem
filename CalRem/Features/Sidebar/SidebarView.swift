import SwiftUI

struct SidebarView: View {
    let lists: [TaskList]
    let tasks: [TaskItem]
    @Binding var workspace: AppWorkspace
    @Binding var selection: SidebarSelection
    let onAddList: () -> Void
    let onEditList: (TaskList) -> Void
    let onDeleteList: (TaskList) -> Void

    var body: some View {
        List {
            Section {
                workspaceRow(.tasks)
                workspaceRow(.calendar)
            }

            Section("Smart Lists") {
                ForEach(SmartFilter.allCases) { filter in
                    smartFilterRow(filter)
                }
            }

            Section("Lists") {
                ForEach(lists) { list in
                    taskListRow(list)
                }

                Button {
                    onAddList()
                } label: {
                    Label("New List", systemImage: "plus")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("CalRem")
    }

    private func workspaceRow(_ item: AppWorkspace) -> some View {
        Button {
            workspace = item
        } label: {
            SidebarRowLabel(
                title: item.title,
                systemImage: item.systemImage,
                count: item == .calendar ? scheduledTaskCount : nil,
                color: .accentColor,
                isSelected: workspace == item
            )
        }
        .buttonStyle(.plain)
    }

    private func smartFilterRow(_ filter: SmartFilter) -> some View {
        Button {
            workspace = .tasks
            selection = .smart(filter)
        } label: {
            SidebarRowLabel(
                title: filter.title,
                systemImage: filter.systemImage,
                count: count(for: filter),
                color: .secondary,
                isSelected: workspace == .tasks && selection == .smart(filter)
            )
        }
        .buttonStyle(.plain)
    }

    private func taskListRow(_ list: TaskList) -> some View {
        HStack(spacing: 6) {
            Button {
                workspace = .tasks
                selection = .list(list.id)
            } label: {
                SidebarRowLabel(
                    title: list.name,
                    systemImage: list.symbolName,
                    count: count(for: list),
                    color: ListColor.named(list.colorName).color,
                    isSelected: workspace == .tasks && selection == .list(list.id)
                )
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
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
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
}

private struct SidebarRowLabel: View {
    let title: String
    let systemImage: String
    let count: Int?
    let color: Color
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 18)

            Text(title)
                .font(.callout)
                .lineLimit(1)

            Spacer(minLength: 8)

            if let count {
                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isSelected ? Color.accentColor.opacity(0.14) : Color.clear,
            in: RoundedRectangle(cornerRadius: 7)
        )
    }
}
