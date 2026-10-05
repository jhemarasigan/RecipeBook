import SwiftUI

/// Horizontally scrolling chips for each active filter; tapping a chip removes it.
struct ActiveFiltersBar: View {
    let filters: [RecipeSearchQuery.Filter]
    let onRemove: (RecipeSearchQuery.Filter) -> Void

    var body: some View {
        if !filters.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(filters, id: \.self) { filter in
                        Button {
                            onRemove(filter)
                        } label: {
                            HStack(spacing: 4) {
                                Text(filter.title)
                                Image(systemName: "xmark")
                                    .font(.caption2.weight(.bold))
                            }
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .controlSize(.small)
                        .accessibilityLabel("Remove filter: \(filter.title)")
                    }
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 16, for: .scrollContent)
        }
    }
}

#Preview {
    ActiveFiltersBar(filters: [.vegetarian(true), .including("tomato"), .excluding("egg")]) { _ in }
}
