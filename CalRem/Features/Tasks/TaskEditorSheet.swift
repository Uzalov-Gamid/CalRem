import SwiftData
import SwiftUI

struct TaskEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let task: TaskItem?
    let lists: [TaskList]
    let defaultList: TaskList?
    let defaultDate: Date?
    let defaultAllDay: Bool

    @State private var title: String
    @State private var notes: String
    @State private var selectedListID: UUID?
    @State private var isCompleted: Bool
    @State private var hasDate: Bool
    @State private var scheduleDate: Date
    @State private var isAllDay: Bool
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var hasReminder: Bool
    @State private var reminderDate: Date
    @State private var priority: TaskPriority
    @State private var recurrenceRule: TaskRecurrenceRule

    init(
        task: TaskItem?,
        lists: [TaskList],
        defaultList: TaskList?,
        defaultDate: Date? = nil,
        defaultAllDay: Bool = false
    ) {
        self.task = task
        self.lists = lists
        self.defaultList = defaultList
        self.defaultDate = defaultDate
        self.defaultAllDay = defaultAllDay

        let defaultStart = Self.defaultStartTime(for: defaultDate ?? .now)
        let calendarStart = task?.calendarStart ?? defaultDate ?? defaultStart
        let startTime = task?.calendarStart ?? defaultStart
        let calendarEnd = task?.calendarEnd ?? Calendar.current.date(byAdding: .minute, value: 30, to: startTime) ?? startTime
        let shouldShowDate = task?.isScheduled ?? (defaultDate != nil)

        _title = State(initialValue: task?.title ?? "")
        _notes = State(initialValue: task?.notes ?? "")
        _selectedListID = State(initialValue: task?.list?.id ?? defaultList?.id)
        _isCompleted = State(initialValue: task?.isCompleted ?? false)
        _hasDate = State(initialValue: shouldShowDate)
        _scheduleDate = State(initialValue: calendarStart)
        _isAllDay = State(initialValue: task?.isAllDay ?? defaultAllDay)
        _startTime = State(initialValue: startTime)
        _endTime = State(initialValue: calendarEnd)
        _hasReminder = State(initialValue: task?.reminderDate != nil)
        _reminderDate = State(initialValue: task?.reminderDate ?? startTime)
        _priority = State(initialValue: task?.priority ?? .none)
        _recurrenceRule = State(initialValue: task?.recurrenceRule ?? .none)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(task == nil ? "New Task" : "Edit Task")
                .font(.title2.weight(.semibold))

            Form {
                TextField("Title", text: $title)

                Picker("List", selection: $selectedListID) {
                    ForEach(lists) { list in
                        Text(list.name).tag(Optional(list.id))
                    }
                }

                Picker("Priority", selection: $priority) {
                    ForEach(TaskPriority.allCases) { priority in
                        Text(priority.title).tag(priority)
                    }
                }

                Toggle("Completed", isOn: $isCompleted)

                Section("Schedule") {
                    Toggle("Show in calendar", isOn: $hasDate)

                    if hasDate {
                        DatePicker("Date", selection: $scheduleDate, displayedComponents: .date)
                        Toggle("All day", isOn: $isAllDay)

                        if !isAllDay {
                            DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                            DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                        }
                    }

                    Picker("Repeat", selection: $recurrenceRule) {
                        ForEach(TaskRecurrenceRule.allCases) { rule in
                            Text(rule.title).tag(rule)
                        }
                    }
                    .disabled(!hasDate)
                }

                Section("Reminder") {
                    Toggle("Remind me", isOn: $hasReminder)
                    if hasReminder {
                        DatePicker("Reminder", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .buttonStyle(CalRemPillButtonStyle())
                Button(task == nil ? "Create" : "Save") {
                    save()
                }
                .buttonStyle(CalRemPillButtonStyle(isProminent: true))
                .keyboardShortcut(.defaultAction)
                .disabled(trimmedTitle.isEmpty || selectedListID == nil)
            }
        }
        .padding(24)
        .frame(width: 460, height: 620)
        .onChange(of: hasDate) { _, hasDate in
            if !hasDate {
                recurrenceRule = .none
            }
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func defaultStartTime(for date: Date) -> Date {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            let now = Date()
            let components = calendar.dateComponents([.minute], from: now)
            let minute = components.minute ?? 0
            let minutesToAdd = minute < 30 ? 30 - minute : 60 - minute

            return calendar.date(byAdding: .minute, value: minutesToAdd, to: now) ?? now
        }

        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
    }

    private func save() {
        guard
            !trimmedTitle.isEmpty,
            let list = selectedList
        else {
            return
        }

        let normalized = TaskScheduleValidator.normalized(
            hasDate: hasDate,
            date: scheduleDate,
            isAllDay: isAllDay,
            startTime: startTime,
            endTime: endTime
        )

        let target = task ?? TaskItem(title: trimmedTitle, list: list)
        let wasCompleted = target.isCompleted
        target.title = trimmedTitle
        target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        target.list = list
        target.isCompleted = isCompleted
        target.completedAt = isCompleted ? (target.completedAt ?? .now) : nil
        target.priority = priority
        target.recurrenceRule = hasDate ? recurrenceRule : .none
        target.apply(schedule: normalized)
        target.reminderDate = hasReminder ? reminderDate : nil
        target.notificationIdentifier = hasReminder ? target.notificationID : nil
        target.touch()

        if task == nil {
            modelContext.insert(target)
        }

        if !wasCompleted, target.isCompleted {
            createNextRecurringInstanceIfNeeded(from: target)
        }

        try? modelContext.save()

        let payload = ReminderPayload(
            taskID: target.id,
            title: target.title,
            notes: target.notes,
            reminderDate: target.reminderDate,
            isCompleted: target.isCompleted
        )
        Task {
            await NotificationScheduler.shared.sync(payload)
        }

        dismiss()
    }

    private var selectedList: TaskList? {
        guard let selectedListID else { return defaultList ?? lists.first }
        return lists.first { $0.id == selectedListID } ?? defaultList ?? lists.first
    }

    private func createNextRecurringInstanceIfNeeded(from task: TaskItem) {
        guard let nextTask = task.nextRecurringInstance(), !hasExistingRecurringInstance(matching: nextTask, original: task) else {
            return
        }

        modelContext.insert(nextTask)

        let payload = ReminderPayload(
            taskID: nextTask.id,
            title: nextTask.title,
            notes: nextTask.notes,
            reminderDate: nextTask.reminderDate,
            isCompleted: nextTask.isCompleted
        )
        Task {
            await NotificationScheduler.shared.sync(payload)
        }
    }

    private func hasExistingRecurringInstance(matching candidate: TaskItem, original: TaskItem) -> Bool {
        let descriptor = FetchDescriptor<TaskItem>()
        let existingTasks = (try? modelContext.fetch(descriptor)) ?? []
        return existingTasks.contains { task in
            guard task.id != original.id else { return false }
            return task.title == candidate.title
                && task.list?.id == candidate.list?.id
                && task.recurrenceRule == candidate.recurrenceRule
                && task.calendarStart == candidate.calendarStart
        }
    }
}
