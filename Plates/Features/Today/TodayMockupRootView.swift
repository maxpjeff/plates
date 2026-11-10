import SwiftUI
import SwiftData

struct TodayMockupRootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.startHybridSession) private var startHybridSession
    @Query private var profiles: [UserProfile]

    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var showSettings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                MockupWeekStripExact(selectedDate: $selectedDate)
                summaryCard
                yourDayHeader
                timeline
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
        .background(MockupColors.canvas)
        .sheet(isPresented: $showSettings) {
            if let profile = profiles.first {
                SettingsView(profile: profile)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(MockupFont.body(14))
                    .foregroundStyle(MockupColors.muted)
                Text("Today")
                    .font(MockupFont.title(36))
                    .foregroundStyle(MockupColors.ink)
            }
            Spacer()
            MockupProfileAvatar(initials: initials) { showSettings = true }
        }
    }

    private var initials: String {
        let name = profiles.first?.name ?? "You"
        return String(name.prefix(1)).uppercased()
    }

    private var summaryCard: some View {
        let targets = PlatesDataStore.targets(for: selectedDate, context: context)
        let eaten = PlatesDataStore.macroTotals(for: selectedDate, context: context)
        let left = max(0, targets.kcal - Int(eaten.kcal.rounded()))
        let progress = targets.kcal > 0 ? eaten.kcal / Double(targets.kcal) : 0
        let load = HybridDataStore.dayLoad(for: selectedDate, context: context)
        let session = HybridDataStore.session(for: selectedDate, context: context)
        let time = session?.plannedStart?.formatted(date: .omitted, time: .shortened) ?? ""

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                if let load {
                    MockupHighDayPill(label: "\(load.label.title) day")
                }
                Text("\(session?.title ?? "Rest")\(time.isEmpty ? "" : " · \(time)")")
                    .font(MockupFont.body(14))
                    .foregroundStyle(MockupColors.muted)
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(left.formatted())
                        .font(MockupFont.heroNumber(44))
                    Text("kcal to go · \(Int(eaten.kcal)) of \(targets.kcal) eaten")
                        .font(MockupFont.body(14))
                        .foregroundStyle(MockupColors.muted)
                }
                Spacer()
                ZStack {
                    Circle().stroke(Color.black.opacity(0.08), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: min(1, progress))
                        .stroke(MockupColors.accentOrange, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(progress * 100))%")
                        .font(MockupFont.headline(13))
                }
                .frame(width: 64, height: 64)
            }

            HStack(spacing: 12) {
                MockupMacroProgressColumn(title: "Protein", eaten: Int(eaten.protein), target: targets.proteinG, fill: MockupColors.proteinBar)
                MockupMacroProgressColumn(title: "Carbs", eaten: Int(eaten.carbs), target: targets.carbsG, fill: MockupColors.carbsBar)
                MockupMacroProgressColumn(title: "Fat", eaten: Int(eaten.fat), target: targets.fatG, fill: MockupColors.fatBar)
            }
        }
        .padding(18)
        .background(MockupColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }

    private var yourDayHeader: some View {
        let plan = PlatesDataStore.dayPlan(for: selectedDate, context: context)
        let session = HybridDataStore.session(for: selectedDate, context: context) != nil ? 1 : 0
        return HStack {
            Text("Your day")
                .font(MockupFont.headline(18))
            Spacer()
            Text("\(plan.plannedMeals.count) meals · \(session) session")
                .font(MockupFont.body(13))
                .foregroundStyle(MockupColors.muted)
        }
    }

    private var timeline: some View {
        VStack(spacing: 0) {
            ForEach(Array(timelineItems.enumerated()), id: \.element.id) { index, item in
                timelineRow(item, isLast: index == timelineItems.count - 1)
            }
        }
    }

    private struct TimelineItem: Identifiable {
        enum Kind { case meal(PlannedMeal), session(TrainingSession) }
        let id: String
        let sortKey: Date
        let kind: Kind
    }

    private var timelineItems: [TimelineItem] {
        var items: [TimelineItem] = []
        let plan = PlatesDataStore.dayPlan(for: selectedDate, context: context)
        for meal in plan.plannedMeals {
            items.append(TimelineItem(id: meal.id.uuidString, sortKey: meal.slotTime ?? .distantFuture, kind: .meal(meal)))
        }
        if let session = HybridDataStore.session(for: selectedDate, context: context) {
            items.append(TimelineItem(id: session.id.uuidString, sortKey: session.plannedStart ?? .distantFuture, kind: .session(session)))
        }
        return items.sorted { $0.sortKey < $1.sortKey }
    }

    private func timelineRow(_ item: TimelineItem, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Text(item.sortKey.formatted(date: .omitted, time: .shortened))
                    .font(MockupFont.headline(12))
                    .foregroundStyle(MockupColors.ink)
                    .frame(width: 58, alignment: .trailing)
                if !isLast {
                    Rectangle()
                        .fill(Color.black.opacity(0.08))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.top, 8)
                }
            }
            .frame(width: 58)

            VStack {
                Circle()
                    .fill(nodeColor(item))
                    .frame(width: 10, height: 10)
                    .padding(.top, 4)
                if !isLast {
                    Spacer()
                }
            }
            .frame(width: 10)

            Group {
                switch item.kind {
                case .meal(let planned):
                    mealCard(planned)
                case .session(let session):
                    sessionCard(session)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, isLast ? 0 : 20)
        }
    }

    private func nodeColor(_ item: TimelineItem) -> Color {
        switch item.kind {
        case .session: return MockupColors.ink
        default: return MockupColors.accentOrange
        }
    }

    private func mealCard(_ planned: PlannedMeal) -> some View {
        let m = PlatesDataStore.mealMacros(planned)
        return ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                Text(planned.slotLabel.uppercased())
                    .font(MockupFont.micro(10))
                    .foregroundStyle(MockupColors.muted)
                Text(planned.meal?.name ?? planned.food?.name ?? "Meal")
                    .font(MockupFont.headline(17))
                MockupMacroPills(kcal: Int(m.kcal), protein: Int(m.protein), carbs: Int(m.carbs), fat: Int(m.fat))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(MockupColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            if planned.isEaten {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(MockupColors.accentOrange)
                    .padding(12)
            } else {
                Circle()
                    .strokeBorder(MockupColors.muted.opacity(0.4), lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .padding(12)
            }
        }
    }

    private func sessionCard(_ session: TrainingSession) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SESSION · \(session.blocks.count) BLOCKS · ~\(session.blocks.map(\.estimatedMinutes).reduce(0, +)) MIN")
                .font(MockupFont.micro(10))
                .foregroundStyle(Color.white.opacity(0.5))
            Text(session.title)
                .font(MockupFont.headline(20))
                .foregroundStyle(.white)

            ForEach(session.blocks.sorted { $0.order < $1.order }, id: \.id) { block in
                if let spec = block.items.first?.plannedSpec {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: blockIcon(block.blockType))
                            .foregroundStyle(MockupColors.accentOrange)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(block.blockType.label)
                                .font(MockupFont.headline(14))
                                .foregroundStyle(.white)
                            Text(blockDetail(block.blockType, spec: spec))
                                .font(MockupFont.body(13))
                                .foregroundStyle(Color.white.opacity(0.55))
                        }
                    }
                }
            }

            Button { startHybridSession(session) } label: {
                Text("Start session")
                    .font(MockupFont.headline(16))
                    .foregroundStyle(MockupColors.ink)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(MockupColors.accentOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(MockupColors.sessionCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func blockIcon(_ type: HybridBlockType) -> String {
        switch type {
        case .sprint: "bolt.fill"
        case .plyo: "arrow.up"
        case .lift: "dumbbell.fill"
        default: "circle.fill"
        }
    }

    private func blockDetail(_ type: HybridBlockType, spec: HybridItemSpec) -> String {
        switch type {
        case .sprint:
            return "\(spec.sprintReps ?? 4) × \(Int(spec.distanceM ?? 30)) m fly @ \(spec.intensityPct ?? 95)% · \((spec.restSec ?? 240) / 60) min rest"
        case .plyo:
            return "\(spec.plyoDrill ?? "Pogos + bounds") · \((spec.contactsPerSet ?? 30) * (spec.plyoSets ?? 2)) contacts"
        case .lift:
            return "\(spec.exerciseName ?? "Front squat") \(spec.sets ?? 4) × \(spec.repsMin ?? 3) · Nordics 3 × 5"
        default: return type.label
        }
    }
}
