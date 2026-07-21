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
}
