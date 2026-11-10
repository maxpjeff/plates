import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var search = ""
    @State private var muscle: MuscleGroup?
    @State private var selected: Set<UUID> = []

    let onPick: ([Exercise]) -> Void

    private var filtered: [Exercise] {
        exercises.filter { ex in
            let matchesSearch = search.isEmpty || ex.name.localizedCaseInsensitiveContains(search)
            let matchesMuscle = muscle == nil || ex.primaryMuscle == muscle
            return matchesSearch && matchesMuscle
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextField("Search exercises", text: $search)
                    .padding(12)
                    .background(PlatesColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        PillChip(title: "All", isSelected: muscle == nil) { muscle = nil }
                        ForEach(MuscleGroup.allCases, id: \.self) { group in
                            PillChip(title: group.rawValue.capitalized, isSelected: muscle == group) {
                                muscle = group
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                List(filtered, id: \.id) { exercise in
                    Button {
                        toggle(exercise)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(exercise.name)
                                Text(exercise.movementPatternLabel)
                                    .font(PlatesFont.secondary())
                                    .foregroundStyle(PlatesColor.muted)
                            }
                            Spacer()
                            if selected.contains(exercise.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(PlatesColor.good)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .background(PlatesColor.bg)
            .navigationTitle("Add exercises")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let picks = exercises.filter { selected.contains($0.id) }
                        onPick(picks)
                        dismiss()
                    }
                    .disabled(selected.isEmpty)
                }
            }
        }
    }

    private func toggle(_ exercise: Exercise) {
        if selected.contains(exercise.id) {
            selected.remove(exercise.id)
        } else {
            selected.insert(exercise.id)
        }
    }
}

#Preview {
    ExercisePickerView { _ in }
        .modelContainer(SampleData.previewContainer())
}
