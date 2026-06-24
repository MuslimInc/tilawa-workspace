# Tilawa color architecture

How colour flows through the monorepo. Implementation truth: `packages/ui_kit/lib/src/foundation/`.

## Layers (bottom → top)

| Layer | Code | Who may import |
|-------|------|----------------|
| **Palette** | `AppColors`, `AppQuranReaderLegacyColors`, share/export palettes | `ui_kit` theme assembly only |
| **ColorScheme** | `AppTheme` → Material 3 roles | All apps and packages (via `Theme.of(context).colorScheme`) |
| **Status extensions** | `TilawaStatusColors`, `TilawaAccessibleAccents` on `ColorScheme` | Features for success / warning / small accent labels |
| **Product semantics** | `TilawaProductColors` (`ThemeData.productColors`) | Features for prayer, Quran, player, hub, featured cards |
| **Component tokens** | `TilawaComponentTokens` (`theme.componentTokens`) | Kit molecules/organisms and features mirroring kit chrome |
| **Feature extensions** | `QuranReaderTheme`, `QuranDesignTokens` | Quran reader surfaces only |

## When to use what

### `ColorScheme` (default)

Scaffold, cards, sheets, app bars, body text, outlines, primary CTAs, switches, nav selection, generic lists.

```dart
final scheme = Theme.of(context).colorScheme;
Container(color: scheme.surfaceContainerLow);
```

### `theme.productColors`

Product-specific roles that Material does not model:

- Prayer: `prayerTimeActive`, `prayerTimeNext`, `prayerTimeNextSurface`
- Quran: `quranPageBackground`, `quranTextPrimary`, `quranTextSecondary`
- Player: `playerBackground`, `playerProgress`
- Athkar: `athkarCounter`
- Hub: `exploreFeatureIcon(feature)` / `exploreFeatureTileStyle(feature)`
- Brand lock: `brandLockedPrimary`, `brandLockedOnPrimary` (splash, login)
- Ceremonial: `featuredGradientStart` / `End`

```dart
final product = Theme.of(context).productColors;
final fill = product.prayerTimeNextSurface;
```

### `colorScheme.success` / `.warning`

Destructive → `colorScheme.error`. Positive / caution → `TilawaStatusColors` extension.

### `theme.componentTokens`

Kit-owned formulas (search field, bottom nav, hero prayer gradients via `homeNextPrayerHero`, etc.). Prefer kit widgets; if a feature copies kit chrome, read tokens — do not duplicate hex.

## Do not

- Import `AppColors` in `apps/tilawa/lib/features/` for ordinary UI (exceptions: theme preset enum, notification services, documented platform-fixed accents).
- Use `Colors.red`, `Colors.grey`, etc. in product widgets.
- Add raw `Color(0x…)` in feature widgets.
- Create a second `AppColors` class in feature packages (`quran_image` is scheduled for consolidation).

## Documented exceptions

| Area | Why |
|------|-----|
| `AppShareComposerColors` | Marketing-style share/reel output |
| `AppQuranReaderLegacyColors` | Mushaf reading presets (surfaced via `TilawaProductColors`) |
| `features/color_picker/` | Dev/QA tool |
| `notificationAccent` | OS notification channel cannot read `ThemeData` |
| Shader warmup alphas | Bootstrap performance |

## Brand lock (production)

`PrimaryColorPreset.brandLocked` → teal `#00897B` (`AppColors.defaultPrimary`). `Env.kShowColorPicker == false` forces this at runtime. See [`colors.md`](colors.md).

## Tests

- `packages/ui_kit/test/theme/app_theme_color_roles_test.dart` — contrast on scheme roles
- `packages/ui_kit/test/foundation/tilawa_product_colors_test.dart` — product extension
- `packages/ui_kit/test/foundation/home_explore_feature_tile_styles_test.dart` — hub icons
- `apps/tilawa/test/shared/contracts/feature_color_contract_test.dart` — bans raw `Colors.*` / `Color(0x…)` in feature code

## Related

- [`colors.md`](colors.md) — policy
- [`../packages/ui_kit/docs/design_system.md`](../packages/ui_kit/docs/design_system.md) — kit contracts
- [`../DESIGN.md`](../DESIGN.md) — human spec
