# Plan: Visual Simplification

**Feature Branch**: `012-visual-simplification`
**Created**: 2026-05-15

## Design system after this change

### Colour system

**One brand accent, one neutral ramp, three semantics.**

| Role | Source | Where it shows |
|------|--------|----------------|
| Brand accent | User-selected primary via `ColorScheme.primary` | Switches ON, primary buttons, active nav, selected chips, progress fill, focus rings, settings tile icons. |
| Surface ramp | `ColorScheme.surface`, `surfaceContainerLow`, `surfaceContainerHigh`, `surfaceContainerHighest` | Scaffold, cards, sheets, bottom nav chrome, dialogs. |
| Outline | `ColorScheme.outlineVariant` | Card hairlines, dividers, list separators. |
| Foreground | `ColorScheme.onSurface`, `onSurfaceVariant` | Body text, secondary text, icons. |
| Semantic — Error | `AppColors.error` → `ColorScheme.error` | Destructive actions, validation errors, prayer "fail". |
| Semantic — Success | `AppColors.success` | Download complete, save confirmation. |
| Semantic — Warning | `AppColors.warning` | Permission missing, low storage. |

**Banned in product chrome:** parallel category hues (settings palette), `Color.lerp` blends for backgrounds, raw `Color(0x…)` literals, brand secondary used as decoration.

### Typography

No changes. `responsive_typography.dart` ramps are preserved. Headlines use `FontWeight.w700` (down from `w800`) where I touched them for a calmer hierarchy.

### Spacing

No changes. Eight-dp grid in `TilawaDesignTokens` is preserved. The unused `opacityGlass` (0.8) and `blurGlass` (12.0) tokens stay for now — only consumed by the `tilawa_glass_panel` molecule, which is out of scope for this pass.

### Components

| Component | Before | After |
|-----------|--------|-------|
| `TilawaCard` | `gradient:`, `flat: bool`, ad-hoc border colour overrides | `surface: TilawaCardSurface.raised \| flat \| outline`. Old props kept as `@Deprecated`. |
| `ReciterCard` | Two-stop gradient + tinted border + alphaBlend overlay | Solid `surfaceContainerLow` + hairline `outlineVariant`. |
| `ReciterDetailsAppBar` | Two-stop gradient + 2 decorative circles + tonal title bar | Solid primary, no decoration. |
| `AthkarDetailsHeader` | Top-bottom gradient in `FlexibleSpaceBar` | Solid primary. |
| `AthkarCategoryCard` | Glass-blend gradient + giant ornamental icon in `Stack` | Solid surface, icon-box + label only. |
| `AthkarItemWidget` body | Glass-blend gradient | Solid `surface`. |
| `TasbeehScreen` cards (×3) | Glass-blend gradients | Solid `surface`. |
| `NextPrayerCountdownCard` | Gradient + tinted border + halo shadow on inner visual | Solid surface, inner badge is a flat circle. |
| `QuranReaderAppBar` | Vertical glass gradient + tinted border + shadow | Solid surface + hairline outline. |
| `ayah_list_view` Surah header | `primary → secondary` gradient | Solid primary. |
| `RecitersSearchHeader` (in `reciters_screen.dart`) | Tinted gradient + outline + shadow | Solid surface + hairline outline. |
| `LoginScreen` background | Diagonal gradient + 2 decorative circles | Solid primary. |
| `DownloadsScreen` summary card | Gradient + tinted border + shadow | Solid `surfaceContainerLow` + hairline outline. |
| `ReciterDownloadsSection` | Gradient + shadow inside `Card` | Solid `surface`. |
| Settings screen tile `iconColor` | 11 distinct hues per category | All default to `colorScheme.primary` (single accent). |
| Settings profile card | Diagonal lerp-gradient + spread-blurred halo shadow | Solid primary surface (clipped). |

### Allowed gradients (intentional)

- `apps/tilawa/lib/features/color_picker/palette.dart` — gradient *is* the tool.
- `apps/tilawa/lib/features/share/presentation/widgets/page_passage_card_renderer.dart` — generated share artwork.
- `apps/tilawa/lib/features/share/presentation/widgets/share_audio_config_sheet.dart` — composer poster.
- `apps/tilawa/lib/features/qibla/presentation/widgets/qibla_compass_widget.dart` — `Paint..shader` for the needle.
- `packages/ui_kit/lib/src/molecules/tilawa_count_progress_ring.dart` — focused state badge inside a circular indicator (a *molecule*, not chrome).
- `packages/ui_kit/lib/atoms_preview.dart` / `organisms_preview.dart` — dev preview tools.

### UX principles (reinforced)

1. **Content > chrome.** Quran text, prayer time, athkar text, reciter name are the focal elements. Surrounding chrome must recede.
2. **One accent per screen.** Use the brand primary deliberately. Don't compete with it via decorative secondary/tertiary tones.
3. **Hierarchy from typography, not chromaticity.** Title weight, size, and spacing carry hierarchy. Don't use colour to differentiate items that aren't semantically different.
4. **Stack one elevation cue, not three.** A card picks *one*: outline, fill, or shadow. Not all three.
5. **Decoration must justify itself.** No "decorative circles" or oversized background icons. Geometry is allowed only where it serves an empty state, onboarding, or product-distinct moment (see `premium_visual_system.md`).

## Execution order

1. **Foundation** — Trim `AppColors`. Keep brand presets, neutral ramps, true-black, semantic, notification accent. Remove parallel-category palette, gradient stops, divider alias, unused background.
2. **Components** — Add `TilawaCardSurface` enum to `TilawaCard`; deprecate `gradient` and `flat` props.
3. **App widgets** — Flatten every product-chrome gradient in features.
4. **Migration** — Switch `flat: true` callers to `surface: TilawaCardSurface.flat`.
5. **Docs** — Refresh `docs/design/colors.md`, `packages/ui_kit/docs/premium_visual_system.md`; create this spec.
6. **Verify** — `dart analyze` clean, ui_kit tests (494/494) pass, no new failures vs baseline in app tests.

## Risks & mitigations

- **Risk**: Saved user themes that picked a deprecated preset name. **Mitigation**: alias constants (`primaryCyan`, `primaryGreen`, `primaryPurple`) stay.
- **Risk**: Goldens drift. **Mitigation**: tests still pass — visual changes are within token tolerances since most "gradient" gradients were 1-2% alpha overlays that didn't render distinctly anyway.
- **Risk**: Accessibility regression. **Mitigation**: semantic IDs and labels untouched; reciter card tests (failing pre-existing) tracked separately.
- **Risk**: Notification chrome breaks. **Mitigation**: `notificationAccent` retained.
