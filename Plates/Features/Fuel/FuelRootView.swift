import SwiftUI
import SwiftData

private enum FuelSegment: String, CaseIterable {
    case meals, plans, groceries
}

struct FuelRootView: View {
    @Environment(\.modelContext) private var context
    @State private var segment: FuelSegment = .meals
    @State private var showSearch = false
    @State private var showNewMeal = false
    @Query(sort: \Meal.name) private var meals: [Meal]
    @Query private var profiles: [UserProfile]
    @Query private var dayPlans: [DayPlan]
    @Query private var groceryChecks: [GroceryCheck]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    FuelTodayPanel()
                    quickAdd
                    SegmentedTabs(
                        options: FuelSegment.allCases,
                        selection: $segment,
                        title: { $0.rawValue.capitalized }
                    )
                    segmentBody
                }
                .padding(.horizontal, 20)
                .padding(.top, 52)
                .padding(.bottom, 20)
            }
            .background(PlatesColor.bg)
            .sheet(isPresented: $showSearch) {
                FoodSearchView()
            }
            .sheet(isPresented: $showNewMeal) {
                PresetMealsSheet()
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Fuel")
                    .font(PlatesFont.sectionTitle(28))
                Text(goalLabel)
                    .platesLabelCaps()
            }
            Spacer()
            Button { showNewMeal = true } label: {
                Image(systemName: "plus")
                    .frame(width: 44, height: 44)
            }
        }
    }

    private var goalLabel: String {
        let goals = profiles.first?.goals ?? []
        if goals.contains(.buildMuscle) { return "Goal · Lean gain" }
        if goals.contains(.loseFat) { return "Goal · Fat loss" }
        return "Goal · Maintain"
    }

    private var targetsCard: some View {
        let training = PlatesDataStore.targets(for: Date(), context: context)
        let restDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let rest = PlatesDataStore.targets(for: restDate, context: context)

        return PlatesCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your daily targets")
                    .font(PlatesFont.bodySemibold())
                gridRow("Calories", training: training.kcal, rest: rest.kcal)
                gridRow("Protein", training: training.proteinG, rest: rest.proteinG, suffix: "g")
                gridRow("Carbs", training: training.carbsG, rest: rest.carbsG, suffix: "g")
                gridRow("Fat", training: training.fatG, rest: rest.fatG, suffix: "g")
                Text("Targets adjust each Monday when enough data is logged.")
                    .font(PlatesFont.secondary(12))
                    .foregroundStyle(PlatesColor.muted)
            }
        }
    }

    private func gridRow(_ label: String, training: Int, rest: Int, suffix: String = "") -> some View {
        HStack {
            Text(label)
                .frame(width: 80, alignment: .leading)
                .foregroundStyle(PlatesColor.muted)
            Text("\(training)\(suffix)")
                .frame(maxWidth: .infinity)
            Text("\(rest)\(suffix)")
                .frame(maxWidth: .infinity)
        }
        .font(PlatesFont.bodyMedium(13))
    }

    private var quickAdd: some View {
        HStack {
            quickButton("Search foods", icon: "magnifyingglass") { showSearch = true }
            quickButton("Scan barcode", icon: "barcode.viewfinder") { showSearch = true }
        }
    }

    private func quickButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .font(PlatesFont.secondary(11))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(PlatesColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(PlatesColor.line))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var segmentBody: some View {
        switch segment {
        case .meals:
            ForEach(meals, id: \.id) { meal in
                PlatesCard(padding: 12) {
                    HStack {
                        MealSticker()
                        VStack(alignment: .leading) {
                            HStack {
                                Text(meal.name)
                                    .font(PlatesFont.bodySemibold())
                                if meal.isFavorite {
                                    Image(systemName: "heart.fill")
                                        .foregroundStyle(PlatesColor.heart)
                                }
                            }
                            Text(mealSummary(meal))
                                .font(PlatesFont.secondary())
                                .foregroundStyle(PlatesColor.muted)
                        }
                        Spacer()
                    }
                }
            }
        case .plans:
            WeekPlanView()
        case .groceries:
            groceryList
        }
    }

    private func mealSummary(_ meal: Meal) -> String {
        var kcal = 0.0, protein = 0.0
        for ing in meal.ingredients {
            guard let f = ing.food else { continue }
            kcal += f.kcal * ing.servings
            protein += f.protein * ing.servings
        }
        return "\(Int(kcal)) kcal · \(Int(protein)) g protein"
    }

    private var groceryList: some View {
        let items = buildGroceryItems()
        return VStack(alignment: .leading, spacing: 12) {
            Text("Built from planned days this week")
                .font(PlatesFont.secondary())
                .foregroundStyle(PlatesColor.muted)
            ForEach(items) { item in
                let checked = groceryChecks.first { $0.itemKey == item.id }?.isChecked ?? false
                Button {
                    toggleGrocery(item)
                } label: {
                    HStack {
                        Image(systemName: checked ? "checkmark.square.fill" : "square")
                            .foregroundStyle(checked ? PlatesColor.good : PlatesColor.muted)
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .strikethrough(checked)
                            Text("\(item.quantityLabel) · \(item.mealNames.joined(separator: ", "))")
                                .font(PlatesFont.secondary(11))
                                .foregroundStyle(PlatesColor.muted)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func buildGroceryItems() -> [GroceryLineItem] {
        var needs: [GroceryEngine.IngredientNeed] = []
        let plans = dayPlans.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
        for plan in plans {
            for planned in plan.plannedMeals where !planned.isEaten {
                guard let meal = planned.meal else { continue }
                for ing in meal.ingredients {
                    guard let food = ing.food else { continue }
                    needs.append(
                        GroceryEngine.IngredientNeed(
                            foodID: food.id,
                            foodName: food.name,
                            aisle: food.aisle,
                            totalServings: ing.servings * planned.servings,
                            servingName: food.servingName,
                            servingGrams: food.servingGrams,
                            mealNames: [meal.name]
                        )
                    )
                }
            }
        }
        return GroceryEngine.aggregate(ingredients: needs)
    }

    private func toggleGrocery(_ item: GroceryLineItem) {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        if let existing = groceryChecks.first(where: { $0.itemKey == item.id }) {
            existing.isChecked.toggle()
        } else {
            context.insert(GroceryCheck(weekStart: weekStart, itemKey: item.id, isChecked: true))
        }
        try? context.save()
    }
}

#Preview {
    FuelRootView()
        .modelContainer(SampleData.previewContainer())
}
