import SwiftUI
import SwiftData
import UIKit

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    let routine: Routine

    @State private var session: WorkoutSession?
    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer?
    @State private var restRemaining: Int = 0
    @State private var restTimer: Timer?
    @State private var showFinish = false
    @State private var prCount = 0
    /// Routine item id → chosen exercise id for variation slots.
    @State private var variationPick: [UUID: UUID] = [:]

    private var units: WeightUnit { profiles.first?.units ?? .lb }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(sortedItems, id: \.id) { item in
                        exerciseCard(item)
                    }
                }
                .padding(20)
            }
            .background(PlatesColor.bg)
            .navigationTitle(routine.name)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(formatElapsed(elapsed))
                        .font(PlatesFont.bodySemibold())
                        .monospacedDigit()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Finish") { finishWorkout() }
                        .font(PlatesFont.bodySemibold())
                }
            }
            .onAppear { startSession() }
            .onDisappear { timer?.invalidate(); restTimer?.invalidate() }
            .sheet(isPresented: $showFinish) {
                WorkoutFinishView(
                    duration: elapsed,
                    setCount: session?.sets.filter { $0.completedAt != nil }.count ?? 0,
                    prCount: prCount
                ) {
                    dismiss()
                }
            }
            .safeAreaInset(edge: .bottom) {
                if restRemaining > 0 {
                    restBar
                }
            }
        }
    }

    private var sortedItems: [RoutineItem] {
        routine.items.sorted { $0.order < $1.order }
    }

    private func exerciseCard(_ item: RoutineItem) -> some View {
        let exercise = resolvedExercise(for: item)
        let target = progressionTarget(for: item)

        return PlatesCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(item.displayTitle)
                    .font(PlatesFont.bodySemibold(17))
                if let group = item.variationGroup, !group.exercises.isEmpty {
                    Menu {
                        ForEach(group.exercises, id: \.id) { option in
                            Button(option.name) { variationPick[item.id] = option.id }
                        }
                    } label: {
                        HStack {
                            Text("Today: \(exercise?.name ?? "Pick variation")")
                                .font(PlatesFont.bodyMedium(14))
                            Image(systemName: "chevron.down")
                        }
                        .foregroundStyle(PlatesColor.accent)
                    }
                }
                Text(target.note)
                    .font(PlatesFont.secondary())
                    .foregroundStyle(PlatesColor.muted)
                Text(ProgressionEngine.formatSetTarget(
                    weightKg: target.weightKg,
                    sets: item.sets,
                    repMin: item.repMin,
                    repMax: item.repMax,
                    units: units
                ))
                .font(PlatesFont.bodyMedium())

                let isRun = exercise?.isRunning ?? false
                ForEach(0..<item.sets, id: \.self) { index in
                    SetLogRow(
                        setNumber: index + 1,
                        targetWeightKg: target.weightKg,
                        targetReps: item.repMax,
                        units: units,
                        isRunning: isRun,
                        existing: setLog(for: item, index: index)
                    ) { weightKg, reps in
                        logSet(item: item, index: index, weightKg: weightKg, reps: reps)
                    }
                }
            }
        }
    }

    private var restBar: some View {
        VStack(spacing: 8) {
            Text("Rest \(restRemaining)s")
                .font(PlatesFont.bodySemibold())
            HStack {
                Button("−15s") { restRemaining = max(0, restRemaining - 15) }
                Spacer()
                Button("Skip") { restRemaining = 0; restTimer?.invalidate() }
                Spacer()
                Button("+15s") { restRemaining += 15 }
            }
            .font(PlatesFont.bodyMedium())
        }
        .padding()
        .background(PlatesColor.surface)
    }

    private func startSession() {
        let s = WorkoutSession(routine: routine, date: Date(), startedAt: Date())
        context.insert(s)
        session = s
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsed += 1
        }
    }

    private func resolvedExercise(for item: RoutineItem) -> Exercise? {
        if let ex = item.exercise { return ex }
        guard let group = item.variationGroup else { return nil }
        if let pick = variationPick[item.id],
           let match = group.exercises.first(where: { $0.id == pick }) {
            return match
        }
        return group.exercises.first
    }

    private func setLog(for item: RoutineItem, index: Int) -> SetLog? {
        guard let exercise = resolvedExercise(for: item) else { return nil }
        return session?.sets.first { $0.exercise?.id == exercise.id && $0.setIndex == index }
    }

    private func logSet(item: RoutineItem, index: Int, weightKg: Double, reps: Int) {
        guard let session, let exercise = resolvedExercise(for: item) else { return }
        let log: SetLog
        if let existing = setLog(for: item, index: index) {
            log = existing
            log.weightKg = weightKg
            log.reps = reps
            log.completedAt = Date()
        } else {
            log = SetLog(exercise: exercise, setIndex: index, weightKg: weightKg, reps: reps, completedAt: Date())
            log.session = session
            context.insert(log)
            session.sets.append(log)
        }

        if let e1rm = ProgressionEngine.estimatedOneRepMaxKg(weightKg: weightKg, reps: reps) {
            let history = priorBestE1RM(exercise: exercise)
            if ProgressionEngine.isPROneRepMax(newEstimate: e1rm, previousBest: history) {
                log.isPR = true
                prCount += 1
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }

        try? context.save()
        startRest(seconds: item.restSeconds)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func priorBestE1RM(exercise: Exercise) -> Double? {
        let descriptor = FetchDescriptor<SetLog>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all
            .filter { $0.exercise?.id == exercise.id && !$0.isWarmup }
            .compactMap { ProgressionEngine.estimatedOneRepMaxKg(weightKg: $0.weightKg, reps: $0.reps) }
            .max()
    }

    private func progressionTarget(for item: RoutineItem) -> ProgressionTarget {
        let exercise = resolvedExercise(for: item)
        let lastWeight = exercise.map { lastWeightForExercise($0) } ?? 40
        return ProgressionEngine.nextTarget(
            repMin: item.repMin,
            repMax: item.repMax,
            lastSession: lastPerformance(for: exercise),
            priorSession: priorPerformance(for: exercise),
            lastWeightKg: lastWeight,
            isLowerBody: exercise?.isLowerBody ?? false,
            units: units,
            isDeloadWeek: false
        )
    }

    private func lastWeightForExercise(_ exercise: Exercise) -> Double {
        let logs = (try? context.fetch(FetchDescriptor<SetLog>())) ?? []
        return logs.filter { $0.exercise?.id == exercise.id }.last?.weightKg ?? 40
    }

    private func lastPerformance(for exercise: Exercise?) -> SessionPerformance? {
        performance(for: exercise, offset: 0)
    }

    private func priorPerformance(for exercise: Exercise?) -> SessionPerformance? {
        performance(for: exercise, offset: 1)
    }

    private func performance(for exercise: Exercise?, offset: Int) -> SessionPerformance? {
        guard let exercise else { return nil }
        let sessions = (try? context.fetch(FetchDescriptor<WorkoutSession>()))?
            .filter { $0.endedAt != nil }
            .sorted { ($0.endedAt ?? .distantPast) > ($1.endedAt ?? .distantPast) } ?? []
        guard sessions.count > offset else { return nil }
        let sets = sessions[offset].sets.filter { $0.exercise?.id == exercise.id }
        return SessionPerformance(sets: sets.map { SetPerformance(weightKg: $0.weightKg, reps: $0.reps, isWarmup: $0.isWarmup) })
    }

    private func startRest(seconds: Int) {
        restRemaining = seconds
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if restRemaining <= 1 {
                restRemaining = 0
                t.invalidate()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                restRemaining -= 1
            }
        }
    }

    private func finishWorkout() {
        session?.endedAt = Date()
        try? context.save()
        timer?.invalidate()
        showFinish = true
    }

    private func formatElapsed(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        return String(format: "%d:%02d", m, s)
    }
}

private struct SetLogRow: View {
    let setNumber: Int
    let targetWeightKg: Double
    let targetReps: Int
    let units: WeightUnit
    var isRunning: Bool = false
    let existing: SetLog?
    let onLog: (Double, Int) -> Void

    @State private var weightText: String = ""
    @State private var repsText: String = ""

    var body: some View {
        HStack(spacing: 8) {
            Text("\(setNumber)")
                .frame(width: 24)
                .foregroundStyle(PlatesColor.muted)
            if !isRunning {
                TextField("Wt", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 64)
                    .padding(8)
                    .background(PlatesColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            TextField(isRunning ? "Min/m" : "Reps", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: isRunning ? 72 : 48)
                .padding(8)
                .background(PlatesColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Button {
                let kg = UnitFormat.parseWeightInput(weightText, units: units) ?? targetWeightKg
                let reps = Int(repsText) ?? targetReps
                onLog(kg, reps)
            } label: {
                Image(systemName: existing?.completedAt != nil ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(existing?.completedAt != nil ? PlatesColor.good : PlatesColor.muted)
                    .frame(width: 44, height: 44)
            }
        }
        .onAppear {
            if !isRunning, weightText.isEmpty {
                weightText = displayWeight(targetWeightKg)
            }
            if repsText.isEmpty {
                repsText = "\(targetReps)"
            }
        }
    }

    private func displayWeight(_ kg: Double) -> String {
        switch units {
        case .kg: return String(format: "%.1f", kg)
        case .lb: return String(format: "%.0f", kg / 0.453592)
        }
    }
}

#Preview {
    ActiveWorkoutView(routine: Routine(name: "Pull", shortLabel: "Pull"))
        .modelContainer(SampleData.previewContainer())
}
