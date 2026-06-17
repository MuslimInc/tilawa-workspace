---
name: flutter-apply-tilawa-theming
description: >-
  Apply Tilawa design tokens, ColorScheme, component tokens, and Flex spacing
  from DESIGN.md and ui_kit. Use when building or refactoring UI in apps/tilawa
  or packages/ui_kit.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Sun, 24 May 2026 12:00:00 GMT
---
# Applying Tilawa Theming

## Canonical references

Read in order when unsure:

1. [`DESIGN.md`](../../../DESIGN.md) — human spec (implementation wins on code)
2. [`packages/ui_kit/docs/design_system.md`](../../../packages/ui_kit/docs/design_system.md) — agent contracts
3. [`docs/tilawa_brand.md`](../../../docs/tilawa_brand.md) — brand intent

Source of truth: `packages/ui_kit/lib/src/foundation/` (`app_theme.dart`,
`design_tokens.dart`, `component_tokens/`).

## Access patterns

| Need | API |
|------|-----|
| Semantic colours | `Theme.of(context).colorScheme` |
| Space, radii, motion, opacity | `Theme.of(context).tokens` or `context.tokens` |
| Component chrome (buttons, chips, nav) | `Theme.of(context).componentTokens` or project extension |
| Responsive type | `context.responsiveStyle(...)` when the feature already uses it |

**Do not** import `AppColors` in `apps/tilawa/lib/features/` for ordinary chrome.
Extend theme/tokens if a new semantic is needed.

## Colour rules

- **Light catalog chrome:** neutrals on scaffold, app bars, search, and filter
  chips; user primary/coral for **one** emphasis per screen (CTA, active nav,
  favorites, progress, switch ON).
- **No parallel palettes:** no per-screen hex, decorative gradients, or category
  hue stacks in product chrome.
- **Contrast:** validate body text vs surface (WCAG AA where feasible); light
  theme clamps pathological custom primaries in `AppTheme`.

## Spatial layout

### 8-point grid

Use `TilawaDesignTokens` scale — never magic numbers for product spacing:

`spaceTiny` (2) · `spaceExtraSmall` (4) · `spaceSmall` (8) · `spaceMedium`
(16) · `spaceLarge` (24) · `spaceExtraLarge` (32).

### Flex `spacing` (prefer over fixed `SizedBox`)

When **every** gap between adjacent `Column` / `Row` / `Flex` children is the
**same fixed token**, set `spacing:` and remove inter-child `SizedBox` widgets:

```dart
Column(
  spacing: tokens.spaceExtraSmall,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(title, style: titleStyle),
    Text(subtitle, style: subtitleStyle),
  ],
)
```

**Keep `SizedBox` when:**

- Gaps differ (`spaceSmall` then `spaceMedium` in one flex)
- Only trailing or leading padding (not between children)
- Gap is computed or responsive (`narrowWidth ? medium : large`)
- Separator in `ListView.separated` / manual list loops
- `SizedBox` constrains size (e.g. `width: 40` artwork), not just gap

### Touch targets

Follow kit tokens: `tokens.minInteractiveDimension` = **44 dp**
(`kTilawaMinInteractiveDimension` in `design_tokens.dart`). Do not shrink
tappable chrome below this floor.

## Catalog chrome

List/catalog screens use **`TilawaCatalogAppBar`** with parchment surface,
left-aligned title, and catalog search/filter tokens. See
`design_system.md` §3.

## Widget tests and previews

Use `AppTheme.getLightTheme` with project test helpers (see
`test/features/home/presentation/screens/home_screen_test.dart`):

```dart
await tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.getLightTheme(primaryColor: AppColors.defaultPrimary),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: widgetUnderTest),
  ),
);
```

For goldens/previews in `ui_kit`, use `TilawaPreviewWrapper` / full `AppTheme`,
not bare `ThemeData.light()`.

## Pre-merge checklist

- [ ] `dart analyze` clean on touched packages
- [ ] No new raw `Color(0xFF…)` in feature chrome
- [ ] Spacing from tokens; uniform flex gaps use `spacing:` where applicable
- [ ] `flutter test test/theme/` and relevant widget tests when theme changes
- [ ] Update `DESIGN.md` if token or theme behaviour changed materially

## Related skills

- `flutter-build-responsive-layout` — breakpoints, `Expanded`/`Flexible`
- `flutter-fix-layout-issues` — overflow and unbounded constraints
- `flutter-add-widget-test` — pumping widgets with `AppTheme`
- `dart-run-static-analysis` — analyze + format before commit
- `tilawa-apply-ui-principles` / `tilawa-apply-ux-principles` — composition and flows
