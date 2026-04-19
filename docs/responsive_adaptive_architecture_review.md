# Responsive & Adaptive Architecture — Review and Plan

Senior architect's review of the Tilawa UI Kit and Tilawa app for responsive/adaptive behavior. No implementation yet — this document is the deliverable.

Scope covered: small phones, large phones, foldables, tablets. Excludes desktop/web as non-goal for now (easy to extend once the foundation lands).

---

## 1. Validation of current foundation

### What is correct

**Design tokens (`TilawaDesignTokens`)**
- Proper `ThemeExtension<TilawaDesignTokens>` with `copyWith` + `lerp`. This is the right primitive — production-grade.
- Tokens are dimensionless from the device's perspective (fixed `4/8/12/16/24` etc.), which is exactly what large apps do for spacing/radius/borders.
- Access pattern `theme.tokens` is ergonomic and encourages correct usage.

**Component tokens (`ComponentTokens`)**
- Per-component values (`immersiveComposer.compactHeightBreakpoint`, `panelMinHeight`, etc.) keep magic numbers local and theme-able. Good separation from global design tokens.

**Immersive composer scaffold**
- Uses `LayoutBuilder` to switch between compact/regular layouts by **height**, not by width. That's correct for vertical composers.
- `clampDouble` on panel and preview heights — good defensive sizing.
- `SafeArea` + token-driven padding at the right layer.

**Existing adaptive primitives in the app**
- `NavigationBar`, `LayoutBuilder`, `SliverGrid` already appear in real features (main screen, reciters, prayer times). The team reaches for the right tools.
- Composer scaffolds and settings tiles already consume tokens consistently.

### What is risky

**No formal breakpoint system**
- Width-based device classification is ad-hoc across files; some surfaces reason about size inline, some don't. No shared `TilawaWindowSize`, no shared thresholds.
- Risk: every feature re-implements "is this a tablet?" slightly differently → drift.

**No content max-width discipline**
- On a tablet/foldable unfolded, screens currently stretch edge-to-edge. For the Quran reader and settings in particular, this is a readability hazard.
- Risk: when you test on a Pixel Fold unfolded, text lines become too long; cards balloon.

**Height-only breakpoint in composer**
- `ImmersiveComposerScaffold` adapts by height but not by width. On a landscape tablet, preview + bottom panel could sit **side-by-side**, not stacked. That's a missed UX win, not a bug.

**`screenutil_compat.dart` shim**
- Signals legacy ScreenUtil patterns. This is exactly the global-scaling shortcut we want to retire. Needs an audit and a deprecation path.

**Text scaling is unclamped at app root**
- Accessibility text scale can reach 2.0× on both iOS and Android. Arabic text with tight line heights is vulnerable at that scale, particularly in Qur'an rendering.
- Risk: layouts that are correct at 1.0× can break at extreme scale factors on composer, sheet, and reader surfaces.

**Reader layout constants are correct but fragile**
- The `25/720`, `16.5`, `27.762` constants (per memory) are physically derived from the mushaf page and must **never** be touched by any responsive system. They need explicit protection in policy, not just convention.

**No `DisplayFeature` handling**
- Foldables expose hinge/fold regions via `MediaQuery.displayFeatures`. The app doesn't currently consult them, so content may be placed under a hinge on a Fold.

**Rebuild scope on MediaQuery changes**
- Several widgets read `MediaQuery.of(context)` (the whole MediaQueryData) rather than `MediaQuery.sizeOf(context)`. On keyboard open/rotation, this forces rebuild of subtrees that only care about size.

### What is missing

| Concern | Status | Needed |
| --- | --- | --- |
| Formal breakpoints | missing | `TilawaBreakpoints` + `TilawaWindowSize` enum + `BuildContext` extension |
| Content max-widths | missing | `contentMaxWidthReader/Form/Media/Settings` tokens |
| Adaptive shell | partial (BottomNav only) | Bottom-nav ↔ Rail ↔ extended-Rail organism |
| Grid helpers | ad-hoc | `TilawaContentGrid` over `SliverGridDelegateWithMaxCrossAxisExtent` |
| Reader policy | implicit | Documented rules: fixed reading width, user-driven scale, no device scaling |
| Text scaling clamp | missing | Clamp `[1.0, 1.4]` at `MaterialApp.builder` |
| Display features | missing | Consume `MediaQuery.displayFeaturesOf(context)` in shell/composers |
| Responsive tokens | missing | Per-breakpoint override path on `TilawaDesignTokens` (optional) |
| RTL test matrix | missing | Explicit RTL snapshots/integration for top screens |
| Perf guardrails | informal | `const` discipline, rebuild scope rules, `RepaintBoundary` policy |

---

## 2. Recommended responsive/adaptive architecture

The system follows one meta-principle: **keep sizing axes separate**. One axis must not drive another.

| Axis | Driver | Source of truth |
| --- | --- | --- |
| Spacing / radius / borders | Design tokens | `TilawaDesignTokens` (fixed) |
| Typography | `MediaQuery.textScaler` clamped `[1.0, 1.4]` | App root |
| Layout (nav, columns, max width) | Breakpoints + `LayoutBuilder` | `TilawaBreakpoints` + local |
| Media / grid items | `AspectRatio` + `maxCrossAxisExtent` | Feature-local, token-fed |
| Reader page geometry | Physical mushaf constants | Reader package (immutable) |
| Insets / foldables | `MediaQuery.viewPadding` + `displayFeatures` | Adaptive shell |

### A. Breakpoints

Aligned with Material 3 window size classes — the industry-standard taxonomy.

```
compact   : width  <  600   (phones portrait)
medium    : 600 ≤  width  <  840   (small tablets, foldables inner display portrait, phones landscape)
expanded  : 840 ≤  width  < 1200   (tablets, foldables landscape)
large     : 1200 ≤ width           (large tablets, desktop; non-goal now but reserve the class)
```

API shape:

```dart
class TilawaBreakpoints {
  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;
}

enum TilawaWindowSize { compact, medium, expanded, large }

extension TilawaWindowSizeX on BuildContext {
  TilawaWindowSize get windowSize;     // from MediaQuery.sizeOf(this).width
  bool get isCompact;
  bool get isAtLeastMedium;
  bool get isAtLeastExpanded;
}
```

**Location:** `packages/ui_kit/lib/src/foundation/breakpoints.dart`, re-exported from `foundation.dart`.

### B. Content max-width tokens

Added to `TilawaDesignTokens`:

| Token | Value | Usage |
| --- | --- | --- |
| `contentMaxWidthReader` | 720 | Quran reader body |
| `contentMaxWidthForm` | 560 | Settings, dialogs, auth, sheets |
| `contentMaxWidthMedia` | 1200 | Share composers, galleries |
| `contentMaxWidthSettings` | 760 | Settings detail pages |

Usage pattern:

```dart
ConstrainedBox(
  constraints: BoxConstraints(maxWidth: tokens.contentMaxWidthForm),
  child: ...,
)
```

Helper widget (classified as **Foundation / Layout Primitive**, not a molecule — it carries no UI affordance, only layout constraint): `TilawaContentBounds(kind: TilawaContentKind.form, child: ...)` to avoid repetition and to centralize horizontal centering.

### C. Adaptive shell

A new kit organism `TilawaAdaptiveShell`:

| Window size | Navigation | Rationale |
| --- | --- | --- |
| compact | `NavigationBar` bottom | Thumb-reachable; current behavior preserved |
| medium | `NavigationRail` (icons + labels, collapsed) | Foldable inner displays; landscape phones |
| expanded | `NavigationRail` extended, optional sticky header | Tablet landscape; reduces travel time to nav |
| large | Drawer persistent or extended rail + secondary pane | Reserved; not built in phase 1 |

Integration points:
- Consumes `MediaQuery.displayFeaturesOf(context)` to avoid placing nav over hinges.
- Accepts an optional `secondaryPane` slot (null on compact) for list/detail patterns on expanded. Not used day 1 — it's the seam for Phase 4/5.

### D. Grid helpers

`TilawaContentGrid` — classified as a **Layout Primitive / Adaptive Grid Helper**, not an organism. It owns no visual identity; it is a responsive layout utility that wraps `SliverGridDelegateWithMaxCrossAxisExtent`:

```dart
TilawaContentGrid(
  targetItemExtent: 280,        // max cross-axis extent per item
  childAspectRatio: 3 / 4,
  mainAxisSpacing: tokens.spaceMedium,
  crossAxisSpacing: tokens.spaceMedium,
  itemBuilder: (ctx, i) => ...,
)
```

Why `maxCrossAxisExtent` and not `crossAxisCount`: column count becomes a function of available width and the item's target size — no manual breakpoint branching per grid, and it composes with `ConstrainedBox` max-widths cleanly.

Used by: reciters, bookmarks, history, athkar categories, prayer times grid.

### E. Reader policy (hard rules)

The Quran reader is the product's highest-stakes surface. Codified and enforced:

1. **Page geometry is physical.** The `25/720`, `16.5`, `27.762` constants are immutable. No responsive/adaptive layer is permitted to scale them.
2. **Page container width** is bounded by `tokens.contentMaxWidthReader` and centered. On tablets, we keep the page a comfortable reading width with margins — we do **not** stretch the page to the display.
3. **Aspect ratio** of the 15-line grid is preserved by `AspectRatio`. Scale the *container*; never the grid.
4. **Font scale** for reading text is driven by a user preference (already foreseen in your architecture memory) — **not** by device width. On a tablet, a user may prefer *smaller* relative text.
5. **RTL text direction** is locked regardless of platform `Directionality` for the page region. The page frame direction may follow locale; the text direction inside the page is always RTL.
6. **No `MediaQuery.size`-driven sizing** anywhere in the reader render path.

### F. Text scaling policy

At `MaterialApp.builder`:

```dart
MaterialApp(
  builder: (context, child) {
    final scaler = MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.4,
    );
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: child!,
    );
  },
);
```

Rationale:
- `[1.0, 1.4]` is the recommended default upper bound for the system-wide clamp. It accommodates a broad range of accessibility preferences while keeping composer, sheet, and chrome layouts within a tested envelope.
- The lower bound of `1.0` preserves design intent at the baseline; sub-1.0 scaling is not expected behavior on supported platforms and is not supported by this policy.
- Beyond `1.4`, Arabic line heights and dense composer/sheet layouts exceed their tested range and require per-surface validation rather than a global guarantee.

Reader text is **not** subject to this clamp. Reader font size comes from the user's reader-specific preference, independent of system text scale. This is a documented carve-out.

### G. Safe area / insets / foldables

Rules enforced by the shell and by kit organisms:

1. **Explicit safe-area handling is mandatory.** Every screen must explicitly handle safe-area insets. `SafeArea` should be used by default unless the screen intentionally opts into edge-to-edge behavior (e.g., immersive reader, full-bleed media). Never rely on `Scaffold` implicit padding alone.
2. **Read `MediaQuery.viewInsetsOf`** (not the full `MediaQueryData`) when reacting to keyboard.
3. **Display features.** `TilawaAdaptiveShell` consumes `MediaQuery.displayFeaturesOf(context)` and splits its body around hinges/folds. For Phase 1, minimum is: do not render nav-rail across a hinge.
4. **Edge-to-edge system UI.** The app runs edge-to-edge (standard now); compose `SystemUiOverlayStyle` once at the shell, not per-screen.
5. **Bottom gesture area.** Any bottom-docked control (player, sheets) uses `SafeArea(bottom: true)` and avoids the Android gesture zone.

### H. Performance policy

Large apps are obsessive about rebuild scope. Rules:

1. **`MediaQuery.sizeOf`, not `MediaQuery.of`.** Size-only dependencies. Same for `viewInsetsOf`, `textScalerOf`, `displayFeaturesOf`.
2. **`const` constructors** for atoms/molecules wherever inputs are compile-time constants. Atoms that take tokens via `Theme.of` cannot be `const` — and that's fine; their parents can be.
3. **`RepaintBoundary` for the preview region** in composers and around the reader page. Already partly done in share composers — promote to policy.
4. **`LayoutBuilder` placement.** Use at the **narrowest** subtree that actually needs it. A `LayoutBuilder` at screen root rebuilds everything on keyboard open. Place it inside the region that consumes constraints.
5. **No work in `build`.** No image decoding, no file I/O, no preference reads. Hoist to `initState`/providers.
6. **Grids use slivers.** `CustomScrollView` + `SliverGrid` over nested `ListView`/`GridView`. Near-O(1) per-visible-item cost, correct scrolling semantics.
7. **Rebuild-stopping boundaries.** `BlocSelector`/`context.select` for leaf widgets to avoid parent-level rebuilds.

### I. Motion / interaction policy

1. Animation durations and curves are sourced from tokens (`durationFast/Medium/Slow`). No inline `Duration(milliseconds: N)` in widgets.
2. Avoid large implicit animations on layout changes (`AnimatedContainer`, `AnimatedPadding`) at screen scope — they produce continuous reflow on constraint changes.
3. Adaptive layout transitions between window-size classes are **discrete**: the layout swaps, it does not interpolate. Continuous reflow between nav-bar and nav-rail is explicitly out of scope.
4. The Quran reader render path contains **no animations**. No fades, no transitions, no implicit motion. Page changes use explicit, controlled transitions only.

### J. UI state contract

Every major screen must explicitly render four states: **loading**, **empty**, **error**, **content**. Responsive layouts that pass review at the happy path routinely break in non-happy paths (error banners overflowing on compact, empty-state illustrations stretching on expanded, loading shimmers ignoring max-width). Treat state coverage as part of the responsive contract, not as a separate QA concern.

### K. Arabic / RTL policy

1. **RTL correctness is a first-class test axis.** Every new screen ships with a manual RTL check; top-10 screens gain golden/integration tests.
2. **Directional APIs.** Always `EdgeInsetsDirectional`, `AlignmentDirectional`, `Positioned.directional`. No `EdgeInsets.only(left: ...)` in new code.
3. **Locked directions.** Regions with fixed direction (reader page, share preview poster) use explicit `Directionality` widgets; they never inherit.
4. **Line heights.** Arabic typography requires generous `height` on text styles (≥ 1.35 for body; reader uses its own). Codify in `TextTheme` extensions.
5. **Overflow policy.** Arabic word breaks rarely produce good ellipses. Prefer `TextOverflow.fade` for dense UI; `ellipsis` only where a Latin-style truncation is acceptable (titles, metadata).
6. **Number shaping.** Respect the user's preferred numeral shaping (Western vs. Eastern Arabic). Already a localized concern — keep out of widgets.
7. **No mirrored icons by default.** Tilawa is Arabic-first; don't flip reader icons via `Directionality`. Only back-arrows and flow-direction glyphs.

---

## 3. Comparison with large-app standards

### What top apps actually do

**Material 3 reference apps (Google, Gmail, Photos, Drive)**
- Window size classes → distinct layouts (list vs list-detail vs supporting-pane).
- `NavigationBar` ↔ `NavigationRail` ↔ extended rail by size class.
- Content bounded: Gmail caps reading width even on 13" tablets.
- Typography from a type-scale extension; no screen-width math.

**Airbnb / Uber**
- Breakpoint-driven layout swaps, not pixel scaling.
- Card sizes derived from "how many fit per row" at each breakpoint — exactly the `maxCrossAxisExtent` pattern.
- Hard max-widths on forms and content pages (≈ 560–720 px).
- Strict design tokens (Airbnb's DLS, Uber's Base).

**High-end mobile-first consumer apps**
- Avoid `flutter_screenutil` or equivalent. When they inherit such a system, they migrate *away* from it.
- Bottom sheets and sheets remain full-width on compact; become centered-modal with capped width on expanded.
- Reader/article surfaces (Medium, Pocket, Apple News) lock measure (CSS ~65ch) — our `contentMaxWidthReader: 720` mirrors this.

### Where Tilawa already matches

- Design tokens via `ThemeExtension`: ✅ best-practice.
- Component tokens: ✅ beyond many teams.
- Atomic structure (atoms/molecules/organisms/foundation): ✅ properly separated.
- `LayoutBuilder` for composer height classes: ✅.
- `SafeArea` discipline in organisms: ✅.
- Arabic-first by default: ✅ directional APIs partially in use.

### Where Tilawa is weaker

- No formal window-size classification.
- No max-width tokens; content stretches on tablets.
- Shell is bottom-nav only; rail pattern missing.
- No text scaler clamp at app root.
- No `displayFeatures` handling.
- Legacy `screenutil_compat.dart` shim still present.
- Grid patterns are ad-hoc; no shared helper.
- RTL coverage is manual; no test matrix.

### What to improve first

Priority order by UX/perf impact vs. cost:

1. Breakpoints + window size (enables everything below).
2. Content max-widths (immediate tablet/foldable win).
3. Text scaler clamp (cheap accessibility insurance).
4. Adaptive shell (big tablet UX jump).
5. Grid helper (refactor reciters/bookmarks/history).
6. Display features handling (correctness on Fold-class devices).
7. ScreenUtil shim retirement (tech-debt paydown).
8. RTL test matrix (quality lock-in).

---

## 4. Phased rollout plan

Each phase is independently shippable, reversible, and scoped to 2–5 days of work. No phase requires the next.

### Phase 1 — Foundation: breakpoints + max-widths
**Build:**
- `TilawaBreakpoints` class + `TilawaWindowSize` enum + `BuildContext` extensions.
- Add `contentMaxWidth{Reader,Form,Media,Settings}` to `TilawaDesignTokens` (with `copyWith`/`lerp` updates).
- `TilawaContentBounds` layout primitive.

**Where:** `packages/ui_kit/lib/src/foundation/` (breakpoints + bounds widget, since both are layout primitives).

**UX gain:** None directly — this is the substrate.

**Perf risk:** None.

**Migration cost:** Zero. Purely additive.

**Exit criteria:** Breakpoints + tokens documented in the UI kit README; 1 screen migrated as reference (reciters).

---

### Phase 2 — Apply max-widths to the top 5 screens
**Build:** Wrap in `TilawaContentBounds`:
- Quran reader (using `contentMaxWidthReader`)
- Settings
- Share composers
- Bookmarks
- Reciters detail

**Where:** App, per-feature.

**UX gain:** Immediate improvement on tablets/foldables — content stops stretching.

**Perf risk:** Nil. One extra `ConstrainedBox` per screen.

**Migration cost:** Low — wrap-and-ship.

**Exit criteria:** Manual check on Pixel Fold (unfolded) and iPad simulator.

---

### Phase 3 — Text scaling clamp + MediaQuery hygiene
**Build:**
- App-root `MediaQuery.textScalerOf(context).clamp(1.0, 1.4)` via `MaterialApp.builder`.
- Reader carve-out: reader page does not consume the app-level clamp; it uses its own font-size preference.
- Codemod-style pass: replace `MediaQuery.of(context).size` → `MediaQuery.sizeOf(context)`. Replace `MediaQuery.of(context).viewInsets` → `MediaQuery.viewInsetsOf(context)`. Same for `textScaler`.

**Where:** App root + any file flagged by the audit.

**UX gain:** Accessibility correctness, no layout breaks at large text sizes.

**Perf risk:** Positive (narrower rebuild scope).

**Migration cost:** Medium mechanically, low cognitively.

**Exit criteria:** Accessibility smoke test at 1.4× passes on composer, settings, sheet UIs.

---

### Phase 4 — Adaptive shell
**Build:**
- `TilawaAdaptiveShell` organism in UI kit: compact → `NavigationBar`, medium → `NavigationRail`, expanded → extended rail.
- `displayFeatures` handling (skip hinges).
- Migrate the app's root navigation to use it.

**Where:** `packages/ui_kit/lib/src/organisms/` + `apps/tilawa/lib/screens/main_screen.dart`.

**UX gain:** Large. Tablet/foldable users get a proper persistent nav.

**Perf risk:** Low; shell rebuilds on size class change only (discrete transitions, not continuous).

**Migration cost:** Medium — touches main navigation plumbing. Reversible behind a feature flag.

**Exit criteria:** Ship behind a flag. Validate on Pixel Fold, iPad, Pixel 7. A/B if desired.

---

### Phase 5 — Grid helper + list migrations
**Build:**
- `TilawaContentGrid` organism over `SliverGridDelegateWithMaxCrossAxisExtent`.
- Migrate reciters, bookmarks, history, athkar categories, prayer times grid.

**Where:** UI kit organism + feature screens.

**UX gain:** Moderate. Grids behave correctly at every size; dense phones show 2 columns where appropriate.

**Perf risk:** None — slivers are cheaper than the current mix where nested.

**Migration cost:** One PR per feature, small each.

**Exit criteria:** No feature uses manual `crossAxisCount` branching.

---

### Phase 6 — ScreenUtil retirement + RTL test matrix
**Build:**
- Inventory every call-site of `screenutil_compat.dart`; replace with tokens / `LayoutBuilder` / fixed dimensions as appropriate.
- Delete the shim file when empty.
- Add golden tests for top 10 screens in RTL mode.

**Where:** App-wide.

**UX gain:** None directly; eliminates a correctness liability.

**Perf risk:** Positive (fewer `MediaQuery.of` chains).

**Migration cost:** The largest phase. Can be subdivided.

**Exit criteria:** `screenutil_compat.dart` deleted. RTL goldens committed and green in CI.

---

## 5. Final recommendation

### For the Tilawa UI Kit

Add **three new primitives** and nothing more:

1. **`TilawaBreakpoints` + `TilawaWindowSize` + `BuildContext` extensions** (foundation).
2. **`contentMaxWidth*` tokens** on `TilawaDesignTokens` + `TilawaContentBounds` (layout primitive).
3. **`TilawaAdaptiveShell` organism** + **`TilawaContentGrid`** (layout primitive / adaptive grid helper).

Policies codified in the kit's README:
- Sizing axes kept separate (table above).
- Reader geometry is physical and untouchable.
- Text scaler clamped at app root with reader carve-out.
- RTL-first: always directional APIs.

The kit should **not** ship any global scaling utility, density mode, or ScreenUtil analogue. That is the single most important "no" — it's how the shortcut sneaks back in.

### For the Tilawa app

Follow phases 1 → 6 in order. The first three phases can land in a single sprint with near-zero risk and deliver ~80% of the tablet/foldable UX improvement. Phases 4–6 are quality-of-life and tech-debt paydown.

Two guardrails in code review from day one:
- Reject new `MediaQuery.of(context).size.width * x` math.
- Reject new `EdgeInsets.only(left:/right:)` — require directional variants.

These two rules alone will prevent the common regressions this system is designed to stop.

---

## Appendix: responsive testing matrix

Minimum coverage for any responsive change:

- Phone portrait (compact)
- Phone landscape
- Foldable inner display (medium width)
- Tablet (expanded width)

Each surface should also verify its four UI states (loading / empty / error / content) at the compact and expanded ends of the matrix at minimum. Deeper device coverage is optional; this matrix is the floor, not the ceiling.

---

## Appendix: rejected alternatives

**`flutter_screenutil` (or similar)** — rejected. Global proportional scaling produces the exact bugs we're trying to avoid (see the Talabat-pattern analysis in `responsive_and_adaptive_guidelines.md`). Couples the whole app to one design size. Fragile under accessibility scale. No escape hatch when you need to *not* scale (reader).

**Custom density multiplier** — rejected for now. Adds a user-facing toggle we don't have evidence users want. Revisit if telemetry shows it.

**Per-breakpoint `TilawaDesignTokens` variants** — rejected for now. The MD3 guidance is spacing should be roughly stable across breakpoints; layout does the heavy lifting. Revisit only if a specific surface demands it.

**Multi-pane list/detail in Phase 1** — rejected. Correct pattern, but high UX design cost. Reserve the `secondaryPane` slot in the adaptive shell; ship the pattern when list/detail design work is done.
