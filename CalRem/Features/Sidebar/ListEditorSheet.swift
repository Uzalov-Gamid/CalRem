import SwiftUI

struct ListEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let list: TaskList

    @State private var name: String
    @State private var color: ListColor
    @State private var symbolName: String

    init(list: TaskList) {
        self.list = list
        _name = State(initialValue: list.name)
        _color = State(initialValue: ListColor.named(list.colorName))
        _symbolName = State(initialValue: list.symbolName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Edit List")
                .font(.title2.weight(.semibold))

            Form {
                TextField("Name", text: $name)

                Picker("Color", selection: $color) {
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

                Picker("Icon", selection: $symbolName) {
                    Label("List", systemImage: "list.bullet").tag("list.bullet")
                    Label("Inbox", systemImage: "tray").tag("tray")
                    Label("Work", systemImage: "briefcase").tag("briefcase")
                    Label("Home", systemImage: "house").tag("house")
                    Label("Star", systemImage: "star").tag("star")
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .buttonStyle(CalRemPillButtonStyle())
                Button("Save") {
                    save()
                }
                .buttonStyle(CalRemPillButtonStyle(isProminent: true))
                .keyboardShortcut(.defaultAction)
                .disabled(trimmedName.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 380, height: 320)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        list.name = trimmedName
        list.colorName = color.rawValue
        list.symbolName = symbolName
        list.touch()
        try? modelContext.save()
        dismiss()
    }
}
