import SwiftUI
import SwiftData

struct RoutineExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \ExerciseVariationGroup.name) private var variationGroups: [ExerciseVariationGroup]
    @State private var search = ""
    @State private var selectedExercises: Set<UUID> = []
    @State private var selectedVariations: Set<UUID> = []
    @State private var muscleFilters: Set<MuscleFilter> = []
    @State private var patternFilters: Set<MovementPattern> = []

    let onComplete: (_ exercises: [Exercise], _ variations: [ExerciseVariationGroup]) -> Void

    private var filteredVariations: [ExerciseVariationGroup] {
        variationGroups.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }
    }

    private var filteredExercises: [Exercise] {
        exercises.filter { ExercisePickerFilters.matches($0, search: search, muscles: muscleFilters, patterns: patternFilters) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(PlatesColor.bg)
                List {
                    if !filteredVariations.isEmpty {
                        Section("Variations") {
                            ForEach(filteredVariations, id: \.id) { group in
                                variationRow(group)
                            }
                        }
                    }
                    Section("Exercises") {
                        ForEach(filteredExercises, id: \.id) { exercise in
                            exerciseRow(exercise)
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Search")
            .navigationTitle("Add to routine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let ex = exercises.filter { selectedExercises.contains($0.id) }
                        let vars = variationGroups.filter { selectedVariations.contains($0.id) }
                        onComplete(ex, vars)
                        dismiss()
                    }
                    .disabled(selectedExercises.isEmpty && selectedVariations.isEmpty)
                }
            }
        }
    }

    private var filterBar: some View {
        HStack(spacing: 10) {
            MultiSelectFilterMenu(
                title: "Muscle",
                selection: $muscleFilters,
                label: { $0.label }
            )
            MultiSelectFilterMenu(
                title: "Movement",
                options: MovementPattern.allCases,
                selection: $patternFilters,
                label: { $0.label }
            )
        }
    }

    private func variationRow(_ group: ExerciseVariationGroup) -> some View {
        Button { toggleVariation(group) } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(PlatesFont.bodySemibold())
                    Text(group.exercises.map(\.name).joined(separator: ", "))
                        .font(PlatesFont.secondary(11))
                        .foregroundStyle(PlatesColor.muted)
                        .lineLimit(2)
                }
                Spacer()
                if selectedVariations.contains(group.id) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(PlatesColor.good)
                }
            }
        }
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        Button { toggleExercise(exercise) } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(PlatesFont.bodyMedium())
                    ExerciseTagsRow(
                        muscleTags: exercise.muscleDisplayTags,
                        patternTags: exercise.patternTags
                    )
                }
                Spacer()
                if selectedExercises.contains(exercise.id) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(PlatesColor.good)
                }
            }
        }
    }

    private func toggleExercise(_ exercise: Exercise) {
        if selectedExercises.contains(exercise.id) { selectedExercises.remove(exercise.id) }
        else { selectedExercises.insert(exercise.id) }
    }

    private func toggleVariation(_ group: ExerciseVariationGroup) {
        if selectedVariations.contains(group.id) { selectedVariations.remove(group.id) }
        else { selectedVariations.insert(group.id) }
    }
}
