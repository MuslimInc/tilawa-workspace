# Quran player presentation architecture

> **State vocabulary:** [media-state-vocabulary.md](media-state-vocabulary.md)  
> **Canonical entry:** [player-entry-pipeline.md](player-entry-pipeline.md)  
> **Cleanup roadmap:** [player-migration-roadmap.md](player-migration-roadmap.md)

The Quran player is a **first-class product surface** with four separable
concerns (see vocabulary doc):

```text
┌─────────────────────────────────────────────────────────────┐
│  PLAYBACK (domain)     AudioPlayerBloc + audio_service     │
│  Never in URL / never in presentation controller             │
├─────────────────────────────────────────────────────────────┤
│  NAVIGATION (router)   QuranPlayerExpandedRoute /player    │
│  push/pop, redirects, external entry                       │
├─────────────────────────────────────────────────────────────┤
│  PRESENTATION          PlayerPresentationController        │
│  phases, transition progress, gestures, back intercept     │
│  CHROME (publish)      QuranPlayerChromeNotifier (widget)  │
├─────────────────────────────────────────────────────────────┤
│  SHELL LAYOUT          AppShellScreen + footer mini widget │
│  TilawaContentBounds, bottom nav, keyboard insets          │
└─────────────────────────────────────────────────────────────┘
```

## Presentation phases

Explicit phases (no implicit “mode from three booleans”):

| Phase | Meaning | Typical `transitionProgress` |
|-------|---------|------------------------------|
| `mini` | Footer mini only; `/player` not on stack | `0.0` |
| `expanding` | `/player` push animation forward | `0.0 → 1.0` |
| `expanded` | Route settled open | `≥ 0.99` |
| `collapsing` | `/player` pop animation reverse | `1.0 → 0.0` |

**Rules:**

- **Shell overlay expand (shipped):** On `embeddedInShellFooter: true`, mini→expanded
  uses `OverlayPortal` + widget `_expandController` driven by drag/snap;
  `PlayerPresentationController` syncs phase/progress via `PlayerShellOverlayHost`
  without pushing `/player` on shell routes. See
  [specs/019-quran-player-shell-expand/plan.md](../../specs/019-quran-player-shell-expand/plan.md).
- **Route expand:** When `/player` is on the stack, `transitionProgress` is owned by
  the route page animation (`onRouteAnimationTick`).
- Footer mini cross-fade reads `controller.visualProgress` and footer metrics during
  expand; during drag the footer mini stays mounted (opacity 0) so gestures continue.

## PlayerPresentationController

**Location:** `apps/tilawa/lib/features/audio_player/presentation/player_presentation_controller.dart`

**Lifetime:** App-scoped singleton (`getIt<PlayerPresentationController>()` via
`configureDependencies` in `core/di/injection.dart`). Survives shell tab
changes; must not be tied to a single `BuildContext`.

### Responsibilities (owns)

| Concern | API surface |
|---------|-------------|
| Phase + progress | `phase`, `transitionProgress`, `visualProgress` |
| Expand / collapse | `expand()`, `collapse()` → shell host (overlay) or navigation (`/player`) |
| Route sync | `onRouteAnimationTick`, `onRouteOpened`, `onRouteClosed` |
| Gesture arbitration | `onExpandDragStart/Update/End` (hero expanded) |
| Footer metrics | `metricsForFooter()` → `PlayerExpandTransitionMetrics` |
| Chrome **signal** | `overlayChromeActive` (widget applies to notifier) |
| System back **intercept flag** | `_syncSystemBackIntercepts` on coordinator |
| Debug | `snapshot()` for structured logs |

### Must not become (anti–god-object)

Do **not** add to the controller:

- `BuildContext`, `GoRouter`, or `read<Bloc>()` — use navigation interface +
  widget listeners
- Queue sheet state, play/pause, seek, or track selection
- Widget layout, Hero child trees, or theme tokens
- Direct writes to `QuranPlayerChromeNotifier` — widget publishes chrome
- Alternate expand entry points — use `QuranPlayerPresentationEntry.openExpanded`

`bindDismissPlayer` / `bindSystemBack` are **instance callbacks** from the active
`QuranPlayerWidget`, not service-locator fetches. One widget instance at a time.

### Does not own

| Concern | Owner |
|---------|--------|
| Queue, position, play/pause | `AudioPlayerBloc` |
| Route table / code gen | `app_router_config.dart` |
| Hero widgets / tags | `quran_player_hero.dart` |
| Expanded UI layout | `QuranPlayerExpandedScreen` / widget tree |
| Shell footer layout | `AppShellScreen` |

### Navigation boundary

Controller calls **`QuranPlayerNavigation`** (thin service) so presentation
logic stays testable without `BuildContext`:

```dart
abstract interface class QuranPlayerNavigation {
  bool get isExpandedRouteOnStack;
  Future<void> pushExpanded();
  void popExpanded();
}
```

Implementation uses `AppRouter.navigatorKey` + typed `QuranPlayerExpandedRoute`.

## Hero ownership

| Element | Hero tag | Source | Destination |
|---------|----------|--------|-------------|
| Artwork | `quran_player_artwork_{id}` | Footer mini | Expanded stage |
| Metadata | `quran_player_metadata_{id}` | Footer mini | Expanded stage |
| Transport | — | Cross-fade only | — |
| Scrim / surface | — | `CustomTransitionPage` | — |

Hero requires **root navigator** overlay (ADR-001). Do not move expanded
destination into shell child without revisiting ADR.

## Gesture arbitration

Priority on expanded stage (unchanged product behavior):

1. Queue sheet drag when not at peek (consumes vertical drag)
2. Player collapse drag when queue at peek (feeds controller → pop on snap)
3. Mini swipe-up when `phase == mini` (footer widget → shell overlay expand)

Controller records `isDragging` and `collapseBiased` for metrics during
collapse drags.

## Observability

Debug logs use controller `snapshot()` fields:

- `phase`, `transitionProgress`, `routeOpen`
- `transitionOwner`, `renderTree` (derived, for humans)
- No duplicate `expandProgress` vs `visualProgress` without explanation

Enable: `--dart-define=QURAN_PLAYER_DEBUG_LOG=true`

## Layers removed or consolidated (Phase B)

See full audit and Phase C plan in [player-migration-roadmap.md](player-migration-roadmap.md).

| Before | After |
|--------|-------|
| `_heroExpandedRouteOpen` | `navigation.isExpandedRouteOnStack` |
| `QuranPlayerHeroRouteProgress` (widget-owned) | Controller `transitionProgress` |
| `_expandController` in hero footer mode | Route animation only |
| Imperative `QuranPlayerExpandedHeroRoute` push | Typed `/player` |
| Widget-owned system back intercept | Controller sets coordinator flag |

**Retained (not redundant):**

- `QuranPlayerChromeNotifier` — chrome publish target (widget writes)
- `QuranPlayerSystemBackCoordinator` — global back dispatcher (thin)
- `QuranPlayerRoutePolicy` — shell-location policy
- `QuranPlayerWidget` — view; bloc + controller + chrome notifier

## Future-friendly hooks

| Feature | Integration point |
|---------|-------------------|
| Notification → player | `QuranPlayerPresentationEntry.openExpanded` after bloc hydrate |
| Queue deep link | `QuranPlayerExpandedRoute(queue: peek)` query param |
| Resume listening | Bloc restore + optional `pushExpanded` |
| Android Auto | Bloc / audio_service only |
| Maestro | Semantics IDs + optional `/player` path |
| Process death | Bloc persistence; phase defaults to `mini` |

## UX invariants (engineering checklist)

- [ ] No white flash between mini and expanded
- [ ] Footer mini participates in cross-fade during expand/collapse
- [ ] Shell and reciter screen stay mounted under overlay
- [ ] Back gesture pops `/player` before shell route
- [ ] No competing full-page opacity fade + Hero (scrim only on route)
- [ ] Spurious `completed@1.0` frame ignored at push start

## Related

- [specs/019-quran-player-shell-expand](../../specs/019-quran-player-shell-expand/spec.md) — release spec (shell expand MVP)
- [ADR-001](../adr/001-quran-player-root-overlay-route.md)
- [navigation.md](navigation.md)
