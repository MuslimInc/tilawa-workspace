# Media UI state vocabulary (Tilawa)

Use these terms consistently in code reviews, ADRs, logs, and variable names.
**Do not merge concepts** — most player bugs come from syncing the wrong layer.

## Four state families

| Term | What it is | Source of truth | In URL? |
|------|------------|-----------------|---------|
| **Playback state** | Track, queue, position, play/pause, repeat/shuffle | `AudioPlayerBloc` + `audio_service` | **Never** |
| **Presentation state** | Mini vs expanded, transition progress, drag phase | `PlayerPresentationController` + `PlayerPresentationPhase` | **Never** (derived from route animation) |
| **Navigation state** | Whether `/player` is on the stack, shell route underneath | GoRouter + `QuranPlayerNavigation` | **Partially** (`/player` path only) |
| **Chrome state** | Bottom nav visibility, system nav bar color, shell chrome | `QuranPlayerChromeNotifier` + shell widgets | **Never** |

```text
Playback      AudioPlayerBloc.currentAudio, playbackState, queue
Presentation  PlayerPresentationPhase, transitionProgress, isDragging
Navigation    GoRouter stack, isExpandedRouteOnStack
Chrome        QuranPlayerChromeNotifier (shell / system UI)
```

## Naming guidance

| Prefer | Avoid (ambiguous) |
|--------|-------------------|
| `presentationPhase` | `playerMode`, `isOpen` |
| `transitionProgress` | `expandProgress` alone (legacy controller used this) |
| `routeOpen` / `isExpandedRouteOnStack` | `_heroExpandedRouteOpen`, duplicate booleans |
| `hasAudio` / `currentAudio` | `shouldShowPlayer` mixed with presentation |
| `overlayChromeActive` | `isExpanded` when meaning chrome only |

## Playback vs presentation (critical)

- **Playback** answers: *what is playing?*
- **Presentation** answers: *how is the player UI shown?*

Examples that belong in **playback only**:

- Skip, seek, queue index, sleep timer, dismissed track id

Examples that belong in **presentation only**:

- Expand/collapse, Hero transition progress, collapse-biased scrim metrics

**Anti-pattern:** putting `currentSurahId` or `position` in GoRouter query params
for the player overlay. Hydrate the bloc; navigate to `/player` if the UI should
open.

## Navigation vs presentation

- **Navigation** is the stack operation: `push` `/player`, `pop` on collapse.
- **Presentation** is the animated experience while that route exists.

`expand()` → `push`; `collapse()` → `pop`. Presentation phase follows the route
animation via `onRouteAnimationTick`, not a parallel `AnimationController` in
shell-footer mode.

## Chrome vs presentation

Chrome is **shell/system UI policy**, not “is the player expanded.”

- `PlayerPresentationController.overlayChromeActive` is an **input signal**
  the widget uses when updating `QuranPlayerChromeNotifier`.
- The notifier remains the **publish target** for `AppShellScreen` and
  `TilawaApp` — the controller does not call `BuildContext.read` itself.

## Debug logs

When adding `QuranPlayerDebugLog` fields, tag the family:

- `phase`, `transitionProgress` → presentation
- `routeOpen`, `matchedLocation` → navigation
- `currentAudioId`, `isPlaying` → playback (from bloc snapshot at widget)
- `bottomNavVisible` → chrome

## Related

- [player-presentation.md](player-presentation.md)
- [player-entry-pipeline.md](player-entry-pipeline.md)
- [ADR-001](../adr/001-quran-player-root-overlay-route.md)
