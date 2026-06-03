# Quran player — migration roadmap

Tracks consolidation after Phase B. **Do not delete deprecated code until device
QA passes** (see checklist below).

## Current modes

| Mode | Trigger | Presentation authority | Status |
|------|---------|------------------------|--------|
| **Shell footer (canonical)** | `embeddedInShellFooter: true` | `PlayerPresentationController` + **shell overlay** (`PlayerShellOverlayHost`); `/player` for deep links | **Shipped (019)** |
| **Legacy overlay** | `embeddedInShellFooter: false` | `_expandController` + `OverlayPortal` | **Remove** |

Production shell uses `embeddedInShellFooter: true` (`AppShellScreen`). Legacy
path exists for older embed sites — migrate or delete; do not maintain dual
systems indefinitely.

## Phase C — remove transitional layers

Execute in order after QA sign-off:

1. **Delete** `QuranPlayerExpandedHeroRoute` (`quran_player_hero.dart`)
2. **Delete** `QuranPlayerHeroRouteProgress` + bridge (`quran_player_hero_expansion.dart`) — keep snapshot/spike **unit test helpers** in a small `quran_player_transition_test_utils.dart` if needed
3. **Remove** `_expandController` path from `QuranPlayerWidget` when no callers use `embeddedInShellFooter: false`
4. **Audit** `QuranPlayerSystemBackCoordinator` — consider folding intercept flag into controller-only API (coordinator stays as global dispatcher)
5. **Maestro** — assert shell preservation + no flash on collapse (see `.maestro/README.md`)

## Coordinator redundancy audit (Phase B)

| Component | Verdict | Notes |
|-----------|---------|-------|
| `PlayerPresentationController` | **Keep** | Presentation authority |
| `QuranPlayerNavigation` | **Keep** | Navigation boundary; no bloc |
| `QuranPlayerChromeNotifier` | **Keep** | Chrome publish target; not redundant with controller |
| `QuranPlayerSystemBackCoordinator` | **Keep (thin)** | Global back dispatch; controller only sets intercept flag |
| `QuranPlayerRoutePolicy` | **Keep** | Static shell-location policy |
| `QuranPlayerHeroRouteProgress` | **Remove** | Superseded by controller ticks |
| `QuranPlayerHeroRouteProgressBridge` | **Remove** | Superseded by `QuranPlayerExpandedPage` |
| `QuranPlayerExpandedHeroRoute` | **Remove** | Superseded by typed `/player` |
| `_expandController` (non-shell) | **Remove** | After embed audit |
| `transitionOwner` / `renderTree` getters | **Keep** | Debug-only derived strings; not parallel state |

### Partial overlap (acceptable for now)

- Controller `_routeOpen` vs `navigation.isExpandedRouteOnStack` — controller
  optimistically sets open on `expand()`; navigation is authoritative on stack.
  Do not add a third flag in the widget.
- Widget still syncs chrome from `overlayChromeActive` — intentional; controller
  must not become a `BuildContext` service locator.

## Device QA checklist (before Phase C deletes)

Release **019** sign-off (emulator Maestro + logcat): drag expand, tap expand, collapse swipe, quick cycle — see `specs/019-quran-player-shell-expand/checklists/requirements.md`.

- [x] Expand/collapse on `/reciter/:id` — shell preserved; continuous `drag.update` (019 Maestro/logcat)
- [ ] Rapid expand/collapse spam (10×) — phase recovers to `mini` (post-release soak)
- [ ] Android system back — pops `/player` before shell (when route open)
- [ ] iOS interactive pop / edge back — same
- [ ] Interrupt expand mid-animation (back during `expanding`) — footer + shell OK
- [ ] Background app during expanded → foreground — phase matches stack
- [ ] Incoming call / audio focus duck — playback OK; presentation unchanged
- [ ] Deep link `/player` without audio — redirect home
- [ ] Tab switch with mini visible — shell preserved; no duplicate `/player`
- [x] Controller debug log: no spurious `visualProgress=1.0` at expand start (guarded)

## B2 — external entry (after Phase C)

- Notification tap → bloc hydrate → `expand()`
- Deep link → bloc hydrate → optional `expand()` + presentation query params
- Document handlers in feature modules; import pipeline doc only

## Reusable pattern

Root overlay over `TypedShellRoute` is the Tilawa pattern for any immersive
surface above persistent chrome. Copy ADR-001 checklist for new overlays (reader,
share, worship modes).

## Related

- [player-entry-pipeline.md](player-entry-pipeline.md)
- [ADR-001](../adr/001-quran-player-root-overlay-route.md)
