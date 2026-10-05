import Foundation

/// A dietary label a recipe can carry. Raw values match the API's `dietary_attributes` strings.
enum DietaryAttribute: String, CaseIterable, Hashable, Sendable {
    case vegetarian
    case vegan
    case glutenFree = "gluten-free"
    case dairyFree = "dairy-free"
    case nutFree = "nut-free"

    var displayName: String {
        switch self {
        case .vegetarian: "Vegetarian"
        case .vegan: "Vegan"
        case .glutenFree: "Gluten-Free"
        case .dairyFree: "Dairy-Free"
        case .nutFree: "Nut-Free"
        }
    }

    /// Compact visual shorthand used on recipe cards.
    var symbol: String {
        switch self {
        case .vegetarian: "🥕"
        case .vegan: "🌱"
        case .glutenFree: "🌾"
        case .dairyFree: "🥛"
        case .nutFree: "🥜"
        }
    }
}
