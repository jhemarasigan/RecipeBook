import SwiftUI

/// Grid cell summarising a recipe.
struct RecipeCardView: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(recipe.emoji ?? "🍽️")
                .font(.system(size: 52))
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(.tint.opacity(0.12))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(2, reservesSpace: true)
                Text(recipe.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2, reservesSpace: true)
                Text("^[\(recipe.servings) serving](inflect: true)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    ForEach(recipe.sortedDietaryAttributes, id: \.self) { attribute in
                        Text(attribute.symbol)
                    }
                }
                .font(.footnote)
                .frame(minHeight: 20, alignment: .leading)
                .accessibilityHidden(true)
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary)
        .clipShape(.rect(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts = [recipe.title, "serves \(recipe.servings)"]
        parts += recipe.sortedDietaryAttributes.map(\.displayName)
        return parts.joined(separator: ", ")
    }
}

#Preview {
    RecipeCardView(recipe: .preview)
        .frame(width: 180)
        .padding()
}
