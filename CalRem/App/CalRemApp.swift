import SwiftData
import SwiftUI

@main
struct CalRemApp: App {
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(persistenceController.container)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
