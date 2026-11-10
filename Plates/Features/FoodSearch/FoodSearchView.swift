import SwiftUI
import SwiftData

struct FoodSearchView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Food.name) private var foods: [Food]
    @Query(sort: \Meal.name) private var meals: [Meal]

    @State private var search = ""
    var pickMode: Bool = false
    var onPickFood: ((Food) -> Void)?

    private var filteredFoods: [Food] {
        foods.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !meals.isEmpty && search.isEmpty {
                    Section("Your meals") {
                        ForEach(meals, id: \.id) { meal in
                            Text(meal.name)
                        }
                    }
                }
                Section("Foods") {
                    ForEach(filteredFoods, id: \.id) { food in
                        Button {
                            if pickMode {
                                onPickFood?(food)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(food.name)
                                        if food.isVerified {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.caption)
                                                .foregroundStyle(PlatesColor.good)
                                        }
                                    }
                                    Text("\(food.servingName) · \(Int(food.kcal)) kcal")
                                        .font(PlatesFont.secondary())
                                        .foregroundStyle(PlatesColor.muted)
                                }
                                Spacer()
                                if pickMode {
                                    Image(systemName: "plus.circle")
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Search foods")
            .navigationTitle("Search")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    FoodSearchView()
        .modelContainer(SampleData.previewContainer())
}
