# Product tour guide

Contextual, step-by-step in-app tours using `tutorial_coach_mark` behind a
clean-architecture boundary. **Not** the first-run onboarding carousel — see
`features/onboarding/` for that flow.

## Layers

| Layer | Role |
|-------|------|
| `TourDefinition` / `TourStep` | Declarative tour copy and target ids |
| `TourRepository` | Persists completion + version per tour id |
| `TourTargetRegistry` | Maps target ids → `GlobalKey` from widgets |
| `TourGuideService` | When to show, blocked flows, orchestration |
| `TourOverlayPresenter` | Swappable overlay (default: coach marks) |
| `TourFlowGuard` | Blocks tours during worship-first surfaces |

## Adding a tour to a feature

1. **Define stable target ids** (e.g. `reciters_tour_search`).
2. **Wrap widgets** with `TourTarget(targetId: ..., child: ...)`.
3. **Register the tour** in `di/tour_guide_module.dart`:

   ```dart
   @lazySingleton
   List<TourDefinition> provideTourDefinitions() => const [
     TourDefinition(
       id: 'reciters_intro',
       version: 1,
       steps: [
         TourStep(
           id: 'search',
           targetId: RecitersTourTargets.searchField,
           title: '...',
           description: '...',
         ),
       ],
     ),
   ];
   ```

4. **Trigger** after the screen mounts (post-frame), e.g.:

   ```dart
   WidgetsBinding.instance.addPostFrameCallback((_) {
     unawaited(
       getIt<TourGuideService>().tryShowTour(
         context: context,
         tourId: 'reciters_intro',
       ),
     );
   });
   ```

5. **Block sacred flows** with `TourSacredFlowScope(flowId: 'quran_reader', ...)`.

## Persistence

- Keys: `tour_guide_{tourId}_completed` and `_version` in SharedPreferences.
- Bump `TourDefinition.version` to re-show after copy or step changes.
- Debug: Settings → Developer → **Reset product tours**.

## Testing

- Unit-test `TourGuideService` with fake `TourOverlayPresenter` and registry.
- Widget-test `TourTarget` registration and `TourTooltipCard` layout.
- Do not rename tour ids or preference keys after release.

## Design

Tooltip chrome uses `TilawaDesignTokens` and `ColorScheme.surfaceContainerHigh`.
See `DESIGN.md` §11 (Product tours).
