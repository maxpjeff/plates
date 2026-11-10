import SwiftUI
import SwiftData

struct FuelMockupRootView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var showSearch = false
    @Query private var profiles: [UserProfile]
    @Query private var schedules: [WeekSchedule]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MockupLayout.sectionSpacing) {
                header
                MockupWeekStrip(selectedDate: $selectedDate)
                fuelContextLine
                calorieBlock
                MockupMacroFuelRows(
                    proteinEaten: Int(eaten.protein),
                    proteinTarget: targets.proteinG,
                    carbsEaten: Int(eaten.carbs),
                    carbsTarget: targets.carbsG,
                    fatEaten: Int(eaten.fat),
                    fatTarget: targets.fatG
                )
                gapCard
                quickActions
                foodList
            }
            .padding(.horizontal, MockupLayout.screenPadding)
            .padding(.top, 52)
            .padding(.bottom, 24)
        }
        .background(PlatesColor.bg)
        .overlay(alignment: .topTrailing) {
            ThemeToggleButton()
                .padding(.top, 8)
                .padding(.trailing, MockupLayout.screenPadding)
        }
        .sheet(isPresented: $showSearch) {
            FoodSearchView()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(goalLabel)
                .font(PlatesFont.secondary(14))
                .foregroundStyle(PlatesColor.muted)
            Text("Fuel")
                .font(PlatesFont.screenTitle(36))
        }
    }

    private var goalLabel: String {
        let goals = profiles.first?.goals ?? []
        if goals.contains(.buildMuscle) { return "Goal · Lean gain" }
        if goals.contains(.loseFat) { return "Goal · Fat loss" }
        return "Goal · Maintain"
    }

    private var load: DayLoadSnapshot? {
        HybridDataStore.dayLoad(for: selectedDate, context: context)
    }

    private var fuelContextLine: some View {
        Text("Fuel \(load?.label.title ?? "Rest") day")
            .font(PlatesFont.bodySemibold(16))
    }

    private var targets: DailyTargetsResult {
        PlatesDataStore.targets(for: selectedDate, context: context)
    }

    private var eaten: (kcal: Double, protein: Double, carbs: Double, fat: Double) {
        PlatesDataStore.macroTotals(for: selectedDate, context: context)
    }

    private var breakdown: (baseKcal: Int, sessionBonus: Int, totalKcal: Int) {
        PlatesDataStore.fuelBreakdown(for: selectedDate, context: context)
    }

    private var calorieBlock: some View {
        MockupFuelCalorieBlock(
            eaten: Int(eaten.kcal.rounded()),
            target: targets.kcal,
            base: breakdown.baseKcal,
            sessionBonus: breakdown.sessionBonus,
            left: max(0, targets.kcal - Int(eaten.kcal.rounded()))
        )
    }

    @ViewBuilder
    private var gapCard: some View {
        if let gap = PlatesDataStore.fuelGap(for: selectedDate, context: context) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Plan is \(gap.gap) kcal short")
                    .font(PlatesFont.bodySemibold(16))
                Text("Add a banana to your 4:30 snack (+105 kcal)")
                    .font(PlatesFont.secondary(14))
                    .foregroundStyle(PlatesColor.muted)
                Button("Add") {
                    showSearch = true
                }
                .font(PlatesFont.bodySemibold())
                .foregroundStyle(PlatesColor.accent)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PlatesColor.soft.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: MockupLayout.cardRadius))
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            mockupAction("Search foods", icon: "magnifyingglass") { showSearch = true }
            mockupAction("Scan barcode", icon: "barcode.viewfinder") { showSearch = true }
        }
    }

    private func mockupAction(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(PlatesFont.bodySemibold(14))
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(PlatesColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(PlatesColor.line))
        }
        .buttonStyle(.plain)
    }

    private var foodList: some View {
        let plan = PlatesDataStore.dayPlan(for: selectedDate, context: context)
        let sorted = plan.plannedMeals.sorted { ($0.slotTime ?? .distantPast) < ($1.slotTime ?? .distantPast) }
        let eatenCount = sorted.filter(\.isEaten).count

        return VStack(alignment: .leading, spacing: 14) {
            Text("Today's food \(eatenCount) eaten · \(sorted.count - eatenCount) planned")
                .font(PlatesFont.bodySemibold(16))

            ForEach(sorted, id: \.id) { planned in
                foodRow(planned)
                Divider().overlay(PlatesColor.divider)
            }
        }
    }

    private func foodRow(_ planned: PlannedMeal) -> some View {
        let m = PlatesDataStore.mealMacros(planned)
        let name = planned.meal?.name ?? planned.food?.name ?? "Meal"
        let plannedSuffix = planned.isEaten ? "" : " · planned"
        let time = planned.slotTime?.formatted(date: .omitted, time: .shortened) ?? ""

        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(name)\(plannedSuffix)")
                    .font(PlatesFont.bodySemibold(15))
                Text("P \(Int(m.protein))g  C \(Int(m.carbs))g  F \(Int(m.fat))g")
                    .font(PlatesFont.secondary(12))
                    .foregroundStyle(PlatesColor.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(m.kcal))")
                    .font(PlatesFont.bodySemibold(18))
                Text(time)
                    .font(PlatesFont.secondary(12))
                    .foregroundStyle(PlatesColor.muted)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FuelMockupRootView()
        .modelContainer(SampleData.previewContainer())
        .environmentObject(AppAppearance.shared)
}
