import Foundation
import Testing
@testable import RecipeBook

@Suite("Mock recipe service")
struct MockRecipeServiceTests {
    @Test func bundledJSONDecodesAndHasUniqueIDs() async throws {
        let service = MockRecipeService(latency: .zero)
        let recipes = try await service.searchRecipes(matching: RecipeSearchQuery())
        #expect(!recipes.isEmpty)
        #expect(Set(recipes.map(\.id)).count == recipes.count)
    }

    @Test func serviceAppliesTheQuery() async throws {
        let service = MockRecipeService(latency: .zero)
        let recipes = try await service.searchRecipes(matching: RecipeSearchQuery(isVegetarian: true))
        #expect(!recipes.isEmpty)
        #expect(recipes.allSatisfy(\.isVegetarian))
    }

    @Test func missingResourceSurfacesAsError() async {
        let service = MockRecipeService(latency: .zero) {
            throw RecipeServiceError.resourceNotFound(name: "recipes.json")
        }
        await #expect(throws: RecipeServiceError.self) {
            try await service.searchRecipes(matching: RecipeSearchQuery())
        }
    }

    @Test func malformedJSONSurfacesAsDecodingError() async {
        let service = MockRecipeService(latency: .zero) { Data("not json".utf8) }
        await #expect(throws: RecipeServiceError.self) {
            try await service.searchRecipes(matching: RecipeSearchQuery())
        }
    }
}

@Suite("Recipe decoding")
struct RecipeDecodingTests {
    private func json(servings: Int = 2, attributes: String = #"["vegan"]"#) -> Data {
        Data("""
        {"id":1,"title":"T","description":"D","servings":\(servings),
         "ingredients":[{"name":"salt"}],"instructions":["Mix"],
         "dietary_attributes":\(attributes)}
        """.utf8)
    }

    @Test func mapsAPIKeys() throws {
        let recipe = try JSONDecoder().decode(Recipe.self, from: json())
        #expect(recipe.summary == "D")
        #expect(recipe.dietaryAttributes == [.vegan])
        #expect(recipe.ingredients.first?.amount == nil)
    }

    @Test func unknownDietaryAttributesAreIgnored() throws {
        let recipe = try JSONDecoder().decode(Recipe.self, from: json(attributes: #"["vegan","kosher"]"#))
        #expect(recipe.dietaryAttributes == [.vegan])
    }

    @Test func nonPositiveServingsAreRejected() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Recipe.self, from: json(servings: 0))
        }
    }

    @Test func ingredientAmountFormatting() {
        let flour = Ingredient("flour", amount: 250, unit: "g")
        #expect(flour.displayAmount() == "250 g")
        #expect(flour.displayAmount(scale: 0.5) == "125 g")
        #expect(Ingredient("eggs", amount: 2).displayAmount() == "2")
        #expect(Ingredient("salt").displayAmount() == nil)
    }
}
