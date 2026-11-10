import SwiftUI
import SwiftData

struct NewMealView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var ingredients: [MealIngredient] = []
    @State private var showFoodSearch = false
    @State private var tags: Set<MealTimingTag> = [.lunch]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Meal name", text: $name)
                Section("When do you eat it?") {
                    FlowTags(selection: $tags)
                }
                Section("Ingredients") {
                    ForEach(ingredients, id: \.id) { ing in
                        if let food = ing.food {
                            Text("\(food.name) · \(ing.servings, specifier: "%.1f") srv")
                        }
                    }
                    Button("Add ingredient") { showFoodSearch = true }
                }
                Section("Totals") {
                    Text("\(Int(totals.kcal)) kcal · \(Int(totals.protein)) g protein")
                }
            }
            .navigationTitle("New meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.isEmpty || ingredients.isEmpty)
                }
            }
            .sheet(isPresented: $showFoodSearch) {
                FoodSearchView(pickMode: true) { food in
                    let ing = MealIngredient(food: food, servings: 1)
                    ingredients.append(ing)
                }
            }
        }
    }

    private var totals: (kcal: Double, protein: Double) {
        var k = 0.0, p = 0.0
        for ing in ingredients {
            guard let f = ing.food else { continue }
            k += f.kcal * ing.servings
            p += f.protein * ing.servings
        }
        return (k, p)
    }

    private func save() {
        let meal = Meal(name: name, timingTags: Array(tags))
        context.insert(meal)
        for ing in ingredients {
            ing.meal = meal
            context.insert(ing)
        }
        try? context.save()
        dismiss()
    }
}

private struct FlowTags: View {
    @Binding var selection: Set<MealTimingTag>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(MealTimingTag.allCases, id: \.self) { tag in
                    PillChip(title: tag.rawValue.capitalized, isSelected: selection.contains(tag)) {
                        if selection.contains(tag) { selection.remove(tag) } else { selection.insert(tag) }
                    }
                }
            }
        }
    }
}

#Preview {
    NewMealView()
        .modelContainer(SampleData.previewContainer())
}
