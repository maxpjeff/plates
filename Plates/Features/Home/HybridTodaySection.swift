import SwiftUI
import SwiftData

struct HybridTodaySection: View {
    @Environment(\.modelContext) private var context
    @Environment(\.startHybridSession) private var startHybridSession

    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @Query private var schedules: [WeekSchedule]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Today")
                .font(PlatesFont.statLabel())

            WeekStripView(selectedDate: $selectedDate, dayLabels: weekLoadLabels)

            dayHero
            macroSummary
            timelineSection
        }
    }

    private var weekLoadLabels: [Date: DayLoadLabel] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate) else { return [:] }
        var map: [Date: DayLoadLabel] = [:]
        for offset in 0..<7 {
            guard let day = Calendar.current.date(byAdding: .day, value: offset, to: interval.start) else { continue }
            let weekday = Calendar.current.component(.weekday, from: day)
            if let schedule = schedules.first(where: { $0.weekday == weekday }),
               let label = schedule.dayLoadLabel {
                map[Calendar.current.startOfDay(for: day)] = label
            } else if let load = HybridDataStore.dayLoad(for: day, context: context) {
                map[Calendar.current.startOfDay(for: day)] = load.label
            }
        }
        return map
    }

    private var dayHero: some View {
        let load = HybridDataStore.dayLoad(for: selectedDate, context: context)
        let session = HybridDataStore.session(for: selectedDate, context: context)
        let targets = PlatesDataStore.targets(for: selectedDate, context: context)
        let eaten = PlatesDataStore.macroTotals(for: selectedDate, context: context)
        let kcalLeft = max(0, targets.kcal - Int(eaten.kcal.rounded()))

        return PlatesCard(padding: 18, style: .elevated) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    if let load {
                        DayLoadBadge(label: load.label)
                    }
                    Spacer()
                    if let start = session?.plannedStart {
                        Text(start.formatted(date: .omitted, time: .shortened))
                            .font(PlatesFont.secondary())
                            .foregroundStyle(PlatesColor.muted)
                    }
                }
                Text(session?.title ?? "Rest day")
                    .font(PlatesFont.sectionTitle(22))
                Text("\(kcalLeft.formatted()) kcal to go · \(Int(eaten.kcal)) of \(targets.kcal) eaten")
                    .font(PlatesFont.bodyMedium())
                    .foregroundStyle(PlatesColor.muted)
                if let session {
                    Text("Your day · \(session.blocks.count) blocks · ~\(session.blocks.map(\.estimatedMinutes).reduce(0, +)) min")
                        .font(PlatesFont.secondary())
                        .foregroundStyle(PlatesColor.muted)
                }
            }
        }
    }

    private var macroSummary: some View {
        let targets = PlatesDataStore.targets(for: selectedDate, context: context)
        let eaten = PlatesDataStore.macroTotals(for: selectedDate, context: context)

        return HStack(spacing: 10) {
            macroTile("Protein", eaten: eaten.protein, target: Double(targets.proteinG), unit: "g")
            macroTile("Carbs", eaten: eaten.carbs, target: Double(targets.carbsG), unit: "g")
            macroTile("Fat", eaten: eaten.fat, target: Double(targets.fatG), unit: "g")
        }
    }

    private func macroTile(_ title: String, eaten: Double, target: Double, unit: String) -> some View {
        let pct = target > 0 ? min(1, eaten / target) : 0
        return VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(PlatesFont.labelCaps(10))
                .foregroundStyle(PlatesColor.muted)
            Text("\(Int(pct * 100))%")
                .font(PlatesFont.statHero(22))
            Text("\(Int(eaten))/\(Int(target)) \(unit)")
                .font(PlatesFont.secondary(11))
                .foregroundStyle(PlatesColor.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(PlatesColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var timelineSection: some View {
        let session = HybridDataStore.session(for: selectedDate, context: context)
        let plan = PlatesDataStore.dayPlan(for: selectedDate, context: context)
        let meals = plan.plannedMeals.sorted { ($0.slotTime ?? .distantPast) < ($1.slotTime ?? .distantPast) }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Your day")
                .font(PlatesFont.sectionTitle(20))

            ForEach(meals, id: \.id) { meal in
                mealTimelineRow(meal)
            }

            if let session {
                sessionCard(session)
            }
        }
    }

    private func mealTimelineRow(_ planned: PlannedMeal) -> some View {
        let macros = PlatesDataStore.mealMacros(planned)
        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                if let t = planned.slotTime {
                    Text(t.formatted(date: .omitted, time: .shortened))
                        .font(PlatesFont.bodySemibold(13))
                }
                Text(planned.slotLabel)
                    .font(PlatesFont.labelCaps(9))
                    .foregroundStyle(PlatesColor.muted)
            }
            .frame(width: 72, alignment: .trailing)
            PlatesCard(padding: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(planned.meal?.name ?? planned.food?.name ?? "Meal")
                        .font(PlatesFont.bodySemibold())
                    Text("\(Int(macros.kcal)) kcal · P \(Int(macros.protein))g · C \(Int(macros.carbs))g · F \(Int(macros.fat))g")
                        .font(PlatesFont.secondary(11))
                        .foregroundStyle(PlatesColor.muted)
                }
            }
        }
    }

    private func sessionCard(_ session: TrainingSession) -> some View {
        PlatesCard(padding: 16, style: .elevated) {
            VStack(alignment: .leading, spacing: 12) {
                if let start = session.plannedStart {
                    Text("\(start.formatted(date: .omitted, time: .shortened)) · SESSION · \(session.blocks.count) BLOCKS · ~\(session.blocks.map(\.estimatedMinutes).reduce(0, +)) MIN")
                        .platesLabelCaps()
                }
                Text(session.title)
                    .font(PlatesFont.bodySemibold(18))
                ForEach(session.blocks.sorted { $0.order < $1.order }, id: \.id) { block in
                    blockSummary(block)
                }
                Button {
                    startHybridSession(session)
                } label: {
                    Text("Start session")
                        .font(PlatesFont.bodySemibold())
                        .foregroundStyle(PlatesColor.primaryButtonText)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(PlatesColor.primaryButton)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func blockSummary(_ block: TrainingBlock) -> some View {
        if let spec = block.items.first?.plannedSpec {
            VStack(alignment: .leading, spacing: 4) {
                Text(block.blockType.label.uppercased())
                    .font(PlatesFont.labelCaps(10))
                    .foregroundStyle(PlatesColor.accent)
                Text(blockPrescription(block.blockType, spec: spec))
                    .font(PlatesFont.secondary(12))
                    .foregroundStyle(PlatesColor.muted)
            }
        }
    }

    private func blockPrescription(_ type: HybridBlockType, spec: HybridItemSpec) -> String {
        switch type {
        case .sprint:
            return "\(spec.sprintSets ?? 1) × \(spec.distanceM ?? 0) m fly @ \(spec.intensityPct ?? 90)% · \( (spec.restSec ?? 0) / 60) min rest"
        case .plyo:
            return "\(spec.plyoDrill ?? "Drill") · \((spec.contactsPerSet ?? 0) * (spec.plyoSets ?? 1)) contacts"
        case .lift:
            return "\(spec.exerciseName ?? "Lift") \(spec.sets ?? 3) × \(spec.repsMin ?? 8)–\(spec.repsMax ?? 12)"
        case .hurdles:
            return "\(spec.hurdleReps ?? 1) × \(spec.hurdleCount ?? 5) hurdles @ \(spec.hurdleHeightIn ?? 39) in"
        case .jumps:
            return "\(spec.jumpEvent?.label ?? "Jumps") · \(spec.jumpAttempts ?? 4) attempts"
        case .run:
            return "\(spec.runKind?.rawValue.capitalized ?? "Run") · \(spec.runDistanceM.map { "\(Int($0)) m" } ?? "—")"
        case .conditioning:
            return spec.conditioningFormat ?? "Conditioning"
        }
    }
}
