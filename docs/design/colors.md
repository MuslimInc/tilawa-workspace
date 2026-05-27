# Tilawa colour system (design policy)

Tilawa's visual identity is **calm, modern, and premium**. The palette is intentionally small: one **brand-locked** accent, a quiet neutral surface ramp anchored on `#E5E5E0`, and three semantic colours. Decorative parallel palettes are *not* part of the system.

> Spec references: [`specs/012-visual-simplification/`](../../specs/012-visual-simplification/spec.md),
> [`specs/017-catalog-theme-freeze/`](../../specs/017-catalog-theme-freeze/spec.md).
> Implementation contract: [`packages/ui_kit/docs/design_system.md`](../../packages/ui_kit/docs/design_system.md).

## Brand lock (frozen 2026-05-25)

The brand colour is **fixed**. Users do not pick a primary. Production builds
always render Sage on the `#E5E5E0` neutral; the in-Settings colour picker is
retained behind `--dart-define=TILAWA_SHOW_COLOR_PICKER=true` for dev/QA only.

- **Primary (Ink):** Sage `#5E6D49` (`AppColors.primarySage` /
  `AppColors.defaultPrimary` / `PrimaryColorPreset.brandLocked`). Deepened
  from `#6F7F58` so white-on-primary clears the 4.5:1 WCAG AA bar.
- **Brand neutral:** `#E5E5E0` (`AppColors.lightSurfaceContainerHighBase` →
  `ColorScheme.surfaceContainerHigh`). The Vellum tier for chips, search
  fills, settings rows, and idle controls.
- **Light scaffold / surface:** `#FFFFFF` — not tinted by primary.
- **Ink (text):** `#000000` on white; body/mute/ash tiers in `AppColors`
  for secondary copy.
- **Runtime override:** `apps/tilawa/lib/features/theme/presentation/theme_state_material.dart`
  resolves `state.primaryColor` to the brand-locked value when
  `Env.kShowColorPicker` is `false`.

`AppTheme` does **not** primary-harmonize `surfaceContainerHigh` in light mode so
catalog search and filter chips stay Pinterest-neutral.

## The four colour roles

| Role | Examples (from `ColorScheme`) | Where to use it |
| ------ | ----------------------------- | --------------- |
| **Accent** (brand primary) | `primary`, `onPrimary`, `primaryContainer`, `onPrimaryContainer` | Switches ON, primary buttons, active nav, selected chips, progress fill, focus rings, settings tile icons, hero call-to-action backgrounds. **One per screen.** |
| **Surface** (neutral ramp) | `surface`, `surfaceContainerLow`, `surfaceContainerHigh`, `surfaceContainerHighest` | Scaffold, cards, sheets, bottom nav, dialogs, app bars. Quiet, near-monochrome. |
| **Foreground** | `onSurface`, `onSurfaceVariant` | Body and secondary text, icon colours, dividers when emphasised. |
| **Semantic** | `error` / `success` / `warning` from `AppColors` (mapped to `ColorScheme.error` etc.) | Destructive actions, validation, permission warnings. Never reused as decoration. |

A fifth role — **outline** (`outlineVariant`) — is the hairline that separates calm surfaces from each other. It is the *only* allowed border in product chrome.

## Allowed sources

1. **`AppColors`** (`packages/ui_kit`) — Brand presets, neutral ramp, `AppTheme` scheme bases, three semantic colours, and `notificationAccent`. **All hex values used to build** `ColorScheme` in `AppTheme` live here so there is one source of truth.
2. **`AppTheme`** — Builds `ThemeData` and `ColorScheme` from `AppColors` plus the user-selected primary. Defines how primary maps to containers (`_containerForPrimary`, `_blendSurfaceTowardPrimary`). Must not introduce raw `Color(0x…)` literals.
3. **`TilawaComponentTokens`** — Component-level fills and blends; formulas live in **token factories**, not in widgets.
4. **Feature palettes** — Closed-scope feature themes (Quran reader, share/reel composer): centralised palette files or `ThemeExtension`s.
5. **Exceptions** — `Colors.transparent`; the colour-picker tool data; tests / previews / debug; third-party packages.

## Policy: accent vs surfaces

- **User-selected primary** drives the **accent / interactive** role only (CTA,
  active nav, favorites, switch ON, progress fill) — **not** search fields,
  unselected filter chips, or catalog app bar backgrounds.
- **Stable neutral surfaces** (scaffold, fixed bottom nav chrome, cards, sheets,
  catalog headers) use **fixed primitives** or tiers derived from **neutral bases**
  in `AppColors`, not ad-hoc widget literals.
- **Semantic colours** are defined in `AppColors` and must not be derived from
  user primary.

### Catalog chrome (product pattern)

| UI | Source |
|----|--------|
| List app bar | `TilawaCatalogAppBar` + `TilawaAppBarSurface.parchment` |
| Search | `TilawaSearchFieldVariant.catalog` (white `surface` + hairline border) |
| Filters | `TilawaSelectionPillStyle.catalog` |
| Feature rows (e.g. reciter details) | `ColorScheme` neutral roles or `*CatalogChrome` helper — no new hex |
- **User-selected primary** drives the **accent / interactive** role only (CTA,
  active nav, favorites, switch ON, progress fill) — **not** search fields,
  unselected filter chips, or catalog app bar backgrounds.
- **Stable neutral surfaces** (scaffold, fixed bottom nav chrome, cards, sheets,
  catalog headers) use **fixed primitives** or tiers derived from **neutral bases**
  in `AppColors`, not ad-hoc widget literals.
- **Semantic colours** are defined in `AppColors` and must not be derived from
  user primary.

### Catalog chrome (product pattern)

| UI | Source |
|----|--------|
| List app bar | `TilawaCatalogAppBar` + `TilawaAppBarSurface.parchment` |
| Search | `TilawaSearchFieldVariant.catalog` (white `surface` + hairline border) |
| Filters | `TilawaSelectionPillStyle.catalog` |
| Feature rows (e.g. reciter details) | `ColorScheme` neutral roles or `*CatalogChrome` helper — no new hex |

## Gradients

Gradients are **not** part of the product visual system. They are reserved for:

1. **The colour-picker tool** (`features/color_picker/`) — gradient *is* the tool.
2. **Share / reel composer output** (`features/share/presentation/widgets/page_passage_card_renderer.dart`, `share_audio_config_sheet.dart`) — generated poster artwork, not chrome.
3. **`CustomPainter` shaders** — e.g. the Qibla compass needle.
4. **Focused state badges in molecules** (e.g. `tilawa_count_progress_ring`) — narrow, indicator-only use.
5. **Preview dev tools** (`atoms_preview.dart`, `organisms_preview.dart`) — non-production.

Outside of these, gradients are forbidden in product UI. Cards, app bars, headers, banners, hero panels are flat.

## Forbidden in product widgets

- Raw `Color(0x…)` for product chrome.
- `LinearGradient` / `RadialGradient` / `SweepGradient` in product chrome (see the allow-list above).
- Ad-hoc `Color.lerp` / `Color.alphaBlend` in widgets for persistent backgrounds — use tokens.
- Duplicating hex values that already exist in `AppColors` or `AppTheme` assembly.
- Parallel "category palettes" (Settings used to have eleven distinct hues — removed).
- "Decorative" `Positioned` circles, oversized background icons, or other ornament that does not serve content.

## Elevation

A card picks **one** depth cue, not all of them at once:

- **Raised** — solid surface fill + hairline outline + soft drop shadow. Default for top-level cards on a scaffold.
- **Flat** — solid surface fill + hairline outline (no shadow). For cards nested inside another elevated surface.
- **Outline** — hairline outline only, transparent fill. Use sparingly.

These map directly to `TilawaCardSurface { raised, flat, outline }` on `TilawaCard`.

## Migration phases (reference)

- **C1**: Centralise `AppTheme` literals in `AppColors`; document policy.
- **C2**: Move widget-level blends into tokens; feature palettes; app-wide cleanup.
- **C3 (this change, 2026-05-15)**: Strip product-chrome gradients; collapse Settings category palette; introduce `TilawaCardSurface`.

## Related tests

- `packages/ui_kit/test/theme/app_theme_color_roles_test.dart` — contrast, Pinterest neutrals, preset surface no-op.
- `packages/ui_kit/test/theme/app_theme_spec_compliance_test.dart` — M3 extensions, transparent `surfaceTint`, app bar = `surface`.
- `packages/ui_kit/test/goldens/` — atoms, molecules, organisms, and foundation catalog chrome goldens.

Regenerate after intentional visual changes:

```bash
cd packages/ui_kit && flutter test test/goldens/ --update-goldens
```
- `packages/ui_kit/test/theme/app_theme_color_roles_test.dart` — contrast, Pinterest neutrals, preset surface no-op.
- `packages/ui_kit/test/theme/app_theme_spec_compliance_test.dart` — M3 extensions, transparent `surfaceTint`, app bar = `surface`.
- `packages/ui_kit/test/goldens/` — atoms, molecules, organisms, and foundation catalog chrome goldens.

Regenerate after intentional visual changes:

```bash
cd packages/ui_kit && flutter test test/goldens/ --update-goldens
```
