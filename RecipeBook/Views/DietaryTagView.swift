import SwiftUI

/// Capsule label for a dietary attribute, e.g. "🌱 Vegan".
struct DietaryTagView: View {
    let attribute: DietaryAttribute

    var body: some View {
        Label {
            Text(attribute.displayName)
        } icon: {
            Text(attribute.symbol)
        }
        .font(.footnote.weight(.medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.tint.opacity(0.12), in: .capsule)
    }
}

#Preview {
    HStack {
        DietaryTagView(attribute: .vegan)
        DietaryTagView(attribute: .glutenFree)
    }
}
