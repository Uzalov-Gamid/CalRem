import SwiftUI

struct CalendarTaskInlineEditorPayload {
    let title: String
    let notes: String
    let listID: UUID?
    let isCompleted: Bool
    let schedule: TaskSchedule
    let reminderDate: Date?
}

struct CalendarTaskInlineEditor: View {
    let task: TaskItem
    let lists: [TaskList]
    let onSave: (TaskItem, CalendarTaskInlineEditorPayload) -> Void
    let onDelete: (TaskItem) -> Void
    let onDismiss: () -> Void

    @State private var title: String
    @State private var notes: String
    @State private var selectedListID: UUID?
    @State private var isCompleted: Bool
    @State private var scheduleDate: Date
    @State private var isAllDay: Bool
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var hasReminder: Bool
    @State private var reminderDate: Date
    @FocusState private var titleIsFocused: Bool

    init(
        task: TaskItem,
        lists: [TaskList],
        onSave: @escaping (TaskItem, CalendarTaskInlineEditorPayload) -> Void,
        onDelete: @escaping (TaskItem) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.task = task
        self.lists = lists
        self.onSave = onSave
        self.onDelete = onDelete
        self.onDismiss = onDismiss

        let start = task.calendarStart ?? .now
        let end = task.calendarEnd ?? Calendar.current.date(
            byAdding: .minute,
            value: CalendarInteractionService.minimumDurationMinutes,
            to: start
        ) ?? start

        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.notes)
        _selectedListID = State(initialValue: task.list?.id ?? lists.first?.id)
        _isCompleted = State(initialValue: task.isCompleted)
        _scheduleDate = State(initialValue: start)
        _isAllDay = State(initialValue: task.isAllDay)
        _startTime = State(initialValue: start)
        _endTime = State(initialValue: end)
        _hasReminder = State(initialValue: task.reminderDate != nil)
        _reminderDate = State(initialValue: task.reminderDate ?? start)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            titleAndList
            scheduleSection
            notesSection
            footer
        }
        .padding(18)
        .frame(width: 410)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.42), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
        .onAppear {
            titleIsFocused = true
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("Calendar Task")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: CalRemControlStyle.compactHitSize, height: CalRemControlStyle.compactHitSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Close")
        }
    }

    private var titleAndList: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("New Task", text: $title)
                .font(.title2.weight(.semibold))
                .textFieldStyle(.plain)
                .focused($titleIsFocused)

            HStack(spacing: 8) {
                Picker("List", selection: $selectedListID) {
                    ForEach(lists) { list in
                        Text(list.name).tag(Optional(list.id))
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)

                Spacer()

                Toggle("Completed", isOn: $isCompleted)
                    .toggleStyle(.checkbox)
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                DatePicker("Date", selection: $scheduleDate, displayedComponents: .date)
                    .labelsHidden()
            }

            Toggle("All day", isOn: $isAllDay)
                .toggleStyle(.switch)

            if !isAllDay {
                HStack(spacing: 10) {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                        .frame(width: 18)
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    Text("-")
                        .foregroundStyle(.secondary)
                    DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    Spacer(minLength: 0)
                }
            }

            Toggle("Alert", isOn: $hasReminder)
                .toggleStyle(.checkbox)

            if hasReminder {
                DatePicker("Reminder", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
            }
        }
        .font(.callout)
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var notesSection: some View {
        TextEditor(text: $notes)
            .font(.callout)
            .frame(minHeight: 72)
            .scrollContentBackground(.hidden)
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Add Notes")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 17)
                        .allowsHitTesting(false)
                }
            }
    }

    private var footer: some View {
        HStack {
            Button(role: .destructive) {
                onDelete(task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)

            Spacer()

            Button("Done") {
                save()
            }
            .buttonStyle(CalRemPillButtonStyle(isProminent: true))
            .keyboardShortcut(.defaultAction)
            .disabled(trimmedTitle.isEmpty || selectedListID == nil)
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        let schedule = TaskScheduleValidator.normalized(
            hasDate: true,
            date: scheduleDate,
            isAllDay: isAllDay,
            startTime: startTime,
            endTime: endTime
        )
        let payload = CalendarTaskInlineEditorPayload(
            title: trimmedTitle,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            listID: selectedListID,
            isCompleted: isCompleted,
            schedule: schedule,
            reminderDate: hasReminder ? reminderDate : nil
        )
        onSave(task, payload)
    }
}
