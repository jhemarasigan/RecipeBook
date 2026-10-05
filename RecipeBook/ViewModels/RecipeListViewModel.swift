import Foundation
import Observation

/// Drives the recipe list: owns the current query and the results for it.
///
/// The view re-runs `search()` whenever `query` changes using `.task(id:)`, so SwiftUI cancels
/// the in-flight search automatically when the user keeps typing. `search()` debounces
/// itself, which avoids hitting the service on every keystroke.
@MainActor
@Observable
final class RecipeListViewModel {
    var query = RecipeSearchQuery()

    private(set) var recipes: [Recipe] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let service: any RecipeService
    private let debounce: Duration
    private var hasSearched = false

    init(service: any RecipeService, debounce: Duration = .milliseconds(300)) {
        self.service = service
        self.debounce = debounce
    }

    var hasActiveFilters: Bool { !query.activeFilters.isEmpty }

    /// Loads recipes for the current `query`. Safe to cancel at any point.
    func search() async {
        // The very first load should be immediate; later ones are debounced.
        if hasSearched {
            do { try await Task.sleep(for: debounce) } catch { return }
        }
        hasSearched = true

        isLoading = true
        errorMessage = nil
        // A cancelled search was superseded by a newer one, which now owns `isLoading`.
        defer { if !Task.isCancelled { isLoading = false } }

        do {
            let results = try await service.searchRecipes(matching: query)
            guard !Task.isCancelled else { return }
            recipes = results
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            recipes = []
            errorMessage = error.localizedDescription
        }
    }
}
