import Foundation

/// A cooking recipe as returned by the (mock) recipes API.
struct Recipe: Identifiable, Hashable, Sendable, Decodable {
    let id: Int
    let title: String
    /// Short blurb. The API field is called `description`; it is renamed here to avoid
    /// confusion with `CustomStringConvertible.description`.
    let summary: String
    let emoji: String?
    let servings: Int
    let ingredients: [Ingredient]
    let instructions: [String]
    let dietaryAttributes: Set<DietaryAttribute>

    /// Vegan recipes are, by definition, vegetarian.
    var isVegetarian: Bool {
        dietaryAttributes.contains(.vegetarian) || dietaryAttributes.contains(.vegan)
    }

    /// Attributes in a stable display order (a `Set` has none).
    var sortedDietaryAttributes: [DietaryAttribute] {
        DietaryAttribute.allCases.filter(dietaryAttributes.contains)
    }

    init(
        id: Int,
        title: String,
        summary: String,
        emoji: String? = nil,
        servings: Int,
        ingredients: [Ingredient],
        instructions: [String],
        dietaryAttributes: Set<DietaryAttribute> = []
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.emoji = emoji
        self.servings = servings
        self.ingredients = ingredients
        self.instructions = instructions
        self.dietaryAttributes = dietaryAttributes
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, emoji, servings, ingredients, instructions
        case summary = "description"
        case dietaryAttributes = "dietary_attributes"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        summary = try container.decode(String.self, forKey: .summary)
        emoji = try container.decodeIfPresent(String.self, forKey: .emoji)
        ingredients = try container.decode([Ingredient].self, forKey: .ingredients)
        instructions = try container.decode([String].self, forKey: .instructions)

        // Reject nonsensical data at the boundary; the UI divides by `servings` when scaling.
        let servings = try container.decode(Int.self, forKey: .servings)
        guard servings > 0 else {
            throw DecodingError.dataCorruptedError(
                forKey: .servings, in: container,
                debugDescription: "servings must be greater than zero, got \(servings)"
            )
        }
        self.servings = servings

        // Be forward-compatible: a label this app version doesn't know about is dropped
        // rather than failing the whole recipe (or the whole response).
        let rawAttributes = try container.decodeIfPresent([String].self, forKey: .dietaryAttributes) ?? []
        dietaryAttributes = Set(rawAttributes.compactMap(DietaryAttribute.init(rawValue:)))
    }
}

/// Envelope returned by the recipes endpoint: `{ "recipes": [...] }`.
struct RecipeListResponse: Decodable, Sendable {
    let recipes: [Recipe]
}
