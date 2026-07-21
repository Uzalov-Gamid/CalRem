import SwiftData
import SwiftUI

enum AppWorkspace: String, CaseIterable, Identifiable {
    case tasks
    case calendar

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tasks:
            "Tasks"
        case .calendar:
            "Calendar"
        }
    }

    var systemImage: String {
        switch self {
        case .tasks:
            "checklist"
        case .calendar:
            "calendar"
        }
    }
}

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

struct TaskCreationRequest: Identifiable {
    let id = UUID()
    let defaultListID: UUID?
    let defaultDate: Date?
    let defaultAllDay: Bool
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\TaskList.sortOrder), SortDescriptor(\TaskList.createdAt)])
    private var lists: [TaskList]
    @Query(sort: [SortDescriptor(\TaskItem.createdAt, order: .reverse)])
    private var tasks: [TaskItem]

    @State private var workspace: AppWorkspace = .tasks
    @State private var selection: SidebarSelection = .smart(.today)
    @State private var selectedDate = Date()
    @State private var calendarMode: CalendarMode = .week
    @State private var createTaskRequest: TaskCreationRequest?
    @State private var editingTask: TaskItem?
    @State private var calendarEditingTask: TaskItem?
    @State private var editingList: TaskList?
    @State private var isCreatingList = false
    @State private var newListName = ""
    @State private var newListColor = ListColor.blue

    private let calendarService = CalendarDateService()

    var body: some View {
        NavigationSplitView {
            SidebarView(
                lists: activeLists,
                tasks: tasks,
                workspace: $workspace,
                selection: $selection,
                onAddList: showCreateList,
                onEditList: { editingList = $0 },
                onDeleteList: deleteList
            )
            .navigationSplitViewColumnWidth(min: 260, ideal: 292, max: 340)
        } detail: {
            switch workspace {
            case .tasks:
                tasksWorkspace
            case .calendar:
                calendarWorkspace
            }
        }
        .task {
            PersistenceController.seedDefaultListIfNeeded(in: modelContext)
        }
        .sheet(item: $createTaskRequest) { request in
            TaskEditorSheet(
                task: nil,
                lists: activeLists,
                defaultList: list(with: request.defaultListID) ?? selectedList ?? activeLists.first,
                defaultDate: request.defaultDate,
                defaultAllDay: request.defaultAllDay
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
                    showCreateTask()
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

    private var tasksWorkspace: some View {
        TaskListPanel(
            title: contentTitle,
            tasks: visibleTasks,
            onQuickAdd: quickAddTask,
            onAddTask: { showCreateTask() },
            onEditTask: { editingTask = $0 },
            onToggleTask: toggleTask,
            onDeleteTask: deleteTask
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var calendarWorkspace: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                calendarHeader
                Divider()
                PlannerCalendarView(
                    tasks: calendarTasks,
                    selectedDate: $selectedDate,
                    mode: $calendarMode,
                    onEditTask: { calendarEditingTask = $0 },
                    onUpdateTaskSchedule: updateTaskSchedule,
                    onCreateTaskSchedule: createCalendarTask
                )
            }

            if let calendarEditingTask {
                CalendarTaskInlineEditor(
                    task: calendarEditingTask,
                    lists: activeLists,
                    onSave: saveCalendarTaskInlineEdit,
                    onDelete: deleteCalendarTaskFromInlineEdit,
                    onDismiss: { self.calendarEditingTask = nil }
                )
                .padding(.top, 96)
                .padding(.trailing, 26)
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .topTrailing)))
                .zIndex(30)
            }
        }
        .animation(.snappy(duration: 0.16), value: calendarEditingTask?.id)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var calendarHeader: some View {
        HStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.red)
                    .frame(width: CalRemControlStyle.minimumHitSize, height: CalRemControlStyle.minimumHitSize)

                VStack(alignment: .leading, spacing: 2) {
                    Text(calendarHeaderTitle)
                        .font(.largeTitle.weight(.bold))
                    Text(calendarHeaderSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                createCalendarTask(defaultCalendarTaskSchedule())
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(CalRemIconButtonStyle(size: 30))
            .help("Create task on selected date")

            Picker("Calendar View", selection: $calendarMode) {
                ForEach(CalendarMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 188)

            Button {
                selectedDate = calendarService.previousDate(from: selectedDate, mode: calendarMode)
            } label: {
                Label("Previous", systemImage: "chevron.left")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(CalRemIconButtonStyle())
            .help("Previous \(calendarMode.title.lowercased())")

            Button("Today") {
                selectedDate = .now
            }
            .buttonStyle(CalRemPillButtonStyle())
            .help("Jump to today")

            Button {
                selectedDate = calendarService.nextDate(from: selectedDate, mode: calendarMode)
            } label: {
                Label("Next", systemImage: "chevron.right")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(CalRemIconButtonStyle())
            .help("Next \(calendarMode.title.lowercased())")
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 13)
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var calendarHeaderTitle: String {
        selectedDate.formatted(.dateTime.month(.wide).year())
    }

    private var calendarHeaderSubtitle: String {
        switch calendarMode {
        case .month:
            "Month View"
        case .week, .day:
            calendarService.title(for: selectedDate, mode: calendarMode)
        }
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
                .buttonStyle(CalRemPillButtonStyle())
                Button("Create") {
                    createList()
                }
                .buttonStyle(CalRemPillButtonStyle(isProminent: true))
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
        }
    }

    private var visibleTasks: [TaskItem] {
        filteredTasks.sorted(by: taskSort)
    }

    private var calendarTasks: [TaskItem] {
        tasks
            .filter { !$0.isCompleted && $0.isScheduled }
            .sorted(by: taskSort)
    }

    private var filteredTasks: [TaskItem] {
        switch selection {
        case .smart(.today):
            tasks.filter { task in
                guard !task.isCompleted else { return false }
                guard let start = task.calendarStart else { return false }
                return Calendar.current.isDate(start, inSameDayAs: .now)
            }
        case .smart(.upcoming):
            tasks.filter { task in
                guard !task.isCompleted else { return false }
                guard let start = task.calendarStart else { return false }
                return start >= Calendar.current.startOfDay(for: .now)
            }
        case .smart(.all):
            tasks
        case .smart(.completed):
            tasks.filter(\.isCompleted)
        case let .list(id):
            tasks.filter { $0.list?.id == id }
        }
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

    private func showCreateTask(scheduledOn date: Date? = nil, allDay: Bool = false) {
        let contextualDate: Date?
        let contextualAllDay: Bool

        if let date {
            contextualDate = date
            contextualAllDay = allDay
        } else if case .smart(.today) = selection, workspace == .tasks {
            contextualDate = .now
            contextualAllDay = true
        } else {
            contextualDate = nil
            contextualAllDay = false
        }

        createTaskRequest = TaskCreationRequest(
            defaultListID: selectedList?.id ?? activeLists.first?.id,
            defaultDate: contextualDate,
            defaultAllDay: contextualAllDay
        )
    }

    private func quickAddTask(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let list = selectedList ?? activeLists.first else { return }

        let task = TaskItem(title: trimmed, list: list)
        if case .smart(.today) = selection {
            task.apply(schedule: TaskSchedule(dueDate: Calendar.current.startOfDay(for: .now), startDate: nil, endDate: nil, isAllDay: true))
        }

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

    private func createCalendarTask(_ schedule: CalendarTaskDraftSchedule) {
        guard let list = selectedList ?? activeLists.first else { return }

        let task = TaskItem(title: "New Task", list: list)
        task.apply(schedule: taskSchedule(from: schedule))
        modelContext.insert(task)
        selectedDate = schedule.start
        workspace = .calendar
        try? modelContext.save()
        calendarEditingTask = task
    }

    private func saveCalendarTaskInlineEdit(_ task: TaskItem, payload: CalendarTaskInlineEditorPayload) {
        guard let list = list(with: payload.listID) ?? task.list ?? activeLists.first else { return }

        task.title = payload.title
        task.notes = payload.notes
        task.list = list
        task.isCompleted = payload.isCompleted
        task.completedAt = payload.isCompleted ? (task.completedAt ?? .now) : nil
        task.apply(schedule: payload.schedule)
        task.reminderDate = payload.reminderDate
        task.notificationIdentifier = payload.reminderDate == nil ? nil : task.notificationID
        task.touch()
        selectedDate = task.calendarStart ?? selectedDate
        try? modelContext.save()

        let reminderPayload = ReminderPayload(
            taskID: task.id,
            title: task.title,
            notes: task.notes,
            reminderDate: task.reminderDate,
            isCompleted: task.isCompleted
        )
        Task {
            await NotificationScheduler.shared.sync(reminderPayload)
        }

        calendarEditingTask = nil
    }

    private func deleteCalendarTaskFromInlineEdit(_ task: TaskItem) {
        calendarEditingTask = nil
        deleteTask(task)
    }

    private func updateTaskSchedule(_ task: TaskItem, start: Date, end: Date) {
        let minimumEnd = Calendar.current.date(
            byAdding: .second,
            value: Int(TaskScheduleValidator.minimumDuration),
            to: start
        ) ?? start
        let finalEnd = max(end, minimumEnd)

        task.apply(
            schedule: TaskSchedule(
                dueDate: start,
                startDate: start,
                endDate: finalEnd,
                isAllDay: false
            )
        )
        selectedDate = start
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

    private func defaultCalendarTaskSchedule() -> CalendarTaskDraftSchedule {
        if calendarMode == .month {
            return .allDay(on: selectedDate)
        }

        let calendar = Calendar.current
        let start: Date

        if calendar.isDateInToday(selectedDate) {
            let now = Date()
            let minutes = calendar.dateComponents([.minute], from: now).minute ?? 0
            let minutesToAdd = minutes % CalendarInteractionService.snapIntervalMinutes == 0
                ? CalendarInteractionService.snapIntervalMinutes
                : CalendarInteractionService.snapIntervalMinutes - (minutes % CalendarInteractionService.snapIntervalMinutes)
            start = calendar.date(byAdding: .minute, value: minutesToAdd, to: now) ?? now
        } else {
            start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        }

        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let minutesFromStartOfDay = (startComponents.hour ?? 9) * 60 + (startComponents.minute ?? 0)
        let snapped = CalendarInteractionService.newTaskRange(
            on: start,
            locationY: CGFloat(minutesFromStartOfDay) / 60 * CalRemControlStyle.calendarHourHeight,
            hourHeight: CalRemControlStyle.calendarHourHeight
        )
        return .timed(start: snapped.start, end: snapped.end)
    }

    private func taskSchedule(from draft: CalendarTaskDraftSchedule) -> TaskSchedule {
        if draft.isAllDay {
            return TaskSchedule(
                dueDate: Calendar.current.startOfDay(for: draft.start),
                startDate: nil,
                endDate: nil,
                isAllDay: true
            )
        }

        let end = draft.end
            ?? Calendar.current.date(
                byAdding: .minute,
                value: CalendarInteractionService.minimumDurationMinutes,
                to: draft.start
            )
        return TaskSchedule(
            dueDate: draft.start,
            startDate: draft.start,
            endDate: end,
            isAllDay: false
        )
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
        workspace = .tasks
        isCreatingList = false
    }

    private func list(with id: UUID?) -> TaskList? {
        guard let id else { return nil }
        return activeLists.first { $0.id == id }
    }
}

#Preview {
    RootView()
        .modelContainer(PersistenceController.preview.container)
}
