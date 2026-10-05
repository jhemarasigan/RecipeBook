import SwiftUI

/// Root screen: searchable grid of recipe cards with a filter sheet.
struct RecipeListView: View {
    @State private var viewModel: RecipeListViewModel
    @State private var isShowingFilters = false

    private let columns = [GridItem(.adaptive(minimum: 165), spacing: 16)]

    init(viewModel: RecipeListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var model = viewModel

        NavigationStack {
            content
                .navigationTitle("Recipes")
                .searchable(text: $model.query.keyword, prompt: "Search recipes or ingredients")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Filters", systemImage: filterIcon) { isShowingFilters = true }
                    }
                }
                .sheet(isPresented: $isShowingFilters) {
                    RecipeFilterView(query: $model.query)
                        .presentationDetents([.large])
                }
        }
        // Re-runs (and cancels the previous run) every time the query changes.
        .task(id: viewModel.query) { await viewModel.search() }
    }

    private var filterIcon: String {
        viewModel.hasActiveFilters
            ? "line.3.horizontal.decrease.circle.fill"
            : "line.3.horizontal.decrease.circle"
    }

    // MARK: States

    @ViewBuilder
    private var content: some View {
        if let message = viewModel.errorMessage {
            ContentUnavailableView {
                Label("Couldn't Load Recipes", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { Task { await viewModel.search() } }
                    .buttonStyle(.borderedProminent)
            }
        } else if viewModel.recipes.isEmpty {
            if viewModel.isLoading {
                ProgressView("Loading recipes…")
            } else {
                emptyResults
            }
        } else {
            recipeGrid
        }
    }

    private var emptyResults: some View {
        ContentUnavailableView {
            Label("No Matching Recipes", systemImage: "fork.knife")
        } description: {
            Text("Try a different search or loosen your filters.")
        } actions: {
            if viewModel.hasActiveFilters {
                Button("Clear Filters") { viewModel.query.clearFilters() }
            }
        }
    }

    private var recipeGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ActiveFiltersBar(filters: viewModel.query.activeFilters) { filter in
                    viewModel.query.remove(filter)
                }
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.recipes) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeCardView(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
            .opacity(viewModel.isLoading ? 0.6 : 1)
            .animation(.default, value: viewModel.isLoading)
        }
        .navigationDestination(for: Recipe.self) { RecipeDetailView(recipe: $0) }
    }
}

#Preview("Loaded") {
    RecipeListView(viewModel: RecipeListViewModel(service: MockRecipeService(latency: .zero)))
}

#Preview("Empty") {
    RecipeListView(viewModel: RecipeListViewModel(service: StubRecipeService(result: .success([]))))
}

#Preview("Error") {
    RecipeListView(
        viewModel: RecipeListViewModel(
            service: StubRecipeService(result: .failure(.decodingFailed(details: "preview")))
        )
    )
}
