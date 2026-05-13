# Feature Specification: UX Audit Critical Fixes

**Feature Branch**: `011-ux-audit-critical-fixes`  
**Created**: 2026-05-13  
**Status**: In Progress  
**Input**: Comprehensive UX audit of Flutter screen/widget implementation.

## User Scenarios

### User Story 1 — Localized, theme-consistent error states
As a non-English user, I want error states to use my language and respect my theme so I can understand and recover from failures.

### User Story 2 — Discoverable actions on surah items
As a user, I want to see a visible menu button on surah list items so I can access "Quran Reader" and "Add Bookmark" without guessing the long-press gesture.

### User Story 3 — Predictable Quran navigation
As a user, I want the Quran bottom-nav item to behave like a real tab or not appear as one, so I don't get confused about my location in the app.

### User Story 4 — Perceived performance on startup
As a user, I want the app to show real progress or appear instantly, not sit on placeholders for fixed timer durations.

### User Story 5 — Accessible player controls
As a screen-reader user, I want volume, speed, and sleep-timer controls in the expanded player to be discoverable and activatable.

## Requirements

### Functional

- **FR-001**: `QuranImageReaderScreen` error state uses `TilawaIllustratedState` with localized strings and theme tokens (no hardcoded colors/text).
- **FR-002**: `ReciterDetailsLoader` retry label uses `context.l10n.retry`.
- **FR-003**: `SurahListTile` exposes a visible overflow menu button (`Icons.more_vert`) that opens the options sheet; `onLongPress` is removed or made secondary.
- **FR-004**: `main_screen.dart` Quran nav item either becomes a real tab (index + screen) or is removed from the bottom bar.
- **FR-005**: `QuranPlayerWidget` expanded secondary controls (volume, speed) use `Semantics` + `InkWell` or `IconButton` instead of bare `GestureDetector`.
- **FR-006**: Startup artificial timers in `main_screen_cubit.dart` and `reciters_screen.dart` are replaced with event-driven activation where feasible.

## Edge Cases

- RTL: visible menu button follows `Directionality`; no LTR-only positioning.
- Theme changes: error states adapt to dark/light mode automatically.

## Out of Scope

- Skeleton loading redesign (covered by spec 008).
- Full player gesture redesign.
- Contrast measurement automation.
