# Feature Specification: Reciters Screen Accessibility

**Feature Branch**: `010-reciters-a11y`  
**Created**: 2026-05-13  
**Status**: Implemented  
**Input**: Accessibility audit of Reciters list (`reciters_screen.dart`, `reciter_card.dart`) and shared UI kit controls used there.

## User Scenarios & Testing

### User Story 1 — Touch targets and non-nested actions (Priority: P1)

As a user with motor limitations or a screen reader, I want the favorite control and the “open reciter” action to be clearly separated with targets at least **48×48dp**, without nested buttons, so that I can activate the correct action predictably.

**Independent Test**: Inspect semantics tree and hit sizes for `ReciterCard` in loaded list state.

**Acceptance Scenarios**:

1. **Given** a reciter card, **When** measuring the favorite control, **Then** its interactive bounds are at least **48×48** logical pixels.
2. **Given** a reciter card, **When** traversing semantics, **Then** “open reciter” and “favorite” are **sibling** interactive nodes, not a button wrapping another button.

---

### User Story 2 — Names, toggles, and hints (Priority: P1)

As a screen reader user, I want icon-only header actions, the search clear control, and the alphabet index to expose **localized names**, **toggle state** where applicable, and a **hint** for non-obvious gestures.

**Independent Test**: VoiceOver / TalkBack / semantics labels on Reciters header, search field, scrollbar.

**Acceptance Scenarios**:

1. **Given** the Reciters header, **When** focusing the favorites filter and downloads actions, **Then** each has a non-empty accessible name (and favorites exposes **toggled** state when used as a filter).
2. **Given** text in the search field, **When** focusing the clear control, **Then** it has a localized tooltip / name.
3. **Given** the letter scrollbar, **When** focusing its container, **Then** it exposes a label and optional hint describing drag-to-jump behavior.

---

### User Story 3 — Loading and structure (Priority: P2)

As a screen reader user, I want the loading indicator to announce **what** is loading, and the screen to expose a **heading** for the Reciters area.

**Acceptance Scenarios**:

1. **Given** reciters are loading in the main sliver, **When** the progress indicator is focused, **Then** its semantics label matches the localized “loading reciters” copy.
2. **Given** the loaded Reciters UI, **When** using heading navigation, **Then** a header node exists for the Reciters screen title.

---

## Requirements

### Functional

- **FR-001**: Per-card favorite hit target ≥ `kMinInteractiveDimension` (48dp); icon may remain smaller inside padding.
- **FR-002**: Card “open details” uses a single `InkWell` on the info region only; favorite uses its own control (no nested `InkWell` under the row `InkWell`).
- **FR-003**: Favorite control: `Semantics` with `button`, `toggled` (favorite state), and localized `label`; stable `identifier` unchanged for Maestro.
- **FR-004**: Header `TilawaIconActionButton`s: localized `semanticLabel` / `tooltip`; favorites filter supports `toggled` and is **disabled** until `FavoritesCubit` is `FavoritesLoaded`.
- **FR-005**: `TilawaSearchField` supports an optional clear-button tooltip; Reciters passes localized string.
- **FR-006**: `TilawaIconActionButton` supports `enabled` and optional `toggled` in `Semantics`.
- **FR-007**: `ArabicAlphabetScrollbar` accepts optional scrollbar `Semantics` label and hint from the app.
- **FR-008**: Main Reciters loading sliver passes `semanticsLabel` to `TilawaLoadingIndicator`.
- **FR-009**: Reciters header exposes `Semantics(header: true)` with localized screen title.

### Localization

- **FR-010**: New user-visible a11y strings live in `app_en.arb` / `app_ar.arb` with descriptions; `removeFromFavorites` for the favorite-off control label.

---

## Edge Cases

- Favorites cubit not yet loaded: filter button must not appear as a working toggle (disabled semantics, no filter side-effects).
- RTL: header `Row` and card `Row` continue to follow `Directionality`; scrollbar remains `PositionedDirectional`.

---

## Out of Scope

- Replacing pull-to-refresh with a visible “Refresh” menu item (documented follow-up only).
- Automated contrast measurement per theme seed.
