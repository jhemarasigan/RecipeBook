import Foundation

/// Every optional filter the "search endpoint" understands.
///
/// An empty/`nil` field means "don't filter on this". All active filters are combined with AND.
/// Matching lives here (not in the view model or service) so the exact same rules can be
/// unit-tested without any I/O, and so a real backend could simply be sent the query instead.
struct RecipeSearchQuery: Equatable, Sendable {
    /// Free-text search over title, description and ingredient names. Every word must match.
    var keyword = ""
    /// `true` = vegetarian only, `false` = non-vegetarian only, `nil` = no preference.
    var isVegetarian: Bool?
    /// Exact number of servings the recipe makes.
    var servings: Int?
    /// Recipe must contain *all* of these ingredients.
    var includedIngredients: [String] = []
    /// Recipe must contain *none* of these ingredients.
    var excludedIngredients: [String] = []
    /// Free-text search over the cooking steps. Every word must appear somewhere in the steps.
    var instructionText = ""

    // MARK: Matching

    func matches(_ recipe: Recipe) -> Bool {
        if let isVegetarian, recipe.isVegetarian != isVegetarian { return false }
        if let servings, recipe.servings != servings { return false }

        let keywordTerms = keyword.searchTerms
        if !keywordTerms.isEmpty {
            let searchable = ([recipe.title, recipe.summary] + recipe.ingredients.map(\.name))
                .joined(separator: " ")
                .searchNormalized
            guard keywordTerms.allSatisfy({ searchable.contains($0) }) else { return false }
        }

        let ingredientNames = recipe.ingredients.map { $0.name.searchNormalized }
        for phrase in includedIngredients.compactMap(\.searchPhrase)
        where !ingredientNames.contains(where: { $0.contains(phrase) }) {
            return false
        }
        for phrase in excludedIngredients.compactMap(\.searchPhrase)
        where ingredientNames.contains(where: { $0.contains(phrase) }) {
            return false
        }

        let instructionTerms = instructionText.searchTerms
        if !instructionTerms.isEmpty {
            let steps = recipe.instructions.joined(separator: " ").searchNormalized
            guard instructionTerms.allSatisfy({ steps.contains($0) }) else { return false }
        }
        return true
    }

    // MARK: Presentation helpers

    /// A single active filter, as shown in the removable chips bar. The search-bar keyword is
    /// deliberately excluded: it already has its own clear button.
    enum Filter: Hashable, Sendable {
        case vegetarian(Bool)
        case servings(Int)
        case including(String)
        case excluding(String)
        case instructions(String)

        var title: String {
            switch self {
            case .vegetarian(let isVegetarian): isVegetarian ? "Vegetarian" : "Non-vegetarian"
            case .servings(let count): "Serves \(count)"
            case .including(let name): "With \(name)"
            case .excluding(let name): "Without \(name)"
            case .instructions(let text): "Steps: \(text)"
            }
        }
    }

    var activeFilters: [Filter] {
        var filters: [Filter] = []
        if let isVegetarian { filters.append(.vegetarian(isVegetarian)) }
        if let servings { filters.append(.servings(servings)) }
        filters += includedIngredients.map(Filter.including)
        filters += excludedIngredients.map(Filter.excluding)
        let steps = instructionText.trimmed
        if !steps.isEmpty { filters.append(.instructions(steps)) }
        return filters
    }

    mutating func remove(_ filter: Filter) {
        switch filter {
        case .vegetarian: isVegetarian = nil
        case .servings: servings = nil
        case .including(let name): includedIngredients.removeAll { $0 == name }
        case .excluding(let name): excludedIngredients.removeAll { $0 == name }
        case .instructions: instructionText = ""
        }
    }

    /// Clears every filter but keeps the search-bar keyword.
    mutating func clearFilters() {
        self = RecipeSearchQuery(keyword: keyword)
    }
}

// MARK: - String helpers

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Lowercased and diacritic-folded so "Crème Brûlée" matches "creme brulee".
    var searchNormalized: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    /// Individual words of a free-text query.
    var searchTerms: [String] {
        searchNormalized.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    /// A multi-word phrase (e.g. "olive oil") normalised for matching, or `nil` if blank.
    var searchPhrase: String? {
        let phrase = trimmed.searchNormalized
        return phrase.isEmpty ? nil : phrase
    }
}
