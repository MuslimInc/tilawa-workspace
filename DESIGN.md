# Tilawa — DESIGN.md

Design system snapshot for **Tilawa UI Kit** (`packages/ui_kit`) and the **Tilawa app** (`apps/tilawa`). This document is for humans and coding agents. Implementation truth lives in code; update this file when tokens or theme behavior change in meaningful ways.

**Companion:** `AGENTS.md` (how to build). This file is how the product should **look and feel**.

---

## 1. Visual theme and atmosphere

- **Material 3** via **FlexColorScheme**: surfaces, containers, and component themes are assembled in `AppTheme` and refined with Tilawa-specific ramps (`AppColors`).
- **Calm, content-first:** small palette, quiet neutrals, one **user-selectable primary** accent from **curated presets** (default **Tilawa teal**); optional **custom** primary appears **in the same primary-color list** in Settings and may be **soft-clamped in light mode** for contrast (see `AppTheme._safePrimaryForLight`). Surfaces are near-monochrome in light mode; dark mode uses a deep green-tinted neutral stack (with an optional **true-black / OLED** preset).
- **Readable for Arabic:** line-height token `textHeightLoose` supports dense script in readers and lists (see `TilawaDesignTokens`).
- **Comfortable density:** `FlexColorScheme.comfortablePlatformDensity` (not compact VisualDensity).
- **Premium depth:** layered shadows (`opacityShadow` / `opacityShadowStrong`), optional **glass** tokens (`blurGlass`, `opacityGlass`) for overlays and chrome — use consistently, not everywhere.

---

## 2. Color palette and roles

### User-selectable primary (accent)

Offered in app settings (`PrimaryColorPreset`). Default aligns with native splash **teal** `#1AADC5`. **Custom** hex is the last row in the primary-color sheet; extreme values may be adjusted in light theme for readability.

| Preset | Hex (reference) | Notes |
|--------|-----------------|--------|
| Teal (default) | `#1AADC5` | Brand default |
| Sage | `#6F7F58` | Scholarly green |
| Gold | `#8C681F` | Warm, Mushaf-inspired accent |
| Brown | `#7B5E3B` | Warm neutral accent |
| Purple | `#7A5C89` | Muted purple |

Additional constants exist in `AppColors` (e.g. gold) for Flex **secondary/tertiary** assembly or migration; product UI should use **`ColorScheme`**, not copy arbitrary hexes.

### Fixed semantic colors (`AppColors`)

| Role | Light-oriented hex | Usage |
|------|-------------------|--------|
| Error | `#E53935` | Destructive / failures |
| Success | `#43A047` | Positive outcomes |
| Warning | `#FFA000` | Caution |

### Neutral surfaces (light)

| Token / role | Hex (base) |
|--------------|------------|
| Background / low scaffold | `#FFFFFF` |
| Surface | `#FFFFFF` |
| Container mid | `#F6F6F6` |
| Container (tier) | `#F4F4F4` |
| High / highest bases | `#EFEFEF`, `#E8E8E8` (then **primary-harmonized** in `AppTheme`) |
| Outline | `#C0C0C0` |
| Outline variant | `#E8E8E8` |

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
| Min touch target | **44 dp** (`kTilawaMinInteractiveDimension`) — intentional vs Material 48dp |
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

## 9. Do’s and don’ts

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

---

## 10. Responsive behavior (checklist)

- [ ] Narrow: single column; bottom nav with icon + label where shell applies.
- [ ] Medium / expanded: consider rails, split columns, and larger content caps via `resolveContentWidth`.
- [ ] Touch targets ≥ **44 dp**; spacing from the 8-point grid (token scale).
- [ ] Contrast: body text vs surface ≥ **WCAG AA** where feasible; validate primary/onPrimary for custom colors (light theme clamps pathological primaries in `AppTheme._safePrimaryForLight`).

---

## 11. Agent prompt guide

Short prompts that align outputs with this repo:

- *“Implement using **Tilawa UI Kit** — `Theme.of(context).colorScheme`, **`TilawaDesignTokens`**, and **`TilawaComponentTokens`**, no raw hex.”*
- *“Use **`TilawaContentBounds`** with kind **form** for this settings sheet content.”*
- *“Branch layout on **`context.windowSize`** (narrow vs expanded), not raw `MediaQuery` width.”*
- *“Primary is user-configurable; use **`ColorScheme.primary`** / **onPrimary**, not `AppColors.primaryTeal` in feature code.”*
- *“Match **adaptive shell** bottom nav: use component tokens for nav height, spacing, and label styling.”*

---

## 12. Key file map

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
| External DESIGN.md catalog (index) | `docs/design/awesome-design-md-readme.md` |
| Third-party reference designs (per brand) | `design-md/<brand>/DESIGN.md` |

---

## 13. External design references

**Canonical for Tilawa:** this file (`DESIGN.md` at repo root) plus code in `packages/ui_kit`.

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

## 14. Active design initiative (rolling)

**Status:** `TilawaBottomSheetScaffold` implemented and wired for prayer-time
sheets, settings pickers, and surah options; see `TilawaBottomSheetScaffold`
in `packages/ui_kit`.

| Field | Detail |
|-------|--------|
| **Reference moodboard** | [`design-md/mintlify/DESIGN.md`](design-md/mintlify/DESIGN.md) — dense, reading-optimized prose surfaces and clear section padding (not Mintlify colors or fonts). |
| **Tilawa implementation** | `TilawaBottomSheetScaffold` + `TilawaBottomSheetScaffoldTokens` (`organisms_tokens.dart`). Modal sheets use `TilawaBottomSheetScaffold.modalShape(context)` and surface `backgroundColor` on `showTilawaModalBottomSheet` where the shell provides the chrome. |
| **Next candidates** | Refactor remaining ad-hoc sheets (share composer, sleep timer, player confirm) to the scaffold where it reduces duplication. |

Replace or extend this section when the initiative completes or a new one starts.

---

## Document format note

This file follows the same *intent* as community **DESIGN.md** collections (e.g. [awesome-design-md](https://github.com/VoltAgent/awesome-design-md), [getdesign.md](https://getdesign.md/)): a single markdown spec agents can read. It describes **this product’s** implementation, not an external brand.
