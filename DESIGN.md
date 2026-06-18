# Tilawa — DESIGN.md

Design system snapshot for **Tilawa UI Kit** (`packages/ui_kit`) and the **Tilawa app** (`apps/tilawa`). This document is for humans and coding agents. Implementation truth lives in code; update this file when tokens or theme behavior change in meaningful ways.

**Companion:** `AGENTS.md` (how to build). This file is how the product should **look and feel**.
**Brand intent layer:** [`docs/tilawa_brand.md`](docs/tilawa_brand.md) — Behance warm lifestyle reference (parchment, brown ink, gold featured cards). When intent and implementation conflict, this file wins on implementation; [`docs/tilawa_brand.md`](docs/tilawa_brand.md) wins on intent.
**Voluntary support (monetization UX):** [`specs/016-support-tilawa/spec.md`](specs/016-support-tilawa/spec.md) — product ethics and entry points; [`packages/ui_kit/docs/support_visual_system.md`](packages/ui_kit/docs/support_visual_system.md) — support screen visuals.

---

## 1. Visual theme and atmosphere

- **Material 3** via **FlexColorScheme**: surfaces, containers, and component themes are assembled in `AppTheme` and refined with Tilawa-specific ramps (`AppColors`).
- **Calm, content-first:** small palette, quiet warm neutrals, one **user-selectable primary** accent from **curated presets** (default **warm brown** `#8B5E3C`); optional **custom** primary appears **in the same primary-color list** in Settings and may be **soft-clamped in light mode** for contrast (see `AppTheme._safePrimaryForLight`). Surfaces are parchment cream in light mode; dark mode uses a deep green-tinted neutral stack (with an optional **true-black / OLED** preset).
- **Readable for Arabic:** line-height token `textHeightLoose` supports dense script in readers and lists (see `TilawaDesignTokens`).
- **Comfortable density:** `FlexColorScheme.comfortablePlatformDensity` (not compact VisualDensity).
- **Premium depth:** layered shadows (`opacityShadow` / `opacityShadowStrong`), optional **glass** tokens (`blurGlass`, `opacityGlass`) for overlays and chrome — use consistently, not everywhere.

---

## 2. Color palette and roles

### User-selectable primary (accent)

Offered in app settings (`PrimaryColorPreset`). Default aligns with the warm mockup brown **#8B5E3C**. **Custom** hex is the last row in the primary-color sheet; extreme values may be adjusted in light theme for readability.

| Preset | Hex (reference) | Notes |
|--------|-----------------|--------|
| Coral | `#E60023` | Accent option; use sparingly |
| Teal | `#1AADC5` | Legacy Tilawa brand teal |
| Sage | `#219653` | Scholarly green; legacy preset |
| Forest (picker) | `#2D6B47` | Dev/QA preset; deep green |
| Brown (default) | `#8B5E3C` | Warm mockup brown; brand-locked |
| Purple | `#7A5C89` | Muted purple |

Additional constants exist in `AppColors` (e.g. gold) for Flex **secondary/tertiary** assembly or migration; product UI should use **`ColorScheme`**, not copy arbitrary hexes.

### Fixed semantic colors (`AppColors`)

| Role | Light hex | Dark hex (via `ColorScheme.success` / `.warning`) | Usage |
|------|-----------|---------------------------------------------------|--------|
| Error | `#DC2626` | `#FFB4AB` (`darkSchemeError`) | Destructive / failures |
| Success | `#43A047` | `#6BCF7F` (`successDark`) | Positive outcomes |
| Warning | `#C2410C` | `#FB923C` (`warningDark`) | Caution (deep orange, not gold) |

Dark success/warning are brightness-tuned in `TilawaStatusColors` so status
borders and icons clear WCAG 3:1 on green-tinted surfaces.

### Neutral surfaces (light) — warm parchment canvas

Light surfaces use a **warm parchment** family — cream canvas, white cards, beige idle chips.

| Token / role | Hex (base) | Notes |
|--------------|------------|--------|
| Canvas / scaffold | `#F7F7F5` | `lightCanvas` / `lightBackground` |
| Surface (cards, sheets) | `#FFFFFF` | `lightSurface` |
| Ink / onSurface | `#30343C` | `lightInk` |
| Body / mute / ash | `#30343C`, `#78736E`, `#A89B8A` | Secondary copy |
| Container | `#F7F7F5` | `lightSurfaceContainer` (matches canvas) |
| High (idle chips, search fill) | `#EFEDE8` | `lightSurfaceContainerHighBase` → `surfaceContainerHigh` |
| Highest / hairline | `#E4E0D8` | Dividers, `outlineVariant` |
| Outline (strong) | `#D5CEC3` | `lightOutline` |

Featured cards (Last Read) use gold gradient `#FFD28E` → `#FF9E44` via `AppColors.featuredGradientStart` / `featuredGradientEnd`.

See [`packages/ui_kit/docs/design_system.md`](packages/ui_kit/docs/design_system.md) and [`specs/017-catalog-theme-freeze/spec.md`](specs/017-catalog-theme-freeze/spec.md).

### Neutral surfaces (dark, standard)

Approximately: background `#101816`, surface `#16201D`, containers stepping through `#1C2925` → higher tiers with optional primary blend.

### True-black (OLED) mode

Separate ramp (`darkTrueBlack*` in `AppColors`) when `AppThemePreset.trueBlack` is active.

### Secondary / tertiary (Flex assembly)

- Secondary reference: `#65734F`
- Tertiary reference: `#8C681F` (gold tone for scheme harmony)

**Rule:** Widgets consume **`Theme.of(context).colorScheme`** and **`theme.componentTokens`**, not `AppColors` directly (except rare platform-fixed cases like notification accent, documented in code).

---

## 3. Typography

- **Primary font:** **Alexandria** via **Google Fonts** when `AppTheme.useGoogleFonts` is true (tests/previews may disable for stability).
- **Text theme:** Built from `GoogleFonts.alexandriaTextTheme()` and wired through Flex light/dark theme factories in `AppTheme.getLightTheme` / `getDarkTheme`.
- **Hierarchy:** Follow Material 3 `TextTheme` roles (`display*`, `title*`, `body*`, `label*`). Prefer `Theme.of(context).textTheme` over hard-coded sizes.
- **App text scaling:** `MaterialApp` builder clamps `TextScaler`` between **1.0 and 1.4** (`tilawa_app.dart`) so layouts stay predictable while allowing moderate accessibility scaling.

---

## 4. Spacing, radii, and motion (`TilawaDesignTokens`)

Registered as a `ThemeExtension` on `ThemeData` (access: `Theme.of(context).extension<TilawaDesignTokens>()` or project extensions such as `context.tokens`).

| Category | Values (default) |
|----------|------------------|
| Space scale | 2, 4, 8, 12, 16, 24 |
| Corner radii | 8, 12, 16, 24 |
| Icon sizes | 12, 16, 20, 24, 42, 44 |
| Min touch target | **44 dp** (`kTilawaMinInteractiveDimension`) |
| Durations | 200 ms / 400 ms / 600 ms (fast / medium / slow) |
| Line height (loose) | 2.0 for dense Arabic-friendly layouts |

### Content max widths (`TilawaContentBounds`)

| Kind | Max width (px) | Typical use |
|------|----------------|-------------|
| Reader | 720 | Quran reader body |
| Form | 560 | Sheets, dialogs, auth |
| Media | 1200 | Share / gallery style |
| Settings | 760 | Settings detail columns |

---

## 5. Layout and breakpoints

- **Window size classes** (`TilawaBreakpoints` / `TilawaWindowSize`): narrow `< 600`, medium `< 840`, expanded `< 1200`, large `≥ 1200`.
- **Branch on `context.windowSize` (or helpers)** instead of raw widths for shell and two-pane patterns.
- **Adaptive shell** (`TilawaAdaptiveShell` + `componentTokens.adaptiveShell`): main app chrome — bottom navigation, optional rail, **labels shown** on phone bottom nav; system navigation bar color is synced to match floating bottom nav for visual continuity (`_DefaultRouteSystemUiOverlay` in `tilawa_app.dart`).

---

## 6. Components (`TilawaComponentTokens`)

Component styling is tokenized per family (atoms → organisms). Factories: `TilawaComponentTokens.light` / `.dark` with live `ColorScheme`.

Includes (non-exhaustive): section titles, sheet handle, **card**, icon box, loading indicator, dividers, empty/error states, alphabet scrollbar, feedback strip, **glass panel**, icon action button, **chip**, **segmented control**, seek bar, search field, count progress ring, **player background**, footer bar, **media player bar**, **adaptive shell**, settings group, immersive composer, icon toggle, permission banner, prayer alert row, bottom sheet scaffold.

**Rule:** Prefer **`context.theme.componentTokens.<family>`** (or equivalent project API) over one-off `BoxDecoration` values when building kit-aligned UI.

### Catalog chrome (frozen pattern)

List and catalog screens use **`TilawaCatalogAppBar`** (`packages/ui_kit/lib/src/molecules/tilawa_catalog_app_bar.dart`):

- **Surface:** `TilawaAppBarSurface.parchment` (white light / dark `surface`).
- **Title:** left-aligned, bold `titleLarge`.
- **Heights:** `TilawaAppBarConfig.catalogTitleOnlyHeight`, `catalogTitleAndSearchHeight`, `catalogTitleSearchAndFilterRowHeight` — `preferredSize` must match laid-out content (device-pixel ceil).
- **Search:** `TilawaSearchField` (default **catalog** variant); white `surface` fill and hairline border — not primary-tinted.
- **Filters:** `TilawaSelectionPillStyle.catalog` — selected `primary` fill + `onPrimary` label; unselected `surfaceContainerHigh`.
- **Back on pushed routes:** `automaticallyImplyLeading: true` and `onBackPressed: () => context.pop()` with GoRouter; compact leading via `TilawaAppBarChrome.resolveCatalogRowLeading`.

**Accent discipline:** user primary is for CTAs, active nav, favorites, switch ON — **not** catalog search/chip/app-bar backgrounds.

---

## 7. Depth and elevation

- **Shadows:** `BoxShadow` alphas **0.18** (default elevated) and **0.28** (strong / floating), with small vertical offsets (2 and 4 logical px).
- **Borders:** thin hairline **0.5** where tokens apply.
- **Material elevation tint:** Component `surfaceTintColor` is driven to **transparent** on cards, dialogs, and sheets in `AppTheme._applySurfaceScale` for a cleaner, less “washed” M3 look.
- **Switches:** Custom OFF-track treatment blends outline into `surfaceContainerLow` so purple/teal primaries do not tint the track mud.

---

## 8. Tilawa app integration

- **Theme state:** `ThemeCubit` supplies `primaryColor`, preset source, `themeMode`, and `AppThemePreset` (including true black).
- **Themes:** `AppTheme.getLightTheme` / `getDarkTheme` with extra extensions — e.g. **`QuranReaderTheme`** for reader-specific overrides.
- **Localization:** `MaterialApp.router` uses generated `AppLocalizations` + additional delegates (e.g. `quran_image` l10n).
- **Scrim / overlap:** Screens that use **`NestedScrollView`** + **`SliverOverlapAbsorber` / `SliverOverlapInjector`** (e.g. prayer times) must keep test harnesses consistent with that structure.

---

## 9. Support Tilawa surfaces (voluntary contribution)

Tilawa uses **Support Tilawa**, not “Premium” or “Pro,” for optional financial
contribution. Full product rules live in
[`specs/016-support-tilawa/spec.md`](specs/016-support-tilawa/spec.md); visual
detail in
[`packages/ui_kit/docs/support_visual_system.md`](packages/ui_kit/docs/support_visual_system.md).

### Terminology (user-facing)

| Avoid | Use |
|-------|-----|
| Premium, Pro, VIP, Unlock, Upgrade | Support Tilawa, Supporter, Help keep Tilawa free |

### UX placement (allowed vs forbidden)

| Allowed | Forbidden |
|---------|-----------|
| Settings, About, Profile | Quran reader, prayer times, athkar, onboarding, cold-start popups |

### Visual rules (summary)

- **Calm:** `surfaceContainerLow`, hairlines, one **Ink** (`primary`) CTA per screen.
- **No gold pay chrome:** Gilding (`tertiary`) is not for purchase buttons (see brand doc §3).
- **No aggressive success UI:** `TilawaEmptyState` thank-you — no confetti, gold gradients, or “benefits unlocked” lists.
- **Transparent:** impact bullets + “Payments processed by Google Play” footer.

### MVP implementation constraints (design-relevant)

- Android + Google Play consumables only; prices from Play strings, not hard-coded currency.
- Feature flag: `TILAWA_LAUNCH_SUPPORT_TILAWA_ENABLED` (default **on**; set `false` to hide entries).
- No subscription/perk UI in MVP.

---

## 11. Product tours (contextual coach marks)

In-app **product tours** highlight existing controls with a dark scrim and
token-backed tooltip cards. They are separate from first-run **onboarding**
(full-screen carousel).

### UX placement (allowed vs forbidden)

| Allowed | Forbidden |
|---------|-----------|
| Feature discovery after calm entry (e.g. Reciters tab mounted) | Quran reader, prayer times, athkar during active worship |
| Settings-triggered debug replay (developer builds) | Cold-start popups, launch overlays |

### Visual rules

- Scrim: ~72% opacity neutral shadow (adaptive light/dark).
- Tooltip: `surfaceContainerHigh`, `radiusLarge`, primary **Next** / **Got it**
  CTA; secondary **Skip** text button.
- Focus ring padding: 8 dp; respect safe areas and text-scale clamp (§3).

Implementation: `apps/tilawa/lib/features/tour_guide/` — see feature README.

---

## 12. Do’s and don’ts

**Do**

- Use `ColorScheme` and **design/component tokens** for color, space, type, and radii.
- Respect **44 dp** minimum interactive sizes for in-app hit targets.
- Cap wide layouts with **`TilawaContentBounds`** and the correct `TilawaContentKind`.
- Use **`TilawaWindowSize`** for adaptive layout decisions.
- Prefer **Material 3** widgets and kit components (`TilawaButton`, `TilawaIconActionButton`, etc.) for consistent state layers.

**Don’t**

- Sprinkle raw hex or `Color(0xFF…)` in features; extend the theme or tokens if a new semantic is needed.
- Rely on Flutter’s default **48 dp** minimum when Tilawa tokens specify **44 dp** — follow the kit.
- Assume **compact** VisualDensity; the kit is tuned for **comfortable** density.
- Ignore **text scaler clamp** when auditing layouts (test at scale **1.4**).
- Add support/donation UI only per **§9** entry-point policy — never on worship surfaces.

---

## 11. Responsive behavior (checklist)

- [ ] Narrow: single column; bottom nav with icon + label where shell applies.
- [ ] Medium / expanded: consider rails, split columns, and larger content caps via `resolveContentWidth`.
- [ ] Touch targets ≥ **44 dp**; spacing from the 8-point grid (token scale).
- [ ] Contrast: body text vs surface ≥ **WCAG AA** where feasible; validate primary/onPrimary for custom colors (light theme clamps pathological primaries in `AppTheme._safePrimaryForLight`).

---

## 12. Agent prompt guide

Short prompts that align outputs with this repo:

- *“Implement using **Tilawa UI Kit** — `Theme.of(context).colorScheme`, **`TilawaDesignTokens`**, and **`TilawaComponentTokens`**, no raw hex.”*
- *“Use **`TilawaContentBounds`** with kind **form** for this settings sheet content.”*
- *“Branch layout on **`context.windowSize`** (narrow vs expanded), not raw `MediaQuery` width.”*
- *“Primary is user-configurable; use **`ColorScheme.primary`** / **onPrimary**, not `AppColors.primaryTeal` in feature code.”*
- *“Match **adaptive shell** bottom nav: use component tokens for nav height, spacing, and label styling.”*
- *“Support flow: read **§9** and `specs/016-support-tilawa/spec.md` — calm surfaces, no Premium copy, no reader/prayer entry points.”*

---

## 13. Key file map

| Area | Path |
|------|------|
| Theme assembly | `packages/ui_kit/lib/src/foundation/app_theme.dart` |
| Core palette | `packages/ui_kit/lib/src/foundation/app_colors.dart` |
| Spatial / motion tokens | `packages/ui_kit/lib/src/foundation/design_tokens.dart` |
| Content width helper | `packages/ui_kit/lib/src/foundation/content_bounds.dart` |
| Breakpoints | `packages/ui_kit/lib/src/foundation/breakpoints.dart` |
| Component tokens | `packages/ui_kit/lib/src/foundation/component_tokens/` |
| Export / composer fixed palettes (DESIGN §9 exceptions) | `packages/ui_kit/lib/src/foundation/app_colors.dart` — `AppShareComposerColors`, `AppExportScreenshotColors`, `AppVideoReelDesignDefaults` |
| App theme wiring | `apps/tilawa/lib/tilawa_app.dart` |
| Bottom sheet shell | `packages/ui_kit/lib/src/foundation/tilawa_bottom_sheet_scaffold.dart` |
| Primary presets | `apps/tilawa/lib/features/theme/domain/primary_color_preset.dart` |
| Deeper color docs | `docs/design/colors.md` |
| UI kit design system (freeze contract) | `packages/ui_kit/docs/design_system.md` |
| Catalog app bar | `packages/ui_kit/lib/src/molecules/tilawa_catalog_app_bar.dart` |
| Theme freeze spec | `specs/017-catalog-theme-freeze/spec.md` |
| Support product spec | `specs/016-support-tilawa/spec.md` |
| Support visual rules | `packages/ui_kit/docs/support_visual_system.md` |
| Play product IDs | `docs/support_play_products.md` |
| External DESIGN.md catalog (index) | `docs/design/awesome-design-md-readme.md` |
| Third-party reference designs (per brand) | `design-md/<brand>/DESIGN.md` |

---

## 14. External design references

**Canonical for Tilawa:** this file (`DESIGN.md` at repo root) plus code in `packages/ui_kit`.

**Primary external moodboard (2026):** [Behance — Islamic App Mobile UI/UX Design for Muslim Lifestyle](https://www.behance.net/gallery/230050359/Islamic-App-Mobile-UIUX-Design-for-Muslim-Lifestyle) — warm parchment, brown ink, gold featured cards. See [`docs/tilawa_brand.md`](docs/tilawa_brand.md).

**Local library:** the `design-md/` directory is a snapshot of
[VoltAgent/awesome-design-md](https://github.com/VoltAgent/awesome-design-md)
(see the catalog and usage notes in
[`docs/design/awesome-design-md-readme.md`](docs/design/awesome-design-md-readme.md)).
Use **one** `design-md/<brand>/DESIGN.md` per initiative as a **moodboard**
(layout rhythm, elevation, patterns)—not as a replacement palette.

**Agent workflow:** subordinate any external file to this spec: implement with
`TilawaDesignTokens`, `TilawaComponentTokens`, and `ColorScheme`; do not paste
reference hex into feature code unless it becomes a deliberate token in
`AppColors` / theme refinement.

**Updating the library:** refresh `design-md/` from upstream (copy, re-clone, or
`git submodule`) when you want new references; keep the snapshot license
(MIT) in mind.

---

## 15. Theme & UI kit freeze (2026-05-23)

**Status:** **Frozen** for long-term stability — see [`specs/017-catalog-theme-freeze/spec.md`](specs/017-catalog-theme-freeze/spec.md) and [`packages/ui_kit/docs/design_system.md`](packages/ui_kit/docs/design_system.md).

| Field | Detail |
|-------|--------|
| **Visual reference** | [`design-md/pinterest/DESIGN.md`](design-md/pinterest/DESIGN.md) — catalog calm + accent discipline only. |
| **Default primary** | Sage `#219653`; light neutrals white / `#E5E7EB` / black ink. |
| **Catalog header** | `TilawaCatalogAppBar` + catalog search/pills on major list screens. |
| **Allowed changes** | New kit components; critical bugs; documented feature palettes (Quran reader, share output). |
| **Enforcement** | `app_theme_color_roles_test.dart`, `app_theme_spec_compliance_test.dart`, `test/goldens/`. |

**Parallel initiative:** Support Tilawa — [`specs/016-support-tilawa/spec.md`](specs/016-support-tilawa/spec.md), DESIGN §9.

Replace this section when the freeze lifts or a new global visual initiative starts.

---

## Document format note

This file follows the same *intent* as community **DESIGN.md** collections (e.g. [awesome-design-md](https://github.com/VoltAgent/awesome-design-md), [getdesign.md](https://getdesign.md/)): a single markdown spec agents can read. It describes **this product’s** implementation, not an external brand.
