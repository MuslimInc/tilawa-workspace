# Phase 1 — Foundation: Breakpoints + Max-widths

Status: **Shipped.** Part of the responsive/adaptive rollout plan in [responsive_adaptive_architecture_review.md](responsive_adaptive_architecture_review.md).

## Goal

Lay the substrate for the rest of the rollout. No user-visible UX change in this phase — it is purely additive primitives that the following phases build on.

## What landed

### 1. Window-size classification

`packages/ui_kit/lib/src/foundation/breakpoints.dart`

- `TilawaBreakpoints` — Material 3 aligned thresholds (`compact = 600`, `medium = 840`, `expanded = 1200`).
- `TilawaWindowSize` enum — `compact`, `medium`, `expanded`, `large`. The `large` class is reserved; it is not actively targeted today.
- `TilawaWindowSizeX` extension on `BuildContext`:
  - `windowSize` — resolves the current class from `MediaQuery.sizeOf(context)`. Uses the narrow `sizeOf` dependency so consumers do not rebuild on unrelated `MediaQuery` changes (keyboard, text scaler).
  - `isCompact`, `isAtLeastMedium`, `isAtLeastExpanded`, `isAtLeastLarge` — predicates for common branches.

### 2. Content max-width tokens

`packages/ui_kit/lib/src/foundation/design_tokens.dart`

Added four tokens to `TilawaDesignTokens`, with `copyWith`/`lerp` support:

| Token | Value | Usage |
| --- | --- | --- |
| `contentMaxWidthReader` | 720 | Quran reader body |
| `contentMaxWidthForm` | 560 | Settings, dialogs, auth, sheets |
| `contentMaxWidthMedia` | 1200 | Share composers, galleries |
| `contentMaxWidthSettings` | 760 | Settings detail pages |

### 3. `TilawaContentBounds` layout primitive

`packages/ui_kit/lib/src/foundation/content_bounds.dart`

- Classified as a **Foundation / Layout Primitive** (no background, border, padding, or other affordance — only layout constraint).
- `TilawaContentKind` enum selects the token-backed max width (`reader | form | media | settings`).
- `maxWidth` override is supported for one-off cases.
- Wraps `Align(alignment: Alignment.topCenter) → ConstrainedBox`, keeping content centered horizontally while respecting vertical scrolling.

### 4. Exports

`packages/ui_kit/lib/src/foundation/foundation.dart` now re-exports `breakpoints.dart` and `content_bounds.dart`, so consumers get them from the standard `package:tilawa_ui_kit/tilawa_ui_kit.dart` surface.

### 5. Reference migration

`apps/tilawa/lib/features/reciters/presentation/screens/reciters_screen.dart`

The reciters screen body is now wrapped in `TilawaContentBounds(kind: TilawaContentKind.media, ...)`. Chosen as the reference because it is a gallery-style screen and is the exit criterion for this phase. Behavior on phones is unchanged (screens narrower than 1200 simply fill the width); on tablets and foldables the gallery no longer stretches to the full display.

## Usage pattern

```dart
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Scaffold(
  body: TilawaContentBounds(
    kind: TilawaContentKind.form,
    child: /* screen content */,
  ),
);
```

For window-size branches at the call site:

```dart
if (context.isAtLeastExpanded) {
  // tablet-landscape layout
}
```

## What is explicitly out of scope for Phase 1

- No changes to text scaling (Phase 3).
- No adaptive shell / navigation rail (Phase 4).
- No `TilawaContentGrid` helper (Phase 5).
- No sweep migration of other screens to `TilawaContentBounds` — only the reciters reference (Phase 2 covers the top-5 sweep).
- No `displayFeatures` handling (Phase 4).

## Validation

- `flutter analyze` on `packages/ui_kit` — **no issues**.
- `flutter analyze` on `apps/tilawa` — only pre-existing issues unrelated to this phase.

## Migration cost

Zero. All additions are purely additive and the reference migration only wraps an existing widget.

## Notes on design choices

- **Why `Align(topCenter)` inside `TilawaContentBounds` instead of `Center`.** `Center` pushes the child vertically; `topCenter` preserves normal top-of-screen layout while still centering horizontally inside wider constraints.
- **Why `TilawaContentBounds` lives in `foundation/` and not `molecules/`.** It carries no UI affordance. Classifying it as a layout primitive keeps atomic design honest and avoids accidental theme coupling.
- **Why a dedicated `reciters` wrap as the reference.** It is the most ad-hoc in its layout today (manual 680/980 width branches for grid columns) and demonstrates the cleanest before/after — but the grid logic itself is deliberately not touched in Phase 1. That refactor belongs to Phase 5 (`TilawaContentGrid`).

## Next

Phase 2 — apply `TilawaContentBounds` to the top 5 screens (reader, settings, share composers, bookmarks, reciters detail). That phase is where users start to see the improvement on tablets and foldables.
