# ADR-001: Quran player as root overlay route

**Status:** Accepted  
**Date:** 2026-05-29  
**Deciders:** Tilawa mobile architecture  
**Supersedes:** Imperative `Navigator.push(QuranPlayerExpandedHeroRoute)` (interim)

## Context

The Quran player is a **first-class product surface** for Tilawa:

- Persistent footer mini player inside `AppShellScreen`
- Full-screen expanded now-playing with Hero transitions
- Queue sheet, transport, and future external entry (notifications, share, resume)

Tilawa uses **GoRouter** with a `TypedShellRoute` (`AppShellRoute`) for main navigation.
Expanded player must **overlay** the shell without unmounting it or replacing the active
shell route (e.g. `/reciter/1`).

An interim implementation used `Navigator.of(context, rootNavigator: true).push`
with a custom `PageRoute`. That preserved UX but created:

- Hidden navigation state (GoRouter `matchedLocation` unchanged)
- Mixed navigation APIs (`GoRouteData.push` vs raw `Navigator.push`)
- Duplicated presentation ownership (widget flags, route progress, legacy
  `AnimationController`, chrome notifiers)

## Decision

Adopt a **hybrid typed root overlay route**:

| Layer | Source of truth |
|-------|-----------------|
| Playback | `AudioPlayerBloc` + platform audio session |
| Navigation | Typed `QuranPlayerExpandedRoute` at `/player` on **root** navigator |
| Presentation | `PlayerPresentationController` (single authority) |
| Shell layout | `AppShellScreen` (footer mini host, bottom nav) |

### Invariants

1. **Playback is never URL state** — queue, position, and track identity live in
   `AudioPlayerBloc` only.
2. **Presentation entry may be navigable** — `/player` is a canonical overlay
   destination for in-app expand (`push`) and external entry.
3. **In-app expand uses `push`, not `go`** — preserves back stack and shell route
   underneath; avoids replacing `/reciter/1`.
4. **`/player` is outside `TypedShellRoute`** — uses `parentNavigatorKey:
   AppRouter.navigatorKey`.
5. **Overlay page is non-opaque** — `CustomTransitionPage(opaque: false)` with
   scrim + Hero; shell and footer mini remain in the tree.
6. **Hero scope** — artwork and metadata Hero tags fly between footer mini
   (shell) and expanded page (root overlay) on the same root navigator.
7. **One presentation authority** — phase, transition progress, and gesture
   state live in `PlayerPresentationController`; chrome is published via
   `QuranPlayerChromeNotifier` from the widget layer.
8. **Four state families** — playback, presentation, navigation, chrome must
   not blur together ([media-state-vocabulary.md](../architecture/media-state-vocabulary.md)).
9. **Canonical entry** — all expanded opens use
   `QuranPlayerPresentationEntry.openExpanded` ([player-entry-pipeline.md](../architecture/player-entry-pipeline.md)).

### UX philosophy (non-negotiable)

Transitions must remain **calm, smooth, and emotionally quiet** — spiritually
respectful, premium without visual noise. Architecture serves that feeling; it
must not introduce abrupt URL replaces, full-screen flashes, or competing
animations.

## Alternatives considered

### A. Shell-child `/player` (inside `AppShellRoute`)

**Rejected.** Replaces or nests shell child match; fights footer mini + overlay
semantics; poor fit for “stay on reciter while expanded.”

### B. Imperative root `Navigator.push` only

**Rejected as long-term.** Valid interim; lacks observability, typed contracts,
and consistent patterns for notifications and deep links.

### C. URL query on shell route (`/reciter/1?player=1`)

**Rejected for now.** Preserves single matched path but complicates codegen,
redirects, and external entry; harder to document than `/player` overlay.

### D. Hybrid typed root overlay (chosen)

Preserves media-app UX and makes navigation declarative and observable.

## Consequences

### Positive

- Single navigation contract for expand, collapse, notifications, share
- GoRouter observers and analytics see `/player`
- Redirect guards (e.g. no active audio → do not show `/player`)
- Clear contributor docs (`docs/architecture/navigation.md`,
  `player-presentation.md`)
- `PlayerPresentationController` removes duplicated sync layers

### Negative / costs

- `build_runner` when route types change
- Web address bar may show `/player` on expand (acceptable; enables share/resume)
- One-time migration from imperative route + widget-local flags
- Team must learn root overlay pattern (documented)

## Implementation phases

1. **Documentation** (this ADR + architecture docs) — done with Phase B start
2. **Phase B** — typed `/player`, `PlayerPresentationController`, remove
   imperative push and redundant flags in hero mode
3. **Phase B2** — notification / share entry via same route
4. **Phase C** — restoration policy (audio yes, expanded UI usually collapsed on
   cold start)

## References

- `docs/architecture/navigation.md`
- `docs/architecture/player-presentation.md`
- `apps/tilawa/lib/router/app_router_config.dart`
- `apps/tilawa/lib/shared/widgets/quran_player_widget.dart`
