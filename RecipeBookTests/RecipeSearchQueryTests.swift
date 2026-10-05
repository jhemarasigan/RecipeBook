import Foundation
import Testing
@testable import RecipeBook

@Suite("Recipe search rules")
struct RecipeSearchQueryTests {
    private static func recipe(
        _ id: Int,
        _ title: String,
        servings: Int = 4,
        ingredients: [String] = [],
        steps: [String] = [],
        attributes: Set<DietaryAttribute> = []
    ) -> Recipe {
        Recipe(
            id: id, title: title, summary: "", servings: servings,
            ingredients: ingredients.map { Ingredient($0) },
            instructions: steps, dietaryAttributes: attributes
        )
    }

    private let recipes = [
        recipe(1, "Tomato Soup", servings: 4,
               ingredients: ["tomatoes", "onion", "vegetable stock"],
               steps: ["Simmer gently for 20 minutes", "Blend until smooth"],
               attributes: [.vegan]),
        recipe(2, "Cheese Omelette", servings: 1,
               ingredients: ["eggs", "cheddar cheese"],
               steps: ["Whisk the eggs", "Fry until set"],
               attributes: [.vegetarian]),
        recipe(3, "Beef Stew", servings: 6,
               ingredients: ["beef", "onion", "carrots"],
               steps: ["Brown the beef", "Simmer for 2 hours"]),
        recipe(4, "Crème Brûlée", servings: 4,
               ingredients: ["cream", "egg yolks", "sugar"],
               steps: ["Bake in a water bath"],
               attributes: [.vegetarian]),
    ]

    private func ids(_ query: RecipeSearchQuery) -> [Int] {
        recipes.filter(query.matches).map(\.id)
    }

    @Test func emptyQueryMatchesEverything() {
        #expect(ids(RecipeSearchQuery()) == [1, 2, 3, 4])
    }

    @Test func vegetarianFilterTreatsVeganAsVegetarian() {
        #expect(ids(RecipeSearchQuery(isVegetarian: true)) == [1, 2, 4])
        #expect(ids(RecipeSearchQuery(isVegetarian: false)) == [3])
    }

    @Test func servingsFilterIsExact() {
        #expect(ids(RecipeSearchQuery(servings: 4)) == [1, 4])
        #expect(ids(RecipeSearchQuery(servings: 5)).isEmpty)
    }

    @Test func includedIngredientsMustAllBePresent() {
        #expect(ids(RecipeSearchQuery(includedIngredients: ["onion"])) == [1, 3])
        #expect(ids(RecipeSearchQuery(includedIngredients: ["onion", "carrot"])) == [3])
    }

    @Test func excludedIngredientsRemoveAnyMatch() {
        #expect(ids(RecipeSearchQuery(excludedIngredients: ["onion"])) == [2, 4])
        #expect(ids(RecipeSearchQuery(excludedIngredients: ["onion", "egg"])) == [])
    }

    @Test func instructionSearchRequiresEveryWord() {
        #expect(ids(RecipeSearchQuery(instructionText: "simmer")) == [1, 3])
        #expect(ids(RecipeSearchQuery(instructionText: "simmer hours")) == [3])
    }

    @Test func keywordSearchCoversTitleAndIngredients() {
        #expect(ids(RecipeSearchQuery(keyword: "EGG")) == [2, 4])
        #expect(ids(RecipeSearchQuery(keyword: "stew")) == [3])
    }

    @Test func searchIgnoresCaseAndDiacritics() {
        #expect(ids(RecipeSearchQuery(keyword: "creme brulee")) == [4])
    }

    @Test func filtersCombineWithAnd() {
        let query = RecipeSearchQuery(isVegetarian: true, excludedIngredients: ["egg"])
        #expect(ids(query) == [1])
    }

    @Test func blankIngredientEntriesAreIgnored() {
        #expect(ids(RecipeSearchQuery(includedIngredients: ["  "], excludedIngredients: [""])) == [1, 2, 3, 4])
    }

    @Test func activeFiltersExcludeKeywordAndCanBeRemoved() {
        var query = RecipeSearchQuery(keyword: "soup", isVegetarian: true, includedIngredients: ["onion"])
        #expect(query.activeFilters == [.vegetarian(true), .including("onion")])
        query.remove(.including("onion"))
        #expect(query.activeFilters == [.vegetarian(true)])
        query.clearFilters()
        #expect(query.activeFilters.isEmpty)
        #expect(query.keyword == "soup")
    }
}
