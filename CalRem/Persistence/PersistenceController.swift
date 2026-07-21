import Foundation
import SwiftData

@MainActor
struct PersistenceController {
    static let shared = PersistenceController()
    static let preview = PersistenceController(inMemory: true, seedPreviewData: true)

    let container: ModelContainer

    init(inMemory: Bool = false, seedPreviewData: Bool = false) {
        do {
            let schema = Schema([
                TaskList.self,
                TaskItem.self
            ])
            let configuration = ModelConfiguration(
                "CalRem",
                schema: schema,
                isStoredInMemoryOnly: inMemory
            )
            container = try ModelContainer(for: schema, configurations: [configuration])

            if seedPreviewData {
                Self.seedPreviewData(in: container.mainContext)
            }
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    static func seedDefaultListIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<TaskList>()
        let lists = (try? context.fetch(descriptor)) ?? []
        guard lists.isEmpty else { return }

        let inbox = TaskList(
            name: "Inbox",
            colorName: ListColor.blue.rawValue,
            symbolName: "tray",
            sortOrder: 0
        )
        context.insert(inbox)
        try? context.save()
    }

    static func seedExampleTasksIfNeeded(in context: ModelContext) {
        let taskDescriptor = FetchDescriptor<TaskItem>()
        let existingTasks = (try? context.fetch(taskDescriptor)) ?? []
        guard !existingTasks.contains(where: { $0.notes.contains(exampleSeedMarker) }) else { return }

        let listDescriptor = FetchDescriptor<TaskList>()
        let existingLists = (try? context.fetch(listDescriptor)) ?? []
        let routine = list(named: "Routine", color: .orange, symbolName: "sun.max", sortOrder: 1, existingLists: existingLists, context: context)
        let work = list(named: "Work", color: .indigo, symbolName: "briefcase", sortOrder: 2, existingLists: existingLists, context: context)
        let personal = list(named: "Personal", color: .green, symbolName: "person", sortOrder: 3, existingLists: existingLists, context: context)
        let home = list(named: "Home", color: .mint, symbolName: "house", sortOrder: 4, existingLists: existingLists, context: context)
        let study = list(named: "Study", color: .purple, symbolName: "graduationcap", sortOrder: 5, existingLists: existingLists, context: context)
        let errands = list(named: "Errands", color: .teal, symbolName: "cart", sortOrder: 6, existingLists: existingLists, context: context)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        insertTimedTask("Morning routine", list: routine, day: today, hour: 7, minute: 30, durationMinutes: 45, context: context)
        insertTimedTask("Breakfast and day plan", list: routine, day: today, hour: 8, minute: 30, durationMinutes: 30, context: context)
        insertTimedTask("Deep work: CalRem UX polish", list: work, day: today, hour: 9, minute: 30, durationMinutes: 90, context: context)
        insertTimedTask("Lunch walk", list: personal, day: today, hour: 12, minute: 30, durationMinutes: 45, context: context)
        insertTimedTask("Review GitHub issues", list: work, day: today, hour: 15, minute: 0, durationMinutes: 45, context: context)
        insertTimedTask("Workout and stretch", list: personal, day: today, hour: 18, minute: 30, durationMinutes: 60, context: context)
        insertTimedTask("Prepare tomorrow", list: routine, day: today, hour: 22, minute: 15, durationMinutes: 30, context: context)

        insertAllDayTask("Buy groceries", list: errands, day: today, context: context)
        insertAllDayTask("Pay internet bill", list: home, day: today, context: context)
        insertAllDayTask("Pack laptop charger", list: personal, day: tomorrow, context: context)
        insertAllDayTask("Water plants", list: home, day: yesterday, context: context)

        insertUnscheduledTask("Replace toothbrush head", list: home, context: context)
        insertUnscheduledTask("Read 10 pages", list: study, context: context)
        insertUnscheduledTask("Clean Downloads folder", list: personal, context: context)
        insertUnscheduledTask("Write three English sentences", list: study, context: context)
        insertUnscheduledTask("Order notebook refills", list: errands, context: context)

        try? context.save()
    }

    private static let exampleSeedMarker = "CalRem example seed"
    private static let recurringExampleSeedMarker = "CalRem recurring example seed"

    static func seedRecurringExamplesIfNeeded(in context: ModelContext) {
        let taskDescriptor = FetchDescriptor<TaskItem>()
        let existingTasks = (try? context.fetch(taskDescriptor)) ?? []
        guard !existingTasks.contains(where: { $0.notes.contains(recurringExampleSeedMarker) }) else { return }

        let listDescriptor = FetchDescriptor<TaskList>()
        let existingLists = (try? context.fetch(listDescriptor)) ?? []
        let routine = list(named: "Routine", color: .orange, symbolName: "sun.max", sortOrder: 1, existingLists: existingLists, context: context)
        let work = list(named: "Work", color: .indigo, symbolName: "briefcase", sortOrder: 2, existingLists: existingLists, context: context)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let friday = nextWeekday(6, from: today, calendar: calendar)

        insertTimedTask(
            "Hydrate and vitamins",
            notes: recurringExampleSeedMarker,
            list: routine,
            day: today,
            hour: 7,
            minute: 0,
            durationMinutes: 15,
            recurrenceRule: .daily,
            context: context
        )
        insertTimedTask(
            "Weekly planning review",
            notes: recurringExampleSeedMarker,
            list: work,
            day: friday,
            hour: 16,
            minute: 0,
            durationMinutes: 45,
            recurrenceRule: .weekly,
            context: context
        )

        try? context.save()
    }

    private static func seedPreviewData(in context: ModelContext) {
        let inbox = TaskList(name: "Inbox", colorName: ListColor.blue.rawValue, symbolName: "tray")
        let work = TaskList(name: "Work", colorName: ListColor.indigo.rawValue, symbolName: "briefcase", sortOrder: 1)
        let personal = TaskList(name: "Personal", colorName: ListColor.green.rawValue, symbolName: "house", sortOrder: 2)

        context.insert(inbox)
        context.insert(work)
        context.insert(personal)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let focusStart = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today) ?? .now
        let focusEnd = calendar.date(byAdding: .minute, value: 90, to: focusStart) ?? focusStart
        let reviewStart = calendar.date(bySettingHour: 15, minute: 30, second: 0, of: today) ?? .now
        let reviewEnd = calendar.date(byAdding: .minute, value: 45, to: reviewStart) ?? reviewStart

        context.insert(TaskItem(title: "Plan CalRem MVP", list: work, startDate: focusStart, endDate: focusEnd))
        context.insert(TaskItem(title: "Review calendar layout", list: work, startDate: reviewStart, endDate: reviewEnd))
        context.insert(TaskItem(title: "Buy coffee", list: personal, dueDate: today, isAllDay: true))
        try? context.save()
    }

    private static func list(
        named name: String,
        color: ListColor,
        symbolName: String,
        sortOrder: Int,
        existingLists: [TaskList],
        context: ModelContext
    ) -> TaskList {
        if let list = existingLists.first(where: { $0.name == name }) {
            return list
        }

        let list = TaskList(
            name: name,
            colorName: color.rawValue,
            symbolName: symbolName,
            sortOrder: sortOrder
        )
        context.insert(list)
        return list
    }

    private static func insertTimedTask(
        _ title: String,
        notes: String? = nil,
        list: TaskList,
        day: Date,
        hour: Int,
        minute: Int,
        durationMinutes: Int,
        recurrenceRule: TaskRecurrenceRule = .none,
        context: ModelContext,
        calendar: Calendar = .current
    ) {
        let start = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        let end = calendar.date(byAdding: .minute, value: durationMinutes, to: start) ?? start
        let taskNotes = notes ?? exampleSeedMarker
        let task = TaskItem(
            title: title,
            notes: taskNotes,
            list: list,
            dueDate: start,
            startDate: start,
            endDate: end,
            recurrenceRule: recurrenceRule
        )
        context.insert(task)
    }

    private static func nextWeekday(_ weekday: Int, from date: Date, calendar: Calendar) -> Date {
        var candidate = date

        for _ in 0..<7 {
            if calendar.component(.weekday, from: candidate) == weekday {
                return candidate
            }
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }

        return date
    }

    private static func insertAllDayTask(
        _ title: String,
        list: TaskList,
        day: Date,
        context: ModelContext,
        calendar: Calendar = .current
    ) {
        let task = TaskItem(
            title: title,
            notes: exampleSeedMarker,
            list: list,
            dueDate: calendar.startOfDay(for: day),
            isAllDay: true
        )
        context.insert(task)
    }

    private static func insertUnscheduledTask(_ title: String, list: TaskList, context: ModelContext) {
        let task = TaskItem(title: title, notes: exampleSeedMarker, list: list)
        context.insert(task)
    }
}
