import SwiftUI

@main
struct RecipeBookApp: App {
    var body: some Scene {
        WindowGroup {
            // Composition root: the only place that knows which `RecipeService` is in use.
            RecipeListView(viewModel: RecipeListViewModel(service: MockRecipeService()))
        }
    }
}
