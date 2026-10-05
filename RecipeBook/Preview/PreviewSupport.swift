#if DEBUG
import Foundation

extension Recipe {
    /// Hand-written sample for SwiftUI previews and tests.
    static let preview = Recipe(
        id: 1,
        title: "Classic Margherita Pizza",
        summary: "Blistered crust, bright tomato sauce and creamy mozzarella.",
        emoji: "🍕",
        servings: 4,
        ingredients: [
            Ingredient("pizza dough", amount: 500, unit: "g"),
            Ingredient("crushed tomatoes", amount: 400, unit: "g"),
            Ingredient("fresh mozzarella", amount: 250, unit: "g"),
            Ingredient("fresh basil leaves"),
        ],
        instructions: [
            "Preheat the oven to 250°C.",
            "Top the dough and bake for 8–10 minutes.",
        ],
        dietaryAttributes: [.vegetarian, .nutFree]
    )
}

/// Returns a canned result, for previews of empty and error states.
struct StubRecipeService: RecipeService {
    let result: Result<[Recipe], RecipeServiceError>

    func searchRecipes(matching query: RecipeSearchQuery) async throws -> [Recipe] {
        try result.get().filter(query.matches)
    }
}
#endif
