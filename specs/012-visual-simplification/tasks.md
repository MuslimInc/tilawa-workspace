# Tasks: Visual Simplification

**Feature Branch**: `012-visual-simplification`
**Created**: 2026-05-15

## Foundation

- [x] **T-001**: Trim `packages/ui_kit/lib/src/foundation/app_colors.dart` to brand presets, neutral ramps, `AppTheme` scheme bases, semantics, and `notificationAccent`. Remove `settings*` per-category palette (11 colours), `profileGradientStart/End`, `logoutBackground`, `settingsCardShadow`, and `divider` alias. Keep `primaryCyan` / `primaryGreen` / `primaryPurple` as aliases for saved-theme migration.
- [x] **T-002**: No changes to `TilawaDesignTokens`. Keep `opacityGlass` / `blurGlass` (still used by `tilawa_glass_panel` — out of scope).
- [x] **T-003**: No changes to `AppTheme`. The colour-scheme assembly already reads from the kept primitives.

## UI Kit components

- [x] **T-010**: Add `TilawaCardSurface { raised, flat, outline }` enum to `tilawa_card.dart`. Add a `surface:` parameter; deprecate `gradient:` and `flat:` with replacement hints. `TilawaCardSurface.raised` keeps the soft shadow; `flat` drops it; `outline` removes the fill.

## App feature widgets — flatten chrome

- [x] **T-020**: `reciter_card.dart` — drop two-stop gradient + tinted border; use `surfaceContainerLow` + `outlineVariant`.
- [x] **T-021**: `reciter_details_app_bar.dart` — remove gradient, decorative circles, tonal background; solid primary app bar.
- [x] **T-022**: `athkar_details_header.dart` — remove vertical gradient in `FlexibleSpaceBar`; rely on `SliverAppBar.backgroundColor` (solid).
- [x] **T-023**: `athkar_category_card.dart` — drop glass gradient and giant ornamental background icon; keep `TilawaIconBox` + label.
- [x] **T-024**: `athkar_item_widget.dart` — replace card glass gradient with `surface: TilawaCardSurface.raised`.
- [x] **T-025**: `tasbeeh_screen.dart` (×3) — replace glass-gradient `TilawaCard`s with `surface: TilawaCardSurface.raised`.
- [x] **T-026**: `next_prayer_countdown_card.dart` — drop gradient + tinted border; remove inner-badge halo shadow.
- [x] **T-027**: `quran_reader_app_bar.dart` — drop vertical glass gradient + shadow; keep solid surface + hairline.
- [x] **T-028**: `ayah_list_view.dart` Surah header — drop `primary → secondary` gradient; solid primary fill.
- [x] **T-029**: `reciters_screen.dart` `_RecitersSearchHeaderArea` — drop tinted-primary gradient + shadow; solid surface + hairline.
- [x] **T-030**: `login_screen.dart` — drop diagonal gradient and 2 decorative circles; solid primary scaffold.
- [x] **T-031**: `downloads_screen.dart` — drop glass gradient on summary card; solid `surfaceContainerLow` + hairline.
- [x] **T-032**: `reciter_downloads_section.dart` — drop gradient + shadow inside `Card`; solid `surface`.

## Settings screen — single accent

- [x] **T-040**: Remove all `iconColor: AppColors.settings*` arguments from `settings_screen.dart` (11 sites) so settings tiles fall back to `colorScheme.primary`.
- [x] **T-041**: Replace `_SettingsProfileCard` gradient fill + `spreadRadius` halo shadow with a solid primary `Material` surface.

## Migration

- [x] **T-050**: Migrate the five remaining `flat: true` callers in `prayer_times_screen.dart` and `fasting_hours_strip.dart` to `surface: TilawaCardSurface.flat`.

## Documentation

- [x] **T-060**: Update `docs/design/colors.md` to describe the simplified policy.
- [x] **T-061**: Update `packages/ui_kit/docs/premium_visual_system.md` with the gradient policy and `TilawaCardSurface` guidance.
- [x] **T-062**: Create `specs/012-visual-simplification/{spec,plan,tasks}.md`.

## Verification

- [x] **T-070**: `dart analyze` is clean for `packages/ui_kit` and `apps/tilawa`.
- [x] **T-071**: `flutter test` in `packages/ui_kit` is green (494 / 494 tests).
- [x] **T-072**: `flutter test` in `apps/tilawa`: pre-existing failures (`reciter_card_test`, `main_screen_cubit_test` timer gates, `main_screen_startup_test`) noted as out of scope — they fail on `HEAD` without this change. No new failures introduced.

## Hit-target floor (2026-05-15, same branch)

- [x] **T-080**: Add `minInteractiveDimension` field to `TilawaDesignTokens` (44 dp).
- [x] **T-081**: Expose via `BuildContext` extension as `context.minInteractiveDimension` alongside the icon-size aliases.
- [x] **T-082**: Migrate every UI Kit call site from `kMinInteractiveDimension` to the new token (atoms: `tilawa_icon_toggle`; molecules: `tilawa_permission_banner`, `tilawa_settings_tile`; component-token factories: `molecules_tokens.dart` for `iconActionButton`, `searchField`, `seekBar`, `alphabetScrollbar`; `organisms_tokens.dart` for `mediaPlayerBar` and `immersiveComposer`).
- [x] **T-083**: Update prior "48 dp — non-negotiable" comments to reflect the 44 dp floor.
- [x] **T-084**: Migrate app feature widgets: `download_button.dart` (8 sites), `reciter_card.dart`, `prayer_times_screen.dart`, `location_row.dart` (3 sites), `onboarding_screen.dart` (2 sites).
- [x] **T-085**: Update token-defaults / density / a11y-audit / golden tests for the new floor (regenerate the four affected molecule/organism goldens).
- [x] **T-086**: Document the hit-target rule in `packages/ui_kit/docs/premium_visual_system.md`.

## Follow-ups (not in this branch)

- [ ] **F-001**: Update reciter card widget tests to match either the simplified single-InkWell layout *or* split the card into two sibling InkWell + Semantics regions as the tests expect. (Tests pre-date this pass.)
- [ ] **F-002**: Decide whether to retire `tilawa_glass_panel` molecule (last consumer of `opacityGlass` / `blurGlass`).
- [ ] **F-003**: Audit `tilawa_count_progress_ring` to optionally flatten its internal gradient (currently kept as a focused state-badge accent).
- [ ] **F-004**: Reconsider whether `AppColors.brandSecondary` and `brandTertiary` need to stay (used only by `FlexColorScheme` assembly).
