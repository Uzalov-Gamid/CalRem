import SwiftUI

struct SidebarView: View {
    let lists: [TaskList]
    let tasks: [TaskItem]
    @Binding var selection: SidebarSelection?
    let onAddList: () -> Void
    let onEditList: (TaskList) -> Void
    let onDeleteList: (TaskList) -> Void

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(SmartFilter.allCases) { filter in
                    Label(filter.title, systemImage: filter.systemImage)
                        .tag(SidebarSelection.smart(filter) as SidebarSelection?)
                }
            }

            Section {
                ForEach(lists) { list in
                    HStack(spacing: 8) {
                        Image(systemName: list.symbolName)
                            .foregroundStyle(ListColor.named(list.colorName).color)
                            .frame(width: 18)
                        Text(list.name)
                            .lineLimit(1)
                        Spacer()
                        Text("\(count(for: list))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(SidebarSelection.list(list.id) as SidebarSelection?)
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

                Button {
                    onAddList()
                } label: {
                    Label("New List", systemImage: "plus")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            } header: {
                Text("Lists")
            }
        }
        .navigationTitle("CalRem")
    }

    private func count(for list: TaskList) -> Int {
        tasks.filter { $0.list?.id == list.id && !$0.isCompleted }.count
    }
}
