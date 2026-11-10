import Foundation

enum GroceryEngine {
    struct IngredientNeed: Equatable {
        let foodID: UUID
        let foodName: String
        let aisle: GroceryAisle
        let totalServings: Double
        let servingName: String
        let servingGrams: Double
        let mealNames: [String]
    }

    static func aggregate(ingredients: [IngredientNeed]) -> [GroceryLineItem] {
        var map: [UUID: (IngredientNeed, Set<String>)] = [:]
        for item in ingredients {
            if var existing = map[item.foodID] {
                existing.0 = IngredientNeed(
                    foodID: item.foodID,
                    foodName: item.foodName,
                    aisle: item.aisle,
                    totalServings: existing.0.totalServings + item.totalServings,
                    servingName: item.servingName,
                    servingGrams: item.servingGrams,
                    mealNames: []
                )
                item.mealNames.forEach { existing.1.insert($0) }
                map[item.foodID] = existing
            } else {
                map[item.foodID] = (item, Set(item.mealNames))
            }
        }

        return map.values.map { need, meals in
            let qty = quantityLabel(servings: need.totalServings, servingName: need.servingName, grams: need.servingGrams)
            return GroceryLineItem(
                itemKey: need.foodID.uuidString,
                name: need.foodName,
                quantityLabel: qty,
                aisle: need.aisle,
                mealNames: meals.sorted()
            )
        }
        .sorted { $0.aisle.rawValue < $1.aisle.rawValue }
    }

    static func quantityLabel(servings: Double, servingName: String, grams: Double) -> String {
        if servings.rounded() == servings {
            return "\(Int(servings)) × \(servingName)"
        }
        let totalG = servings * grams
        if totalG >= 454 {
            return String(format: "%.1f lb", totalG / 453.592)
        }
        return String(format: "%.0f g", totalG)
    }
}
