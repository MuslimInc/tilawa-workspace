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
| This file | Implementation contracts for agents and reviewers |
| Source of truth | `lib/src/foundation/app_colors.dart`, `app_theme.dart`, `component_tokens/` |

External moodboards live under `design-md/` — inspiration only, never pasted
into feature code.

---

## 1. Architecture (scalable atomic design)

```
foundation/     AppColors, AppTheme, TilawaDesignTokens, TilawaComponentTokens
atoms/          TilawaButton, TilawaCard, TilawaTextField, …
molecules/      TilawaSearchField, TilawaSelectionPill, TilawaCatalogAppBar, …
organisms/      TilawaMediaPlayerBar, TilawaSettingsGroup, …
```

**Rules for growth**

1. **One source of hex** — `AppColors` only; widgets use `ColorScheme` +
   `TilawaComponentTokens`.
2. **Token factories** — light/dark component colours live in
   `component_tokens/*_tokens.dart`, not in widgets.
3. **Public API surface** — export through `tilawa_ui_kit.dart` / feature
   barrels; document new public widgets with dartdoc + golden + preview when
   visual.
4. **No parallel palettes** — category hues, decorative gradients, and
   per-screen hex are forbidden in product chrome (see colours doc).

---

## 2. Theme freeze — Pinterest catalog chrome (light)

Default primary: **coral** `#E60023` (`AppColors.defaultPrimary`).

**Accent usage (Pinterest rule):** coral (or user primary) for **one** emphasis
per screen — primary CTA, active bottom nav, hearts/favorites, progress fill,
switch ON. **Not** for scaffold, app bars, search fields, filter chips, or list
row chrome.

### Light neutral ramp (not primary-harmonized)

| `AppColors` | Hex | `ColorScheme` / usage |
|-------------|-----|------------------------|
| `lightBackground` | `#FFFFFF` | Scaffold, `surface` |
| `lightInk` | `#000000` | `onSurface` |
| `lightBody` | `#33332E` | Secondary body |
| `lightMute` | `#62625B` | Muted labels |
| `lightAsh` | `#91918C` | Hints / idle icons |
| `lightSurfaceContainer` | `#F6F6F3` | `surfaceContainer` |
| `lightSurfaceContainerHighBase` | `#E5E5E0` | Idle chips, search fill, `surfaceContainerHigh` |
| `lightSurfaceContainerHighestBase` | `#DADAD3` | Hairline tier |
| `lightHairline` | `#DADAD3` | `outlineVariant` |

`AppTheme` sets **`surfaceTint` → transparent** on cards, dialogs, sheets, and
app bars so Material 3 does not wash neutrals with the user primary.

### Dark mode

Deep green-tinted neutral stack (`darkBackground` …); idle chips use
`catalogFilterUnselectedDark` (`#3A3936`) without primary harmonization on
`surfaceContainerHigh`. Optional **true-black** preset for OLED.

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
| Filters | `TilawaSelectionPillStyle.catalog` — selected: `onSurface` fill + `surface` label; unselected: `surfaceContainerHigh` |
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
| `chip` / selection | Catalog pills use `ColorScheme` roles above |
| `segmentedControl` | Neutral track; accent only on selected segment when product requires |

Feature-specific neutral chrome (e.g. reciter details moshaf row) may use a
local `*CatalogChrome` helper that reads the same `ColorScheme` roles — do not
duplicate hex.

---

## 5. Testing contract

| Suite | Path | Purpose |
|-------|------|---------|
| Colour roles | `test/theme/app_theme_color_roles_test.dart` | Contrast, Pinterest neutrals, preset no-op on surfaces |
| DESIGN compliance | `test/theme/app_theme_spec_compliance_test.dart` | M3 extensions, transparent elevation tint, app bar = `surface` |
| Goldens | `test/goldens/` | Visual regression (Alchemist); default primary in `TilawaPreviewWrapper` |
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
- [ ] `DESIGN.md` §2 neutrals and § catalog chrome match `AppColors`
- [ ] `docs/design/colors.md` policy unchanged or updated in same PR
- [ ] No new raw `Color(0x…)` in `apps/tilawa/lib/features/` chrome
- [ ] Accent still sparse: search/chips/app bars remain neutral in light mode

---

## 7. Related specs

| Spec | Topic |
|------|--------|
| [`specs/012-visual-simplification/`](../../../specs/012-visual-simplification/spec.md) | Calm palette, no decorative gradients |
| [`specs/013-token-consistency-pass/`](../../../specs/013-token-consistency-pass/spec.md) | Motion/type/feedback token migration |
| [`specs/017-catalog-theme-freeze/`](../../../specs/017-catalog-theme-freeze/spec.md) | Freeze acceptance criteria |
| [`specs/006-ui-kit-expansion/ui-kit-inventory.md`](../../../specs/006-ui-kit-expansion/ui-kit-inventory.md) | Component inventory |
