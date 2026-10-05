# Recipe Book

A native SwiftUI app for browsing and searching cooking recipes. Recipes come from a bundled
JSON file that is accessed through a service layer shaped like a real API.

- **Swift 6 / SwiftUI**, iOS 26+, no third-party dependencies
- **Xcode 26** or later

## Setup

1. Open `RecipeBook.xcodeproj` in Xcode 26+.
2. Select the **RecipeBook** scheme and an iOS 26 simulator (or device).
3. If running on a device, set your team under *Signing & Capabilities* (the bundle ID is
   `com.example.RecipeBook`; change it if it collides).
4. Run with **⌘R**. Run the unit tests with **⌘U**.
5. SwiftUI previews are available in every view file (including loading-independent
   *Empty* and *Error* previews of the list).

> **If the project fails to open or build:** the `.xcodeproj` was written by hand and has not been
> opened in Xcode by its author. The source of truth is the folder structure, so the fallback is
> trivial: create a new *iOS App* project (SwiftUI, Swift Testing) named `RecipeBook`, delete the
> template files, drag in the `RecipeBook/` and `RecipeBookTests/` folders (*Create folder
> references* off, add to the matching targets), and set the deployment target to iOS 26.

## Features

- Adaptive grid of recipe cards (title, blurb, servings, dietary icons).
- Search bar: free text over title, description and **ingredient names**.
- Filter sheet: vegetarian / non-vegetarian, exact servings, **include** ingredients,
  **exclude** ingredients, and text search within the **instructions**.
- Active filters appear as removable chips above the grid.
- Detail screen with a servings stepper that rescales ingredient amounts.
- Distinct loading, empty-results and error states (with retry).

## Architecture

```
RecipeBook/
├── RecipeBookApp.swift          Composition root (chooses the RecipeService)
├── Models/
│   ├── Recipe.swift             Recipe + API envelope, tolerant decoding
│   ├── Ingredient.swift         Structured amount/unit/name
│   ├── DietaryAttribute.swift   Enum of dietary labels
│   └── RecipeSearchQuery.swift  All optional filters + the matching rules
├── Services/
│   ├── RecipeService.swift      Protocol + error type (the "API" boundary)
│   └── MockRecipeService.swift  Actor serving bundled recipes.json
├── ViewModels/
│   └── RecipeListViewModel.swift  @Observable state: query, results, loading, error
├── Views/                       RecipeListView, RecipeCardView, RecipeDetailView,
│                                RecipeFilterView, ActiveFiltersBar, DietaryTagView
├── Preview/PreviewSupport.swift Debug-only sample data and stub service
└── Resources/recipes.json       Mock API response
```

**Data flow:** `RecipeListView` binds to `RecipeListViewModel.query`. When the query changes,
`.task(id: query)` cancels the previous search and calls `search()`, which debounces, then calls
`RecipeService.searchRecipes(matching:)`. The service returns already-filtered recipes, exactly
as a server-side search endpoint would.

## Key design decisions

- **Service protocol as the API boundary.** The view model depends on `RecipeService`, not on
  the JSON file. A real `URLSession` implementation can be dropped in at the composition root.
  `MockRecipeService` decodes the same `{ "recipes": [...] }` envelope, simulates latency
  and takes an injectable data loader for testing failure modes.
- **One query type for the whole search "endpoint".** `RecipeSearchQuery` models every optional
  filter, and its `matches(_:)` is a pure function, so the rules are unit-tested with no I/O.
- **Modern SwiftUI idioms.** `@Observable` view model, `@State` ownership, `.searchable`,
  `.task(id:)` for cancel-and-restart searches, `NavigationStack` with value-based
  `navigationDestination`, `ContentUnavailableView`, `@Previewable`, automatic grammar agreement
  (`^[\(n) serving](inflect: true)`).
- **Swift concurrency.** The view model is `@MainActor`; the mock service is an `actor`; all
  models are `Sendable` value types. Cancelled searches never overwrite newer state.
- **Draft-and-apply filter sheet.** The sheet edits a copy and applies on *Apply*, so typing
  does not fire a search per keystroke and *Cancel* is meaningful.
- **Validation at the boundary.** Decoding rejects `servings <= 0` and ignores unknown dietary
  labels, so bad data fails loudly (or degrades gracefully) at the edge instead of deep in the UI.
- **No packages.** The scope doesn't justify a dependency; Foundation and SwiftUI cover it.

## Assumptions and tradeoffs

- **Vegetarian semantics:** vegan implies vegetarian. The filter is tri-state (any / vegetarian /
  non-vegetarian).
- **Servings filter is exact** (`servings == n`). A "at least n" or range would be a small
  change in `matches(_:)`; exact is the most literal reading of the brief.
- **Include = AND, exclude = OR-removal:** a recipe must contain *all* included ingredients and
  *none* of the excluded ones.
- **Text matching** is case- and diacritic-insensitive; multi-word queries require every word
  (AND). Ingredient filters match as substrings of the ingredient name.
- **Keyword search includes ingredient names**, because "chicken" should find the adobo even
  if the title doesn't say so.
- **Added `emoji` field** to the JSON as a lightweight stand-in for photos. It is optional;
  recipes without it get a default plate.
- **Filtering inside the service** (not in the view model) mirrors a real backend; the cost is
  that the mock does O(n) work per search, which is irrelevant at this size.
- **Debounce** of 300 ms (view model) and simulated latency of 250 ms (mock) are
  constants chosen for feel, not measured.
- **Strings are not localised.** User-facing text is plain English literals.

## Known limitations

- Substring ingredient matching is naive: excluding `egg` also excludes `eggplant`, and `eggs`
  won't match a search for `egg whites`. Real stemming/tokenised matching or server-side
  search would fix this.
- No pagination, favourites, persistence or image loading (no real network layer exists).
- The filter sheet only commits ingredient text that was added with *Add* / Return.
- Scaled amounts are shown as decimals (`0.5`), not cooking fractions (`½`), and units are not
  converted.
- Accessibility has been considered (combined card labels, header traits, Dynamic Type via system
  fonts) but not audited with VoiceOver on a device.
- UI tests are not included; unit tests cover the models, matching rules, decoding and service
  behaviour (`⌘U`).
