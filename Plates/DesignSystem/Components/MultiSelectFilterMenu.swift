import SwiftUI

struct MultiSelectFilterMenu<Item: Identifiable & Hashable>: View where Item: CaseIterable, Item.AllCases: RandomAccessCollection {
    let title: String
    let options: [Item]
    @Binding var selection: Set<Item>
    let label: (Item) -> String

    init(title: String, options: [Item] = Array(Item.allCases), selection: Binding<Set<Item>>, label: @escaping (Item) -> String) {
        self.title = title
        self.options = options
        _selection = selection
        self.label = label
    }

    var body: some View {
        Menu {
            if !selection.isEmpty {
                Button("Clear \(title.lowercased())") { selection.removeAll() }
            }
            ForEach(options) { option in
                Button {
                    toggle(option)
                } label: {
                    HStack {
                        Text(label(option))
                        if selection.contains(option) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(menuLabel)
                    .font(PlatesFont.bodyMedium(13))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(PlatesColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(PlatesColor.line, lineWidth: 1))
        }
    }

    private var menuLabel: String {
        if selection.isEmpty { return title }
        let names = options.filter { selection.contains($0) }.map { label($0) }
        if names.count <= 2 { return names.joined(separator: ", ") }
        return "\(names.count) selected"
    }

    private func toggle(_ option: Item) {
        if selection.contains(option) { selection.remove(option) }
        else { selection.insert(option) }
    }
}

enum ExercisePickerFilters {
    static func matches(
        _ exercise: Exercise,
        search: String,
        muscles: Set<MuscleFilter>,
        patterns: Set<MovementPattern>
    ) -> Bool {
        let matchesSearch = search.isEmpty || exercise.name.localizedCaseInsensitiveContains(search)
        let matchesMuscle = muscles.isEmpty || muscles.contains { $0.matches(exercise) }
        let matchesPattern = patterns.isEmpty || !Set(exercise.movementPatterns).isDisjoint(with: patterns)
        return matchesSearch && matchesMuscle && matchesPattern
    }
}
