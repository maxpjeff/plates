import SwiftUI
import SwiftData

struct PresetMealTemplate: Identifiable {
    let id = UUID()
    let name: String
    let timing: [MealTimingTag]
    let kcal: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let isFavorite: Bool
}

enum PresetMealLibrary {
    static let all: [PresetMealTemplate] = [
        PresetMealTemplate(name: "Oats & berries bowl", timing: [.breakfast], kcal: 420, protein: 18, carbs: 62, fat: 12, isFavorite: true),
        PresetMealTemplate(name: "Greek yogurt parfait", timing: [.breakfast, .snack], kcal: 310, protein: 28, carbs: 35, fat: 6, isFavorite: true),
        PresetMealTemplate(name: "Pre-lift banana & honey", timing: [.pre], kcal: 180, protein: 2, carbs: 42, fat: 1, isFavorite: false),
        PresetMealTemplate(name: "Post-workout chicken & rice", timing: [.post, .lunch], kcal: 620, protein: 52, carbs: 68, fat: 12, isFavorite: true),
        PresetMealTemplate(name: "Turkey & avocado wrap", timing: [.lunch], kcal: 540, protein: 38, carbs: 44, fat: 22, isFavorite: false),
        PresetMealTemplate(name: "Protein shake", timing: [.post, .snack], kcal: 220, protein: 40, carbs: 8, fat: 3, isFavorite: true),
        PresetMealTemplate(name: "Salmon, rice & greens", timing: [.dinner], kcal: 580, protein: 45, carbs: 48, fat: 18, isFavorite: true),
        PresetMealTemplate(name: "Cottage cheese & fruit", timing: [.snack], kcal: 260, protein: 24, carbs: 28, fat: 5, isFavorite: false),
    ]
}

struct PresetMealsSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var addToToday: Bool = true

    var body: some View {
        NavigationStack {
            List(PresetMealLibrary.all) { preset in
                Button {
                    add(preset)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        MealSticker()
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.name)
                                .font(PlatesFont.bodySemibold())
                                .foregroundStyle(PlatesColor.ink)
                            Text("\(preset.kcal) kcal · \(preset.protein) g protein · \(preset.carbs) g carbs")
                                .font(PlatesFont.secondary())
                                .foregroundStyle(PlatesColor.muted)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add a meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func add(_ preset: PresetMealTemplate) {
        let food = Food(
            name: preset.name,
            servingName: "1 meal",
            servingGrams: 100,
            kcal: Double(preset.kcal),
            protein: Double(preset.protein),
            carbs: Double(preset.carbs),
            fat: Double(preset.fat),
            source: .user,
            isVerified: false,
            aisle: .other
        )
        context.insert(food)

        let meal = Meal(name: preset.name, timingTags: preset.timing, isFavorite: preset.isFavorite)
        context.insert(meal)
        let ing = MealIngredient(food: food, servings: 1)
        ing.meal = meal
        context.insert(ing)

        if addToToday {
            let plan = PlatesDataStore.dayPlan(for: Date(), context: context)
            let label = preset.timing.first?.rawValue.capitalized ?? "Meal"
            let planned = PlannedMeal(meal: meal, servings: 1, slotLabel: label, isEaten: false)
            planned.dayPlan = plan
            context.insert(planned)
        }

        try? context.save()
        dismiss()
    }
}

#Preview {
    PresetMealsSheet()
        .modelContainer(SampleData.previewContainer())
}
