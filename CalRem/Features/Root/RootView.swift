import SwiftData
import SwiftUI

enum SmartFilter: String, CaseIterable, Identifiable {
    case today
    case upcoming
    case all
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            "Today"
        case .upcoming:
            "Upcoming"
        case .all:
            "All"
        case .completed:
            "Completed"
        }
    }

    var systemImage: String {
        switch self {
        case .today:
            "calendar.circle"
        case .upcoming:
            "calendar.badge.clock"
        case .all:
            "tray.full"
        case .completed:
            "checkmark.circle"
        }
    }
}

enum SidebarSelection: Hashable {
    case smart(SmartFilter)
    case list(UUID)
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\TaskList.sortOrder), SortDescriptor(\TaskList.createdAt)])
    private var lists: [TaskList]
    @Query(sort: [SortDescriptor(\TaskItem.createdAt, order: .reverse)])
    private var tasks: [TaskItem]

    @State private var selection: SidebarSelection? = .smart(.today)
    @State private var selectedDate = Date()
    @State private var calendarMode: CalendarMode = .week
    @State private var editingTask: TaskItem?
    @State private var editingList: TaskList?
    @State private var isCreatingTask = false
    @State private var isCreatingList = false
    @State private var newListName = ""
    @State private var newListColor = ListColor.blue

    private let calendarService = CalendarDateService()

    var body: some View {
        NavigationSplitView {
            SidebarView(
                lists: activeLists,
                tasks: tasks,
                selection: $selection,
                onAddList: showCreateList,
                onEditList: { editingList = $0 },
                onDeleteList: deleteList
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            VStack(spacing: 0) {
                plannerHeader
                Divider()
                HStack(spacing: 0) {
                    TaskListPanel(
                        title: contentTitle,
                        tasks: visibleTasks,
                        lists: activeLists,
                        onQuickAdd: quickAddTask,
                        onAddTask: { isCreatingTask = true },
                        onEditTask: { editingTask = $0 },
                        onToggleTask: toggleTask,
                        onDeleteTask: deleteTask
                    )
                    .frame(minWidth: 320, idealWidth: 380, maxWidth: 460)

                    Divider()

                    PlannerCalendarView(
                        tasks: calendarTasks,
                        selectedDate: $selectedDate,
                        mode: $calendarMode,
                        onEditTask: { editingTask = $0 }
                    )
                    .frame(minWidth: 540)
                }
            }
        }
        .task {
            PersistenceController.seedDefaultListIfNeeded(in: modelContext)
        }
        .sheet(isPresented: $isCreatingTask) {
            TaskEditorSheet(
                task: nil,
                lists: activeLists,
                defaultList: selectedList ?? activeLists.first
            )
        }
        .sheet(item: $editingTask) { task in
            TaskEditorSheet(
                task: task,
                lists: activeLists,
                defaultList: task.list ?? selectedList ?? activeLists.first
            )
        }
        .sheet(item: $editingList) { list in
            ListEditorSheet(list: list)
        }
        .sheet(isPresented: $isCreatingList) {
            createListSheet
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    isCreatingTask = true
                } label: {
                    Label("New Task", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])

                Button {
                    showCreateList()
                } label: {
                    Label("New List", systemImage: "folder.badge.plus")
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }

    private var plannerHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(contentTitle)
                    .font(.title2.weight(.semibold))
                Text(calendarService.title(for: selectedDate, mode: calendarMode))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                selectedDate = calendarService.previousDate(from: selectedDate, mode: calendarMode)
            } label: {
                Label("Previous", systemImage: "chevron.left")
            }
            .labelStyle(.iconOnly)

            Button("Today") {
                selectedDate = .now
            }

            Button {
                selectedDate = calendarService.nextDate(from: selectedDate, mode: calendarMode)
            } label: {
                Label("Next", systemImage: "chevron.right")
            }
            .labelStyle(.iconOnly)

            Picker("Calendar View", selection: $calendarMode) {
                ForEach(CalendarMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 210)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var createListSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("New List")
                .font(.title2.weight(.semibold))

            TextField("List name", text: $newListName)
                .textFieldStyle(.roundedBorder)

            Picker("Color", selection: $newListColor) {
                ForEach(ListColor.allCases) { color in
                    HStack {
                        Circle()
                            .fill(color.color)
                            .frame(width: 10, height: 10)
                        Text(color.title)
                    }
                    .tag(color)
                }
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    isCreatingList = false
                }
                Button("Create") {
                    createList()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 360)
    }

    private var activeLists: [TaskList] {
        lists.filter { !$0.isArchived }
    }

    private var selectedList: TaskList? {
        guard case let .list(id) = selection else { return nil }
        return activeLists.first { $0.id == id }
    }

    private var contentTitle: String {
        switch selection {
        case let .smart(filter):
            filter.title
        case let .list(id):
            activeLists.first { $0.id == id }?.name ?? "List"
        case nil:
            "Today"
        }
    }

    private var visibleTasks: [TaskItem] {
        filteredTasks(includeUndated: true).sorted(by: taskSort)
    }

    private var calendarTasks: [TaskItem] {
        filteredTasks(includeUndated: false).filter(\.isScheduled)
    }

    private func filteredTasks(includeUndated: Bool) -> [TaskItem] {
        let base: [TaskItem]
        switch selection {
        case .smart(.today), nil:
            base = tasks.filter { task in
                guard !task.isCompleted else { return false }
                guard let start = task.calendarStart else { return includeUndated }
                return Calendar.current.isDate(start, inSameDayAs: .now)
            }
        case .smart(.upcoming):
            base = tasks.filter { task in
                guard !task.isCompleted else { return false }
                guard let start = task.calendarStart else { return includeUndated }
                return start >= Calendar.current.startOfDay(for: .now)
            }
        case .smart(.all):
            base = tasks
        case .smart(.completed):
            base = tasks.filter(\.isCompleted)
        case let .list(id):
            base = tasks.filter { $0.list?.id == id }
        }

        return includeUndated ? base : base.filter(\.isScheduled)
    }

    private func taskSort(_ lhs: TaskItem, _ rhs: TaskItem) -> Bool {
        if lhs.isCompleted != rhs.isCompleted {
            return !lhs.isCompleted
        }

        switch (lhs.calendarStart, rhs.calendarStart) {
        case let (left?, right?):
            return left < right
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return lhs.createdAt > rhs.createdAt
        }
    }

    private func quickAddTask(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let list = selectedList ?? activeLists.first else { return }

        let task = TaskItem(title: trimmed, list: list)
        modelContext.insert(task)
        try? modelContext.save()
    }

    private func toggleTask(_ task: TaskItem) {
        task.toggleCompletion()
        try? modelContext.save()

        let payload = ReminderPayload(
            taskID: task.id,
            title: task.title,
            notes: task.notes,
            reminderDate: task.reminderDate,
            isCompleted: task.isCompleted
        )
        Task {
            await NotificationScheduler.shared.sync(payload)
        }
    }

    private func deleteTask(_ task: TaskItem) {
        let taskID = task.id
        modelContext.delete(task)
        try? modelContext.save()

        Task {
            await NotificationScheduler.shared.cancel(taskID: taskID)
        }
    }

    private func deleteList(_ list: TaskList) {
        guard activeLists.count > 1 else { return }
        let taskIDs = tasks
            .filter { $0.list?.id == list.id }
            .map(\.id)

        if case let .list(id) = selection, id == list.id {
            selection = .smart(.all)
        }

        modelContext.delete(list)
        try? modelContext.save()

        Task {
            for taskID in taskIDs {
                await NotificationScheduler.shared.cancel(taskID: taskID)
            }
        }
    }

    private func showCreateList() {
        newListName = ""
        newListColor = .blue
        isCreatingList = true
    }

    private func createList() {
        let trimmed = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let list = TaskList(
            name: trimmed,
            colorName: newListColor.rawValue,
            symbolName: "list.bullet",
            sortOrder: activeLists.count
        )
        modelContext.insert(list)
        try? modelContext.save()
        selection = .list(list.id)
        isCreatingList = false
    }
}

#Preview {
    RootView()
        .modelContainer(PersistenceController.preview.container)
}
