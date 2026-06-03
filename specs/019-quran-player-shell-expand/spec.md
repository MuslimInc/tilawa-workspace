# Feature Specification: Quran Player Shell Expand (YouTube Music–style)

**Feature Branch**: `019-quran-player-shell-expand`  
**Created**: 2026-06-03  
**Status**: **Released (MVP)** — shipping in next app release; follow-up refactors tracked in [tasks.md](./tasks.md) § Post-release  
**Reference UX**: YouTube Music mini → now-playing (`screenshots/videos/youtube_music.webm`, `youtube_music_new.webm`)  
**Input**: Shell-footer Quran player must expand/collapse in-place over the active shell route (reciter, home, etc.) with finger-tracking drag, stable overlay gestures, and parity-tested behavior.

---

## Context

Tilawa’s production player lives in `AppShellScreen` (`embeddedInShellFooter: true`). Users expect the mini bar to drag up into a full now-playing sheet **without** losing the screen underneath (same pattern as YouTube Music), then collapse back with predictable snap physics.

Earlier implementations stalled drags after ~1px (animation `stop()` cleared drag state), lost pointer events when the overlay opened above the footer mini, and desynced presentation metrics during interactive drags.

This spec captures **what ships in the release** and defers structural cleanup (Phase C deletions, route-only mode) to post-release work.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Drag up from mini (Priority: P1)

As a listener on any shell screen with playback active, I want to drag the mini player upward and have the expanded sheet follow my finger 1:1 so the transition feels direct and controllable.

**Independent Test**: Start playback on a reciter screen, slow-drag the mini bar up, release past the expand threshold — sheet settles fully expanded; logcat shows multiple `QuranPlayer drag.update` lines with monotonically increasing `expandProgress`.

**Acceptance Scenarios**:

1. **Given** the mini player is visible, **When** I drag upward slowly, **Then** `expandProgress` tracks the drag continuously (not stuck near 0.02).
2. **Given** I release above the snap threshold, **When** the gesture ends, **Then** the player animates to fully expanded and remains interactive.
3. **Given** the overlay sheet is growing, **When** I am still dragging, **Then** the footer mini recognizer (or shell pointer route) continues to receive move events until release.

---

### User Story 2 — Collapse and partial snap (Priority: P1)

As a listener with the player expanded, I want to drag down or use collapse affordances so the UI returns to mini or snaps back to expanded without freezing mid-transition.

**Acceptance Scenarios**:

1. **Given** the player is expanded, **When** I swipe down from the upper sheet, **Then** the player collapses to mini or snaps back to expanded (no permanent half-state).
2. **Given** a partial downward drag, **When** I release, **Then** snap physics choose mini or expanded based on progress/velocity thresholds.

---

### User Story 3 — Tap mini to expand (Priority: P2)

As a listener who prefers taps over drags, I want tapping the mini bar to open the expanded player with the same settled end state as a completed drag-expand.

**Acceptance Scenarios**:

1. **Given** the mini player is visible, **When** I tap it, **Then** the expanded sheet opens and `quran_player_track_title` is exposed to accessibility/Maestro.

---

### User Story 4 — System back and shell preservation (Priority: P2)

As a listener, I want the shell route (e.g. reciter list) to stay mounted under the player overlay and system back to collapse the player before popping the shell.

**Acceptance Scenarios**:

1. **Given** the player is expanded over `/reciter/:id`, **When** I press system back, **Then** the player collapses before the reciter screen is popped (when intercept is active).
2. **Given** expand/collapse completes, **When** I observe the shell, **Then** the underlying screen did not remount (no white flash).

---

## Requirements *(mandatory)*

### Functional Requirements (release scope)

- **FR-001**: Shell-footer expand MUST use in-shell overlay (`PlayerShellOverlayHost` + `OverlayPortal`) for the primary path; MUST NOT require `/player` push for mini→expanded on shell routes.
- **FR-002**: Interactive drag MUST update `_expandController` (and synced presentation progress) on every move while `isDragging` is true.
- **FR-003**: Drag start MUST call `AnimationController.stop(canceled: false)` and MUST NOT clear `_isUserDraggingExpand` from animation status listeners mid-gesture.
- **FR-004**: While dragging, the footer mini widget MUST stay mounted (e.g. `Opacity(0)`) so the winning `GestureDetector` keeps receiving updates.
- **FR-005**: Overlay expanded sheet and morph layers MUST use `IgnorePointer` during active expand drag so they do not steal the gesture arena.
- **FR-006**: Shell-footer drag MAY attach a global `PointerRoute` so pointer moves continue after the overlay paints above the mini.
- **FR-007**: Interactive metrics MUST follow YouTube Music–style curves in `quran_player_expand_physics.dart` (mini lingers, late sheet opacity, linear `sheetMotionT`, no morph during drag).
- **FR-008**: `PlayerPresentationController` MUST reflect drag phase/progress for footer metrics and debug snapshots during shell overlay expand.
- **FR-009**: Semantics IDs (`quran_player_mini`, `quran_player_track_title`, `quran_player_collapse`) MUST remain stable for Maestro and TalkBack.

### Non-Functional

- **NFR-001**: Expand/collapse animations target 60 fps; no layout thrash from redundant `setState` outside drag/animation ticks.
- **NFR-002**: Optional debug logs via `--dart-define=QURAN_PLAYER_DEBUG_LOG=true` (disabled in release builds).

---

## Success Criteria *(mandatory)*

- **SC-001**: Maestro `.maestro/quran_player/quran_player_collapse_expand_parity.yaml` passes on Android emulator (PARITY_02–07).
- **SC-002**: Manual slow drag produces ≥10 `drag.update` log lines before release (typical run reaches >0.5 progress).
- **SC-003**: `flutter test` for `quran_player_expand_physics_test.dart` and `player_presentation_controller_test.dart` passes.
- **SC-004**: `dart analyze` clean on touched player presentation/widget files.

---

## Out of Scope (post-release refactor)

- Deleting legacy `embeddedInShellFooter: false` overlay path (Phase C in [player-migration-roadmap.md](../../docs/architecture/player-migration-roadmap.md)).
- Removing duplicate progress sources (`_expandController` vs route-only presentation).
- Full visual parity sign-off vs YouTube Music (typography, queue chrome, blur) beyond gesture/transition structure.
- iOS physical-device Maestro matrix (emulator-tested for this release).

---

## Assumptions

- Production shell always hosts `QuranPlayerWidget(embeddedInShellFooter: true)`.
- `/player` typed route remains for deep links and non-shell embeds; shell overlay is canonical for footer expand.
- Maestro uses coordinate swipes (92%→8%) when element-only swipes under-travel.

## Related

- [plan.md](./plan.md) · [tasks.md](./tasks.md)
- [docs/architecture/player-presentation.md](../../docs/architecture/player-presentation.md)
- [docs/adr/001-quran-player-root-overlay-route.md](../../docs/adr/001-quran-player-root-overlay-route.md)
- [.maestro/reference/README.md](../../.maestro/reference/README.md)
