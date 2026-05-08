# Tilawa color system (design policy)

This document describes **Phase C1** primitives and the intended direction for later phases. Product UI should consume colors only through allowed sources.

## Allowed sources

1. **`AppColors`** (`packages/ui_kit`) — Brand presets, neutral ramp, semantic bases, settings/notification accents, and **all hex values used to build** `ColorScheme` in `AppTheme`. Do not duplicate those hex values elsewhere.
2. **`AppTheme`** — Builds `ThemeData` and `ColorScheme` from `AppColors` + user-selected primary. Defines **how** primary maps to containers (e.g. `_containerForPrimary`, `_blendSurfaceTowardPrimary`). Should not introduce raw `Color(0x…)` literals; add new primitives to `AppColors` first.
3. **`TilawaComponentTokens`** — Component-level fills and blends; formulas live in **token factories**, not in widgets.
4. **Feature themes / palettes** — Quran reader, share/reel, media player: centralized palette files or `ThemeExtension`s (later phases).
5. **Exceptions** — `Colors.transparent`; color-picker named-color data; tests/previews/debug; third-party packages.

## Policy: primary vs surfaces

- **User-selected primary** should drive **accent / interactive** roles (selected nav, primary buttons, switches ON, active chips, progress value, focus/selection) as defined by `ColorScheme` and tokens.
- **Stable neutral surfaces** (scaffold, fixed bottom nav chrome, cards, sheets where specified) use **fixed primitives** or tiers derived from **neutral bases** in `AppColors`, not ad-hoc widget literals.
- **Semantic colors** (`error`, `success`, `warning`, and related) are defined in `AppColors` and must not be derived from user primary.

Light and dark **Flex** scheme colors (secondary/tertiary containers, dark error tone for scheme, true-black tiers, etc.) live under the **“AppTheme”** sections in `app_colors.dart` so there is a single source of truth.

## Forbidden (in product widgets)

- Raw `Color(0x…)` for product chrome (except documented feature palettes after migration).
- Ad-hoc `Color.lerp` / `Color.alphaBlend` in widgets for persistent backgrounds — use tokens.
- Duplicating hex values that already exist in `AppColors` or `AppTheme` assembly.

## Migration phases (reference)

- **C1 (done here):** Centralize `AppTheme` literals in `AppColors`; document policy.
- **C2+:** Move widget-level blends into tokens; feature palettes; app-wide cleanup.

## Related tests

- `packages/ui_kit/test/theme/app_theme_color_roles_test.dart` — contrast and scheme roles.
