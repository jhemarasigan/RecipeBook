import SwiftUI

/// Modal form for the structured filters. Edits a draft copy and applies it on "Apply",
/// so typing here doesn't trigger a search per keystroke and Cancel discards changes.
struct RecipeFilterView: View {
    @Binding var query: RecipeSearchQuery
    @State private var draft: RecipeSearchQuery
    @Environment(\.dismiss) private var dismiss

    private static let defaultServings = 4

    init(query: Binding<RecipeSearchQuery>) {
        _query = query
        _draft = State(initialValue: query.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Diet") {
                    Picker("Diet", selection: $draft.isVegetarian) {
                        Text("Any").tag(Bool?.none)
                        Text("Vegetarian").tag(Bool?.some(true))
                        Text("Non-veg").tag(Bool?.some(false))
                    }
                    .pickerStyle(.segmented)
                }

                Section("Servings") {
                    Toggle("Filter by servings", isOn: servingsEnabled)
                    if let servings = draft.servings {
                        Stepper("Exactly \(servings)", value: servingsValue, in: 1...24)
                    }
                }

                IngredientTokenSection(
                    title: "Include ingredients",
                    prompt: "e.g. tomato",
                    footer: "Recipes must contain every ingredient listed.",
                    tokens: $draft.includedIngredients
                )
                IngredientTokenSection(
                    title: "Exclude ingredients",
                    prompt: "e.g. egg",
                    footer: "Recipes containing any of these are hidden.",
                    tokens: $draft.excludedIngredients
                )

                Section {
                    TextField("e.g. simmer, whisk", text: $draft.instructionText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Instructions contain")
                } footer: {
                    Text("Every word must appear somewhere in the cooking steps.")
                }

                Section {
                    Button("Reset Filters", role: .destructive) { draft.clearFilters() }
                        .disabled(draft.activeFilters.isEmpty)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        query = draft
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: Bindings

    private var servingsEnabled: Binding<Bool> {
        Binding(
            get: { draft.servings != nil },
            set: { draft.servings = $0 ? (draft.servings ?? Self.defaultServings) : nil }
        )
    }

    private var servingsValue: Binding<Int> {
        Binding(
            get: { draft.servings ?? Self.defaultServings },
            set: { draft.servings = $0 }
        )
    }
}

/// A list of removable text tokens with an inline field to add more.
private struct IngredientTokenSection: View {
    let title: String
    let prompt: String
    let footer: String
    @Binding var tokens: [String]
    @State private var newToken = ""

    var body: some View {
        Section {
            ForEach(tokens, id: \.self) { Text($0) }
                .onDelete { tokens.remove(atOffsets: $0) }
            HStack {
                TextField(prompt, text: $newToken)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit(addToken)
                Button("Add", action: addToken)
                    .disabled(newToken.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } header: {
            Text(title)
        } footer: {
            Text(footer)
        }
    }

    private func addToken() {
        let token = newToken.trimmingCharacters(in: .whitespacesAndNewlines)
        newToken = ""
        guard !token.isEmpty,
              !tokens.contains(where: { $0.caseInsensitiveCompare(token) == .orderedSame })
        else { return }
        tokens.append(token)
    }
}

#Preview {
    @Previewable @State var query = RecipeSearchQuery(isVegetarian: true, includedIngredients: ["tomato"])
    RecipeFilterView(query: $query)
}
