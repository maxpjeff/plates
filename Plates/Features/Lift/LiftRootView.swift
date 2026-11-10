import SwiftUI
import SwiftData

private enum LiftSegment: String, CaseIterable {
    case routines, exercises, history
}

struct LiftRootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.startWorkout) private var startWorkout
    @State private var segment: LiftSegment = .routines
    @State private var showEditor = false
    @State private var showLogWeight = false
    @State private var routineForActions: Routine?
    @State private var routineToEdit: Routine?
    @Query(sort: \BodyWeightEntry.date, order: .reverse) private var weights: [BodyWeightEntry]
    @Query(sort: \Routine.sortOrder) private var routines: [Routine]
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var profiles: [UserProfile]

    private var units: WeightUnit { profiles.first?.units ?? .lb }
    private var todayWeekday: Int { Calendar.current.component(.weekday, from: Date()) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    SegmentedTabs(
                        options: LiftSegment.allCases,
                        selection: $segment,
                        title: { $0.rawValue.capitalized }
                    )
                    segmentContent
                }
                .padding(.horizontal, 20)
                .padding(.top, 52)
                .padding(.bottom, 20)
            }
            .background(PlatesColor.bg)
            .navigationDestination(isPresented: $showEditor) {
                RoutineEditorView()
            }
            .sheet(item: $routineForActions) { routine in
                RoutineActionsSheet(routine: routine) {
                    routineToEdit = routine
                }
            }
            .sheet(item: $routineToEdit) { routine in
                NavigationStack {
                    RoutineEditorView(existing: routine)
                }
            }
            .sheet(isPresented: $showLogWeight) {
                LogWeightView()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading) {
                Text("Lift")
                    .font(PlatesFont.sectionTitle(28))
                Text("\(profiles.first?.trainingDaysPerWeek ?? 4) days / week")
                    .font(PlatesFont.secondary())
                    .foregroundStyle(PlatesColor.muted)
            }
            Spacer()
            Button { showEditor = true } label: {
                Image(systemName: "plus")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("New routine")
        }
    }

    @ViewBuilder
    private var segmentContent: some View {
        switch segment {
        case .routines:
            ForEach(routines, id: \.id) { routine in
                routineCard(routine)
            }
        case .exercises:
            ForEach(exercises, id: \.id) { exercise in
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name)
                        .font(PlatesFont.bodyMedium())
                    ExerciseTagsRow(
                        muscleTags: exercise.muscleDisplayTags,
                        patternTags: exercise.patternTags
                    )
                }
                .padding(.vertical, 8)
                Divider().overlay(PlatesColor.divider)
            }
        case .history:
            bodyWeightCard
            ForEach(sessions.filter { $0.endedAt != nil }.prefix(10), id: \.id) { session in
                PlatesCard(padding: 12) {
                    HStack {
                        if let sticker = session.routine?.shortLabel {
                            TextCardSticker(label: sticker, color: session.routine?.stickerColor ?? .wine, rotation: 2)
                        }
                        VStack(alignment: .leading) {
                            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                            Text("\(session.sets.count) sets logged")
                                .font(PlatesFont.secondary())
                                .foregroundStyle(PlatesColor.muted)
                        }
                    }
                }
            }
            if sessions.isEmpty {
                ContentUnavailableView("No history yet", systemImage: "clock")
            }
        }
    }

    private var bodyWeightCard: some View {
        let entries = weights.map { ($0.date, $0.weightKg) }
        let trend = TrendEngine.trendToday(entries: entries) ?? profiles.first?.resolvedBodyWeightKg ?? 79
        let rate = TrendEngine.weeklyRateKg(entries: entries)

        return PlatesCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Body weight")
                    .font(PlatesFont.bodySemibold())
                Text(UnitFormat.displayWeight(trend, units: units))
                    .font(PlatesFont.bigNumber(28))
                if let rate {
                    Text(String(format: "%+.1f kg over 7 days (trend)", rate))
                        .font(PlatesFont.secondary())
                        .foregroundStyle(PlatesColor.muted)
                }
                Button("Log today") { showLogWeight = true }
                    .font(PlatesFont.bodySemibold())
            }
        }
    }

    private func routineCard(_ routine: Routine) -> some View {
        let isToday = WeekScheduleService.routine(for: todayWeekday, context: context)?.id == routine.id
        return PlatesCard {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    routineForActions = routine
                } label: {
                    HStack(alignment: .top) {
                        TextCardSticker(label: routine.shortLabel, color: routine.stickerColor)
                        VStack(alignment: .leading) {
                            Text(routine.name)
                                .font(PlatesFont.bodySemibold(17))
                                .foregroundStyle(PlatesColor.ink)
                            Text("\(routine.items.count) exercises · \(routine.dayType.rawValue)")
                                .font(PlatesFont.secondary())
                                .foregroundStyle(PlatesColor.muted)
                            if isToday {
                                Text("TODAY")
                                    .platesLabelCaps()
                                    .foregroundStyle(PlatesColor.accent)
                            }
                        }
                        Spacer()
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(PlatesColor.muted)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    startWorkout(routine)
                } label: {
                    Text(isToday ? "Start" : "Start workout")
                        .font(PlatesFont.bodySemibold())
                        .foregroundStyle(PlatesColor.primaryButtonText)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(PlatesColor.primaryButton)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .overlay {
            if isToday {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(PlatesColor.accent, lineWidth: 2)
            }
        }
    }
}

#Preview {
    LiftRootView()
        .modelContainer(SampleData.previewContainer())
}
