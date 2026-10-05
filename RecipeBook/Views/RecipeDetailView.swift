import SwiftUI

/// Full recipe: description, dietary tags, ingredients (scalable by servings) and numbered steps.
struct RecipeDetailView: View {
    let recipe: Recipe
    @State private var servings: Int

    init(recipe: Recipe) {
        self.recipe = recipe
        _servings = State(initialValue: recipe.servings)
    }

    /// Multiplier for ingredient amounts. `Recipe` guarantees `servings > 0` at decode time.
    private var scale: Double { Double(servings) / Double(recipe.servings) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                ingredientsSection
                instructionsSection
            }
            .padding()
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(recipe.emoji ?? "🍽️")
                .font(.system(size: 72))
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .background(.tint.opacity(0.12), in: .rect(cornerRadius: 20))
                .accessibilityHidden(true)

            Text(recipe.title)
                .font(.largeTitle.bold())
            Text(recipe.summary)
                .font(.body)
                .foregroundStyle(.secondary)

            if !recipe.dietaryAttributes.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(recipe.sortedDietaryAttributes, id: \.self) { DietaryTagView(attribute: $0) }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Ingredients")

            Stepper(value: $servings, in: 1...48) {
                Text("^[\(servings) serving](inflect: true)")
                    .font(.headline)
            }
            if servings != recipe.servings {
                Text("Amounts adjusted from the original \(recipe.servings).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { _, ingredient in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(ingredient.displayAmount(scale: scale) ?? "")
                            .fontWeight(.semibold)
                            .frame(minWidth: 80, alignment: .leading)
                        Text(ingredient.name)
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Instructions")
            ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(.tint, in: .circle)
                        .accessibilityLabel("Step \(index + 1)")
                    Text(step)
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title2.bold())
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    NavigationStack { RecipeDetailView(recipe: .preview) }
}
