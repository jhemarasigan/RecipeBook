import Foundation

/// One line of a recipe's ingredient list.
///
/// `amount` and `unit` are optional so entries such as "salt, to taste" or
/// "2 eggs" (no unit) are representable without string parsing.
struct Ingredient: Hashable, Sendable, Decodable {
    let name: String
    let amount: Double?
    let unit: String?

    init(_ name: String, amount: Double? = nil, unit: String? = nil) {
        self.name = name
        self.amount = amount
        self.unit = unit
    }

    /// Human-readable quantity (e.g. "250 g", "2"), or `nil` when no amount is specified.
    /// - Parameter scale: Multiplier applied to `amount`, used when the cook changes servings.
    func displayAmount(scale: Double = 1) -> String? {
        guard let amount else { return nil }
        let value = (amount * scale).formatted(.number.precision(.fractionLength(0...2)))
        guard let unit else { return value }
        return "\(value) \(unit)"
    }
}
