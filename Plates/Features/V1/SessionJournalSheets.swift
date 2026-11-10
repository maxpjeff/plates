import SwiftUI

struct LogSessionPlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Log session")
                    .font(InterFont.inter(20, .heavy))
                Spacer()
            }
            .padding()
            .navigationTitle("Log session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct BeforeJournalPlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("Goals & notes")
                .font(InterFont.inter(15, .medium))
                .foregroundStyle(DesignSystem.Color.inkSecondary)
                .navigationTitle("Before")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
        }
    }
}

struct ReflectJournalPlaceholderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feel = 3
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Feel") {
                    Picker("Rating", selection: $feel) {
                        ForEach(1...5, id: \.self) { Text("\($0)").tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Reflection") {
                    TextField("How did it go?", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Reflect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { dismiss() }
                }
            }
        }
    }
}
