# Tilawa Premium Visual System

This document defines the first-pass rules for adding emotional visuals to
Tilawa without weakening the calm Islamic identity of the product.

## Principles

- Keep visuals respectful, quiet, and non-childish.
- Prefer non-figurative Islamic geometry, arches, compass lines, prayer-time
  horizon bands, tasbeeh motifs, and soft surface texture.
- Use visuals only when they clarify state, reduce anxiety, or make an empty
  moment feel intentional.
- Keep active Quran reading visually restrained. Quran text and Mushaf imagery
  remain the primary sacred visual.
- Derive color from `ThemeData`, `ColorScheme`, `TilawaDesignTokens`, and
  `TilawaComponentTokens`.
- Do not add hardcoded colors, spacing, shadows, or radii to reusable UI Kit
  widgets.

## Asset Style

Use this style for empty states, permission states, onboarding, and store
screenshots:

- Mature editorial vector artwork, not cartoons.
- Low detail, generous whitespace, and soft contrast.
- Palette based on active theme roles: primary, secondary, tertiary, surface,
  surfaceContainer, outlineVariant.
- Optional muted gold accents for Quran/prayer emphasis.
- No stock photos inside the app shell.
- No decorative Quranic text unless reviewed and intentionally placed.
- No mascots, childish faces, exaggerated characters, or playful scenes.

## Where Visuals Belong

Good candidates:

- Downloads empty state.
- Reciters search empty, favorites empty, and first-load states.
- Qibla permission, calibration, and sensor error states.
- Prayer location-required state.
- Athkar category and tasbeeh history empty states.
- Onboarding pages.
- Google Play screenshots.

Avoid visuals:

- Inside the active Quran page.
- Inside dense prayer time cards.
- In every reciter list row.
- Inside Settings groups, except account/profile identity.
- Anywhere visuals compete with prayer accuracy, Quran readability, or adhan
  controls.

## UI Kit vs Feature Scope

Add to UI Kit when the visual contract is reusable:

- Generic illustrated state layouts.
- Decorative pattern layers.
- Shared skeleton/state layouts.
- Tokenized surface, spacing, motion, and sizing rules.

Keep feature-specific:

- Exact illustration asset choices.
- Screen-specific copy.
- Permission/request behavior.
- Analytics, routing, repositories, and BLoC state.
- Any asset that only makes sense for one feature.

## Current Foundation

`TilawaIllustratedState` is the baseline component for premium state moments.
It provides a token-backed layout with a custom visual slot, optional icon
fallback, title, subtitle, and up to two actions. Feature screens should compose
their own assets into this component instead of creating one-off state layouts.

