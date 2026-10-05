import Foundation

/// A `RecipeService` that behaves like a remote API but is backed by `recipes.json` in the app bundle.
///
/// - Decodes the same envelope a real endpoint would return and caches it after the first load.
/// - Applies the query server-side style (inside the service), not in the UI.
/// - Simulates network latency so loading states are real and cancellation is exercised.
/// - The data source is injectable so tests can simulate missing or malformed payloads.
actor MockRecipeService: RecipeService {
    typealias DataLoader = @Sendable () throws -> Data

    private let loadData: DataLoader
    private let latency: Duration
    private var cachedRecipes: [Recipe]?

    init(
        latency: Duration = .milliseconds(250),
        loadData: @escaping DataLoader = { try MockRecipeService.bundledRecipesData() }
    ) {
        self.latency = latency
        self.loadData = loadData
    }

    func searchRecipes(matching query: RecipeSearchQuery) async throws -> [Recipe] {
        if latency > .zero {
            try await Task.sleep(for: latency) // Throws CancellationError if the caller moved on.
        }
        return try allRecipes().filter(query.matches)
    }

    // MARK: Private

    private func allRecipes() throws -> [Recipe] {
        if let cachedRecipes { return cachedRecipes }
        let data = try loadData()
        do {
            let response = try JSONDecoder().decode(RecipeListResponse.self, from: data)
            cachedRecipes = response.recipes
            return response.recipes
        } catch {
            throw RecipeServiceError.decodingFailed(details: String(describing: error))
        }
    }

    static func bundledRecipesData() throws -> Data {
        guard let url = Bundle.main.url(forResource: "recipes", withExtension: "json") else {
            throw RecipeServiceError.resourceNotFound(name: "recipes.json")
        }
        return try Data(contentsOf: url)
    }
}
