# Navigation architecture (Tilawa)

Tilawa uses **GoRouter** with **go_router_builder** typed routes
(`app_router_config.dart` + generated `app_router_config.g.dart`).

> **Not used:** `auto_route`. Older docs mentioning it are stale.

## Navigator map

```text
MaterialApp.router
└── GoRouter (navigatorKey: AppRouter.navigatorKey)  ← ROOT
    ├── TypedShellRoute (AppShellRoute)
    │   └── Shell child navigator
    │       ├── /
    │       ├── /reciter/:reciterId
    │       ├── /downloads
    │       └── …
    ├── /splash, /login, /onboarding, …              ← full-screen top-level
    ├── /quran-reader/:surahNumber, /share/…
    └── /player                                        ← ROOT OVERLAY (Phase B)
```

### Ownership rules

| Question | Answer |
|----------|--------|
| Where does footer mini player live? | `AppShellScreen` — **not** a route |
| Where does expanded player live? | `/player` on **root** navigator |
| Which navigator for overlay? | `AppRouter.navigatorKey` via `$parentNavigatorKey` |
| In-app expand API | `const QuranPlayerExpandedRoute().push(context)` |
| In-app collapse API | `context.pop()` (or controller `collapse()`) |
| Replace shell route on expand? | **Never** for player — use `push`, not `go` |

## Root overlay route pattern

Use when **all** of the following are true:

- Content must appear **above** the shell
- Shell route (e.g. `/reciter/1`) must **stay mounted**
- Persistent chrome (mini player, bottom nav host) must **remain alive**
- Dismiss returns to the **previous shell context**

### Checklist for new overlay routes

1. Declare `@TypedGoRoute` **outside** `@TypedShellRoute`
2. Set `static final GlobalKey<NavigatorState> $parentNavigatorKey =
   AppRouter.navigatorKey`
3. Override `buildPage` → `CustomTransitionPage(opaque: false, …)`
4. Register redirect guards in `AppRouter.redirect` if needed (e.g. `/player`
   without `AudioPlayerBloc.state.hasAudio` → `HomeRoute`)
5. Document in an ADR if the overlay is product-critical
6. Wire presentation through a controller — not widget-local route flags

### Anti-patterns

| Anti-pattern | Why |
|--------------|-----|
| `Navigator.push` beside GoRouter without ADR | Hidden stack; analytics gap |
| Shell-child “modal” route for global player | Unmounts or replaces shell context |
| `go('/player')` from in-app expand | Replaces stack; breaks calm back UX |
| Playback state in URL | Use `AudioPlayerBloc` only |
| Duplicate “route open” booleans in widgets | Use `PlayerPresentationController` + GoRouter |

## Shell route location

Active shell path is resolved via `ShellRouteLocation` (not raw
`GoRouterState.uri` alone) because the match list often includes
`ShellRouteMatch`.

Player policy helpers: `QuranPlayerRoutePolicy` in
`quran_player_chrome.dart` (when to show mini, main shell, etc.).

## Redirects and guards

`/player` redirect (Phase B):

- If `AudioPlayerBloc` has no `currentAudio` → pop or redirect away from
  `/player`
- Optional future: validate `?queue=` query against allowed peek/mid/full

## External entry (planned)

| Entry | Navigation |
|-------|------------|
| Notification tap | `QuranPlayerExpandedRoute(…).push` on root |
| Share / deep link | `/player` + hydrate bloc from link payload |
| Android Auto / CarPlay | Platform session → bloc (not GoRouter) |
| Cold start | Restore audio in bloc; expanded UI usually **collapsed** |

## Code generation

After editing `app_router_config.dart`:

```sh
# from workspace root (preferred)
melos run gen

# or from apps/tilawa
dart run build_runner build
```

## Related

- [ADR-001: Quran player root overlay](../adr/001-quran-player-root-overlay-route.md)
- [player-presentation.md](player-presentation.md)
