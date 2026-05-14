# Feature Specification: Visual Simplification

**Feature Branch**: `012-visual-simplification`
**Created**: 2026-05-15
**Status**: In Progress
**Input**: Senior UI/UX review of Tilawa across UI Kit and feature screens. Goal: a clean, modern, calm, premium feel that lets sacred content (Mushaf, prayer, athkar) lead — not chrome.

## Intent

Tilawa accumulated visual friction over several iterations: gradient backgrounds on cards/app bars/headers, parallel category colors in Settings, decorative ornaments competing with content, double-stacked elevations (border + gradient + shadow). The product no longer felt *calm*.

This change resets the visual system around three principles:

1. **Surfaces are quiet.** A card is a solid colour, a hairline outline, and optionally a soft shadow — never all three plus a gradient.
2. **One brand accent.** The user-selected primary is the *only* chromatic accent in product chrome. Semantic colours (error/success/warning) keep their meaning. Decorative "category hues" are gone.
3. **Gradients are reserved.** Three legitimate uses: (a) the colour-picker tool, (b) share/reel composer output artwork (poster aesthetics), (c) shader-driven painters (Qibla needle). Everywhere else: flat.

## User Scenarios

### User Story 1 — Calm Settings
As a user opening Settings, I want a quiet, scannable list — not 11 different icon hues — so I can find the toggle I'm looking for without visual noise.

### User Story 2 — Premium prayer card
As a user checking the next prayer, I want the countdown card to feel reassuring and clean, not "marketing splash", so I can read the time at a glance.

### User Story 3 — Focused reciter browsing
As a user scanning the reciters list, I want each card to recede into a calm grid so the **reciter name** is the focal element, not the card's chrome.

### User Story 4 — Restrained Quran reading chrome
As a user reading the Mushaf, I want the reader app bar to be a flat surface — the Quran text must be the only visual that earns attention.

### User Story 5 — Composer artwork stays expressive
As a user sharing a Mushaf passage, I want the share-composer output to keep its poster-quality gradient — generated artwork is allowed to be expressive, app chrome is not.

## Requirements

### Functional

- **FR-001**: `AppColors` exposes only brand presets, neutral ramps, `AppTheme` assembly tones, and three semantic colours (`error`, `success`, `warning`). The eleven `settings*` per-category hues, `profileGradientStart/End`, `logoutBackground`, `settingsCardShadow`, and `divider` are removed.
- **FR-002**: `TilawaCard` exposes a `TilawaCardSurface` enum (`raised | flat | outline`); the legacy `gradient:` and `flat:` properties remain only as deprecated migration helpers.
- **FR-003**: No `LinearGradient` / `RadialGradient` / `SweepGradient` appears in product chrome (cards, app bars, headers, banners, hero panels). Allowed exceptions: `color_picker/palette.dart`, `share/presentation/widgets/page_passage_card_renderer.dart`, `share/presentation/widgets/share_audio_config_sheet.dart`, `qibla_compass_widget.dart`, `tilawa_count_progress_ring.dart` (state badge), preview dev tools.
- **FR-004**: Settings screen does not pass `iconColor:` to settings tiles; tiles fall back to `colorScheme.primary` for a single, harmonized accent.
- **FR-005**: Reciter details app bar, athkar details header, Quran reader app bar, and reciters search header use a single solid surface colour with a hairline outline. Decorative circles and ornament icons are removed.
- **FR-006**: Settings profile card uses a solid primary fill (no gradient, no spread-shadow halo).
- **FR-007**: Tests and `dart analyze` pass after the migration. Existing UI Kit golden tests continue to pass (the changes are deliberately within token tolerances).

### Non-functional

- **NFR-001**: The change must not regress accessibility (a11y semantics on reciter cards, settings tiles, prayer countdown, share/reel composer remain intact).
- **NFR-002**: Locale (Arabic / English) and RTL layout behaviour are unchanged.
- **NFR-003**: True-black dark mode and OLED behaviour are preserved.

## Edge Cases

- **Saved primary colour preset migration**: `primaryCyan`, `primaryGreen`, `primaryPurple` constants stay (alias-only) so users who saved a non-default theme don't lose their choice.
- **Notification chrome**: `AppColors.notificationAccent` stays — system notifications render outside Flutter's theme and can't resolve `ColorScheme`.
- **Composer output (share / reel)**: gradients here are *generated artwork*, not chrome. They are explicitly out of scope.
- **Qibla compass needle**: a `RadialGradient` lives inside a `CustomPainter` shader. It is a functional rendering, not chrome.

## Out of Scope

- Typography overhaul. Existing `responsive_typography.dart` ramps are kept.
- Spacing/sizing token changes. The existing 8 dp grid in `TilawaDesignTokens` is preserved.
- Motion / animation changes.
- The share/reel composer poster design (deliberately expressive).
- Color-picker tool gradients (the tool *is* colour).
- Onboarding illustration work.
