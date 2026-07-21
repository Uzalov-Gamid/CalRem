import SwiftData
import SwiftUI

struct TaskEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let task: TaskItem?
    let lists: [TaskList]
    let defaultList: TaskList?

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

    init(task: TaskItem?, lists: [TaskList], defaultList: TaskList?) {
        self.task = task
        self.lists = lists
        self.defaultList = defaultList

        let calendarStart = task?.calendarStart ?? .now
        let calendarEnd = task?.calendarEnd ?? Calendar.current.date(byAdding: .minute, value: 30, to: calendarStart) ?? calendarStart

        _title = State(initialValue: task?.title ?? "")
        _notes = State(initialValue: task?.notes ?? "")
        _selectedListID = State(initialValue: task?.list?.id ?? defaultList?.id)
        _isCompleted = State(initialValue: task?.isCompleted ?? false)
        _hasDate = State(initialValue: task?.isScheduled ?? false)
        _scheduleDate = State(initialValue: calendarStart)
        _isAllDay = State(initialValue: task?.isAllDay ?? false)
        _startTime = State(initialValue: calendarStart)
        _endTime = State(initialValue: calendarEnd)
        _hasReminder = State(initialValue: task?.reminderDate != nil)
        _reminderDate = State(initialValue: task?.reminderDate ?? calendarStart)
        _priority = State(initialValue: task?.priority ?? .none)
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
                Button(task == nil ? "Create" : "Save") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(trimmedTitle.isEmpty || selectedListID == nil)
            }
        }
        .padding(24)
        .frame(width: 460, height: 620)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
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
        target.title = trimmedTitle
        target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        target.list = list
        target.isCompleted = isCompleted
        target.completedAt = isCompleted ? (target.completedAt ?? .now) : nil
        target.priority = priority
        target.apply(schedule: normalized)
        target.reminderDate = hasReminder ? reminderDate : nil
        target.notificationIdentifier = hasReminder ? target.notificationID : nil
        target.touch()

        if task == nil {
            modelContext.insert(target)
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
}
