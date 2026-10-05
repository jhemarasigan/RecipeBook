import Foundation

/// The seam between the UI and wherever recipes come from.
///
/// The app only depends on this protocol. Swapping the bundled-JSON mock for a real
/// `URLSession`-backed implementation means adding one type and changing one line in
/// `RecipeBookApp`; no view or view model changes.
protocol RecipeService: Sendable {
    /// Returns the recipes matching `query`. An empty query returns everything.
    func searchRecipes(matching query: RecipeSearchQuery) async throws -> [Recipe]
}

enum RecipeServiceError: LocalizedError {
    case resourceNotFound(name: String)
    case decodingFailed(details: String)

    var errorDescription: String? {
        switch self {
        case .resourceNotFound: "The recipe data is missing from the app."
        case .decodingFailed: "The recipe data couldn't be read."
        }
    }

    /// Technical detail for logs and debugging; not shown as the primary message.
    var failureReason: String? {
        switch self {
        case .resourceNotFound(let name): "Bundle resource \"\(name)\" was not found."
        case .decodingFailed(let details): details
        }
    }
}
