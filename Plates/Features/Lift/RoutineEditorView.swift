import SwiftUI
import SwiftData

struct RoutineEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var shortLabel: String = ""
    @State private var sticker: StickerColorName = .wine
    @State private var dayType: DayType = .standard
    @State private var items: [RoutineItemDraft] = []
    @State private var showPicker = false
    @State private var editMode: EditMode = .inactive

    var existing: Routine?

    struct RoutineItemDraft: Identifiable {
        let id = UUID()
        enum Kind {
            case exercise(Exercise)
            case variation(ExerciseVariationGroup)
        }
        var kind: Kind
        var sets: Int
        var repMin: Int
        var repMax: Int
        var restSeconds: Int

        var title: String {
            switch kind {
            case .exercise(let ex): ex.name
            case .variation(let v): v.name
            }
        }

        var isRunning: Bool {
            switch kind {
            case .exercise(let ex): ex.isRunning
            case .variation: false
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextCardSticker(label: shortLabel.isEmpty ? "New" : shortLabel, color: sticker)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(PlatesColor.bg)
                    TextField("Routine name", text: $name)
                    TextField("Short label", text: $shortLabel)
                    Picker("Day type", selection: $dayType) {
                        ForEach(DayType.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                    }
                    stickerSwatches
                }
                Section {
                    ForEach($items) { $draft in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(PlatesColor.muted)
                                Text(draft.title)
                                    .font(PlatesFont.bodySemibold())
                            }
                            if draft.isRunning {
                                PrescriptionStepper(title: draft.kind.isSprint ? "Reps / efforts" : "Blocks", value: $draft.sets, range: 1...20)
                                PrescriptionStepper(title: "Min (min or m)", value: $draft.repMin, range: 1...180, step: 1)
                                PrescriptionStepper(title: "Max (min or m)", value: $draft.repMax, range: 1...180, step: 1)
                                PrescriptionStepper(title: "Rest", value: $draft.restSeconds, range: 0...600, step: 15, suffix: "s")
                            } else {
                                PrescriptionStepper(title: "Sets", value: $draft.sets, range: 1...10)
                                PrescriptionStepper(title: "Min reps", value: $draft.repMin, range: 1...30)
                                PrescriptionStepper(title: "Max reps", value: $draft.repMax, range: 1...30)
                                PrescriptionStepper(title: "Rest", value: $draft.restSeconds, range: 30...300, step: 15, suffix: "s")
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .onDelete { indexSet in
                        items.remove(atOffsets: indexSet)
                    }
                    .onMove { from, to in
                        items.move(fromOffsets: from, toOffset: to)
                    }
                    Button("Add exercise or variation") { showPicker = true }
                } header: {
                    HStack {
                        Text("Exercises")
                        Spacer()
                        EditButton()
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .scrollContentBackground(.hidden)
            .background(PlatesColor.bg)
            .navigationTitle(existing == nil ? "New routine" : "Edit routine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty || items.isEmpty)
                }
            }
            .sheet(isPresented: $showPicker) {
                RoutineExercisePickerView { exercises, variations in
                    for ex in exercises {
                        let defaults = ex.isRunning
                            ? (sets: 1, min: 30, max: 45, rest: 120)
                            : (sets: 3, min: 8, max: 12, rest: 90)
                        items.append(
                            RoutineItemDraft(
                                kind: .exercise(ex),
                                sets: defaults.sets,
                                repMin: defaults.min,
                                repMax: defaults.max,
                                restSeconds: defaults.rest
                            )
                        )
                    }
                    for v in variations {
                        items.append(RoutineItemDraft(kind: .variation(v), sets: 3, repMin: 8, repMax: 12, restSeconds: 90))
                    }
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private var stickerSwatches: some View {
        HStack {
            ForEach(StickerColorName.allCases, id: \.self) { color in
                Circle()
                    .fill(PlatesColor.sticker(color))
                    .frame(width: 32, height: 32)
                    .overlay {
                        if sticker == color {
                            Circle().strokeBorder(PlatesColor.ink, lineWidth: 2)
                        }
                    }
                    .onTapGesture { sticker = color }
            }
        }
    }

    private func loadExisting() {
        guard let existing else { return }
        name = existing.name
        shortLabel = existing.shortLabel
        sticker = existing.stickerColor
        dayType = existing.dayType
        items = existing.items.sorted { $0.order < $1.order }.compactMap { item -> RoutineItemDraft? in
            if let group = item.variationGroup {
                return RoutineItemDraft(
                    kind: .variation(group),
                    sets: item.sets,
                    repMin: item.repMin,
                    repMax: item.repMax,
                    restSeconds: item.restSeconds
                )
            }
            if let ex = item.exercise {
                return RoutineItemDraft(
                    kind: .exercise(ex),
                    sets: item.sets,
                    repMin: item.repMin,
                    repMax: item.repMax,
                    restSeconds: item.restSeconds
                )
            }
            return nil
        }
    }

    private func save() {
        let routine = existing ?? Routine(name: name, shortLabel: shortLabel)
        routine.name = name
        routine.shortLabel = shortLabel.isEmpty ? String(name.prefix(4)) : shortLabel
        routine.stickerColorRaw = sticker.rawValue
        routine.dayTypeRaw = dayType.rawValue
        routine.scheduledWeekdays = []

        if existing == nil {
            context.insert(routine)
        }

        for old in routine.items {
            context.delete(old)
        }
        routine.items.removeAll()

        for (index, draft) in items.enumerated() {
            let item: RoutineItem
            switch draft.kind {
            case .exercise(let ex):
                item = RoutineItem(exercise: ex, order: index, sets: draft.sets, repMin: draft.repMin, repMax: draft.repMax, restSeconds: draft.restSeconds)
            case .variation(let group):
                item = RoutineItem(variationGroup: group, order: index, sets: draft.sets, repMin: draft.repMin, repMax: draft.repMax, restSeconds: draft.restSeconds)
            }
            item.routine = routine
            context.insert(item)
        }

        try? context.save()
        dismiss()
    }
}

private extension RoutineEditorView.RoutineItemDraft.Kind {
    var isSprint: Bool {
        switch self {
        case .exercise(let ex):
            ex.movementPatterns.contains(.sprint) || ex.movementPatterns.contains(.intervalRun)
        case .variation: false
        }
    }
}

#Preview {
    RoutineEditorView()
        .modelContainer(SampleData.previewContainer())
}
