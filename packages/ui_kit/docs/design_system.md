# Tilawa UI Kit — design system (frozen baseline)

**Status:** Production baseline frozen **2026-05-23**. Treat tokens, light
neutral ramp, and catalog chrome as stable. Changes are limited to:

- New atoms/molecules/organisms (atomic design additions)
- Critical bug fixes (contrast, layout overflow, accessibility regressions)
- Documented exceptions (Quran reader palette, share composer output)

**Canonical stack (read in order):**

| Layer | Document / code |
|-------|-----------------|
| Product intent | [`docs/tilawa_brand.md`](../../../docs/tilawa_brand.md) |
| Human spec | [`DESIGN.md`](../../../DESIGN.md) (repo root) |
| Colour policy | [`docs/design/colors.md`](../../../docs/design/colors.md) |
| Colour architecture | [`docs/design/color_architecture.md`](../../../docs/design/color_architecture.md) |
| This file | Implementation contracts for agents and reviewers |
| Source of truth | `lib/src/foundation/app_colors.dart`, `app_theme.dart`, `component_tokens/` |

External moodboards live under `design-md/` — inspiration only, never pasted
into feature code.

---

## 1. Architecture (scalable atomic design)

```
foundation/     AppColors, AppTheme, MeMuslimDesignTokens, TilawaInputStyle, …
atoms/          TilawaButton, TilawaCard, TilawaTextField, TilawaReadOnlyField, …
molecules/      TilawaSearchField, TilawaSelectionPill, TilawaCatalogAppBar, …
organisms/      TilawaMediaPlayerBar, TilawaSettingsGroup, …
```

**Rules for growth**

1. **One source of hex** — `AppColors` only; widgets use `ColorScheme` +
   `MeMuslimComponentTokens`.
2. **Token factories** — light/dark component colours live in
   `component_tokens/*_tokens.dart`, not in widgets.
3. **Public API surface** — export through `tilawa_ui_kit.dart` / feature
   barrels; document new public widgets with dartdoc + golden + preview when
   visual.
4. **No parallel palettes** — category hues, decorative gradients, and
   per-screen hex are forbidden in product chrome (see colours doc).

### Automated component boundary

Product code must use the UI Kit component whenever one exists. In particular,
use `TilawaAppBar`, `TilawaCatalogAppBar`, or `TilawaSliverAppBar` instead of
Flutter's raw `AppBar` and `SliverAppBar`. The UI Kit package may use framework
widgets internally to implement those abstractions.

Run `melos run ui:lint` locally. The same guard is blocking in pull requests.
It scans production Dart sources, reports the file and line, and rejects new
raw component usage. Pre-existing violations are tracked by a non-increasing
baseline in `tool/ui_kit_guard.dart`; remove baseline entries as those screens
are migrated. If the UI Kit lacks a suitable component, add and test one at the
smallest correct Atomic Design level instead of bypassing the guard.

---

## 2. Theme freeze — calm catalog chrome (light)

Default primary: **brand green** `#1DAB61` (`AppColors.brandActionGreen` /
`AppColors.defaultPrimary`), **brand-locked** for production per
`PrimaryColorPreset.brandGreen` / `Env.kShowColorPicker`.
Legacy presets (coral, teal, sage, brown, purple) remain only for the dev/QA
color picker and persisted user choices — **do not reintroduce purple** or ship
new UI assuming a user-picked primary other than green.

**Accent usage (one-accent rule):** Green primary for **one** emphasis per screen
— primary CTA, active bottom nav, selected pills/segments, progress fill,
switch ON. **Not** for scaffold fills (use the neutral canvas).

### Light neutral ramp (warm near-white canvas + white cards)

60-30-10: canvas ~60% (`lightCanvas`), elevated surfaces ~30% (`lightSurface`, chips), accent ~10% (`primary`). Scaffold stays porcelain-green near-white — not pure white.

| `AppColors` | Hex | `ColorScheme` / usage |
|-------------|-----|------------------------|
| `lightCanvas` / `lightBackground` | `#F3F6F4` | Scaffold, `surfaceContainerLowest` |
| `lightSurface` | `#FFFFFF` | Cards, sheets, dialogs |
| `lightInk` | `#1A2E24` | `onSurface` |
| `lightMute` | `#6B7F74` | Muted labels (`onSurfaceVariant`) |
| `lightSurfaceContainerHighBase` | `#F0F7F2` | Idle chips, `surfaceContainerHigh` |
| `featuredGradientStart` / `End` | `#FFD28E` / `#FF9E44` | Last Read / hero gold cards (via `productColors`) |
| `brandActionGreen` / `defaultPrimary` | `#1DAB61` | `primary` — CTAs, active nav, selected controls |
| `lightSchemeOnPrimary` | `#003317` | `onPrimary` on green fills |

### Product semantics

`MeMuslimProductColors` (`Theme.of(context).productColors`) exposes prayer, Quran, player, hub, and brand-lock roles. Feature code should prefer this over `AppColors`.

`AppTheme` sets **`surfaceTint` → transparent** on cards, dialogs, sheets, and
app bars so Material 3 does not wash neutrals with the user primary.

### Dark mode

Deep green-tinted neutral stack (`darkBackground` …); idle chips use
`catalogFilterUnselectedDark` (`#353E3A`) without primary harmonization on
`surfaceContainerHigh`. Optional **true-black** preset for OLED.

| Semantic | Dark hex | Access |
|----------|----------|--------|
| Success | `#6BCF7F` | `colorScheme.success` (`TilawaStatusColors`) |
| Warning | `#FB923C` | `colorScheme.warning` |
| Error | `#FFB4AB` | `colorScheme.error` |

Light-mode success/warning stay at `#43A047` / `#C2410C`; dark tones are
lifted in the same hue family for WCAG 3:1 on green-tinted surfaces.

### Depth and touch (`MeMuslimDesignTokens`)

**Layered elevation (added 2026-07-11):** raised surfaces take a
`MeMuslimElevationX` tier — a tight *contact* shadow plus a soft *ambient*
bloom, tinted with `ColorScheme.shadow` (brand ink, not gray). Do not
hand-roll `BoxShadow` lists on new surfaces.

| Tier | Layers (alpha / blur / y-offset) | Use |
|------|----------------------------------|-----|
| `elevationRaised(colorScheme.shadow)` | 0.05 / 3 / 1 + 0.07 / 24 / 10 | Resting cards — `TilawaCard` raised, settings group panels, capability action cards |
| `elevationFloating(colorScheme.shadow)` | 0.06 / 6 / 2 + 0.11 / 32 / 14 | Floating chrome — hero summaries, pinned bars, dialogs |

Every shadow value (legacy and tiers) scales with `kElevationMultiplier`
(currently `1.0`) — a single device-tuning knob; safe range ≈ 0.8–1.3.

Legacy single-shadow tokens stay for existing chrome (search field, collapsed
header); prefer the tiers for new work:

| Token | Value | Use |
|-------|-------|-----|
| `opacityShadow` | 0.04 | Legacy single shadow on raised chips |
| `opacityShadowStrong` | 0.08 | Legacy floating chrome (nav, player) |
| `shadowOffsetSmall` / `shadowOffsetMedium` | `(0, 1.5)` / `(0, 3)` | Legacy shadow offsets |
| `blurShadow` | 12 | Legacy shadow blur |
| `borderWidthThin` | 0.5 | Hairlines |
| `minInteractiveDimension` | 48 dp | Minimum hit target (`kMeMuslimMinInteractiveDimension`) |

Access tokens via `Theme.of(context).tokens` or `context.tokens`.

---

## 3. Catalog header pattern

Use **`TilawaCatalogAppBar`** on list/catalog screens (Reciters, Favorites,
Settings lists, Athkar, etc.).

| Piece | Contract |
|-------|----------|
| Surface | `TilawaAppBarSurface.parchment` (white / dark surface) |
| Title | Left-aligned, `titleLarge` w700 |
| Height | `TilawaAppBarConfig.catalogTitleOnlyHeight`, `catalogTitleAndSearchHeight`, `catalogTitleSearchAndFilterRowHeight` — **always** match `preferredHeight` to laid-out content (uses `TextPainter` + device-pixel ceil) |
| Search | `TilawaSearchField` default variant **catalog**; wrap row in `TilawaSearchFieldSlot` only when **not** inside `TilawaCatalogAppBar.bottomContent` |
| Filters | `TilawaSelectionPillStyle.catalog` — selected: `primary` fill + `onPrimary` label; unselected: `surfaceContainerHigh` |
| Back | `automaticallyImplyLeading: true` on pushed routes; `onBackPressed: () => context.pop()` with GoRouter |

**Back in title row:** `TilawaAppBarChrome.resolveCatalogRowLeading` /
`catalogBackButton` — compact `TilawaBackButton` without double start inset.

**Do not** stack `PreferredSize` + status bar on top of catalog height helpers
(double safe-area padding).

---

## 4. Component token highlights (light catalog)

| Family | Catalog behaviour |
|--------|-------------------|
| `searchField` | Catalog variant: white `surface` fill + `outlineVariant` border — not `primaryContainer` |
| `chip` / selection | Catalog pills: light = `primary` fill + `onPrimary` label; dark = warm lifted `surfaceContainerHighest` + `onSurface` label |
| `segmentedControl` | Neutral track; accent only on selected segment when product requires |

Feature-specific neutral chrome (e.g. reciter details moshaf row) may use a
local `*CatalogChrome` helper that reads the same `ColorScheme` roles — do not
duplicate hex.

---

## 4.1 Interaction feedback (press / focus)

**Rule:** Interactive surfaces use a soft splash/highlight/state-layer effect by
default. Press-scale is not the default because it can look unstable on clipped
or rounded surfaces.

| Mechanism | Where | Tokens |
|-----------|-------|--------|
| Ink splash | `TilawaInteractiveSurface` (default) | `inkSplashAlpha` (0.08) on `ColorScheme.primary` |
| Ink highlight | `TilawaInteractiveSurface` (default) | `inkHighlightAlpha` (0.04) on `ColorScheme.onSurface` |
| State-layer wash | `TilawaInteractiveSurface` (default) | `stateLayerPressed` (0.12), `stateLayerHover` (0.08), `stateLayerFocused` (0.12) on `ColorScheme.onSurface` |
| Motion | Press/hover/focus transitions | `durationFast` (200 ms) |
| Material overlay | `TilawaButton` | M3 pressed 10% on label colour; focus ring via `focusRingWidth` |

**Nested taps on cards:** enabled nested controls own their action; disabled
controls are dead zones; parent `TilawaCard` only reacts from blank areas (see
`CLAUDE.md`).

### Motion curves

Easing is tokenized alongside durations — do not write raw `Curves.*` in kit
widgets:

| Token | Value | Use |
|-------|-------|-----|
| `curveStandard` | `Curves.easeOut` | Chrome fades, reveals, in-place opacity shifts |
| `curveEmphasized` | `Curves.easeOutCubic` | Spatial movement — slides, expands, scroll-to |
| `curveSymmetric` | `Curves.easeInOut` | Cross-fades and switchers where enter/exit mirror |

For `CurvedAnimation`s created in `initState`, sync the curve from tokens in
`didChangeDependencies` (see `TilawaFeedbackHost`).

---

## 4.2 Loading states (skeletons)

**Rule:** Regions that load structured content show a **skeleton mirroring the
loaded layout**, not a bare spinner. Spinners remain for indeterminate work
without stable geometry (submissions, refreshes).

| Piece | Contract |
|-------|----------|
| Scope | `TilawaSkeleton` — one shared shimmer sweep per placeholder; freezes to static blocks under reduced motion; `semanticLabel` announces the region |
| Bones | `TilawaSkeletonBone` (block / `.circle`), `TilawaSkeletonLine` (text-style-measured height) |
| Appearance | `TilawaSkeletonTokens` — `onSurface` at `baseAlpha` (0.08) / `highlightAlpha` (0.16); band sweeps in reading direction (RTL-aware) |
| Region swap | `TilawaAsyncContent` cross-fades loading → content/empty/error over `durationFast` (instant under reduced motion) |

`TilawaCapabilityActionCardSkeleton` is the reference composition (measured
bones matching loaded copy heights).

---

## 4.3 Call to Action (CTA) Guidelines

**Rule:** Primary CTAs must feel substantial but should never stretch arbitrarily to unbounded screen edges on tablets. Use the appropriate design-system constraints for the context.

| Context | Recommended Pattern | Constraints & Behaviors |
|---------|---------------------|--------------------------|
| **Empty states** | `TilawaIllustratedState` / `TilawaEmptyState` | Handled natively. Buttons use `actionMinWidth` (240dp) and `actionMaxWidth` (320dp). Hugs content organically while preventing overstretch on tablets. |
| **Pinned bottom** | `TilawaBottomActionInset` | Wrap the bottom area in `TilawaBottomActionInset(maxWidthKind: TilawaContentKind.form)`. This expands cleanly on phones but restricts stretch on large tablets, keeping thumb reach safe. |
| **Inline (cards/dialogs)** | `TilawaButton(isFullWidth: true)` | Relies on the parent container (e.g. Card padding or Dialog width). Do **not** wrap in `SizedBox(width: double.infinity)` which forcefully breaks out of responsive constraints. |

**Important notes:**
- Avoid manual safe area logic or arbitrary `double.infinity` wrappers.
- `TilawaButton` scales nicely for text wrapping and RTL alignment inherently. Let the button hug or fill its parent constraint.

---

## 5. Testing contract

| Suite | Path | Purpose |
|-------|------|---------|
| Colour roles | `test/theme/app_theme_color_roles_test.dart` | Contrast, cool neutral ramp, preset no-op on surfaces |
| DESIGN compliance | `test/theme/app_theme_spec_compliance_test.dart` | M3 extensions, transparent elevation tint, app bar = `surface` |
| Goldens | `test/goldens/` | Visual regression (Alchemist); default primary in `TilawaPreviewWrapper` |
| Toast goldens | `test/goldens/tilawa_toast_goldens_test.dart` | `TilawaToast` variants, actionable, layout, edge cases |
| Review checklist | `test/goldens/REVIEW_CHECKLIST.md` | Human sign-off after `--update-goldens` |

Regenerate goldens only when visuals intentionally change:

```bash
cd packages/ui_kit
flutter test test/goldens/ --update-goldens
```

Previews and goldens set `AppTheme.useGoogleFonts = false` and
`GoogleFonts.config.allowRuntimeFetching = false` for CI stability.

---

## 6. Maintainer checklist (before merging theme changes)

- [ ] `dart analyze` clean on `packages/ui_kit`
- [ ] `flutter test test/theme/` and `flutter test test/goldens/`
- [ ] `DESIGN.md` frontmatter and § catalog chrome match `AppColors` / `MeMuslimDesignTokens`
- [ ] `docs/design/colors.md` policy unchanged or updated in same PR
- [ ] No new raw `Color(0x…)` in `apps/tilawa/lib/features/` chrome
- [ ] Accent still sparse: search/chips/app bars remain neutral in light mode

---

## 7. Related specs

| Spec | Topic |
|------|--------|
| [`docs/UI_KIT_INPUT_SYSTEM.md`](../../../docs/UI_KIT_INPUT_SYSTEM.md) | Input SSOT (`TilawaInputStyle`, `TilawaFieldShell`, kit atoms) |
| [`specs/012-visual-simplification/`](../../../specs/012-visual-simplification/spec.md) | Calm palette, no decorative gradients |
| [`specs/013-token-consistency-pass/`](../../../specs/013-token-consistency-pass/spec.md) | Motion/type/feedback token migration |
| [`feedback_system.md`](feedback_system.md) | Toast vs inline validation channel rules |
| [`specs/017-catalog-theme-freeze/`](../../../specs/017-catalog-theme-freeze/spec.md) | Freeze acceptance criteria |
| [`specs/006-ui-kit-expansion/ui-kit-inventory.md`](../../../specs/006-ui-kit-expansion/ui-kit-inventory.md) | Component inventory |
