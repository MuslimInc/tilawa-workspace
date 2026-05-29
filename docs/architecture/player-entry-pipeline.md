# Quran player — canonical entry pipeline

All ways to show the **expanded** player must use the same pipeline. Do not add
alternate `Navigator.push`, shell mutations, or widget-local “force expanded”
flags.

## Pipeline (B2-ready)

```text
1. Playback ready     AudioPlayerBloc has currentAudio (and optional play)
2. Presentation       PlayerPresentationController.expand()
3. Navigation         QuranPlayerNavigation.pushExpanded() → /player push
4. Route sync         QuranPlayerExpandedPage → onRouteAnimationTick
5. View               QuranPlayerExpandedPageContent + footer Hero mini
```

### In-app (footer mini tap / swipe)

```dart
await getIt<PlayerPresentationController>().expand();
```

### External entry (notifications, deep links, intents) — planned B2

```dart
// 1. Restore or select media in AudioPlayerBloc (never in URL)
await audioPlayerBloc.playFromNotification(payload);

// 2. Same presentation entry as in-app
if (context.read<AudioPlayerBloc>().state.hasAudio) {
  await getIt<PlayerPresentationController>().expand();
}
```

Optional: navigate with query params for **presentation chrome only** (e.g.
`?queue=peek`) — still hydrate queue in the bloc; params only hint UI.

### Invalid entry

| Case | Behavior |
|------|----------|
| `/player` with no `currentAudio` | `AppRouter.redirect` → `HomeRoute` |
| `expand()` while route already open | No-op in controller |
| `collapse()` with no route | No-op |

## Forbidden alternate paths

| Pattern | Why forbidden |
|---------|----------------|
| `QuranPlayerExpandedHeroRoute` (imperative) | Deprecated; hidden stack |
| Widget sets “expanded” without `push` | Breaks navigation observability |
| `go('/player')` from expand gesture | Replaces shell; not calm back UX |
| Playback fields in `/player` URL | See [media-state-vocabulary.md](media-state-vocabulary.md) |

## Android Auto / wear / car

Platform session → **bloc only**. Expanded UI opens only if product requires it,
via step 2 above — never a separate navigation implementation.

## Related

- [navigation.md](navigation.md)
- [player-migration-roadmap.md](player-migration-roadmap.md)
