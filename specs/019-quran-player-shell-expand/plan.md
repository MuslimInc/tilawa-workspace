# Implementation Plan: Quran Player Shell Expand

**Branch**: `019-quran-player-shell-expand` | **Date**: 2026-06-03 | **Spec**: [spec.md](./spec.md)  
**Release intent**: Ship current implementation; continue refactor in a later cycle.

## Summary

Deliver YouTube Music–style **in-shell** expand/collapse for the footer Quran player: finger-tracked vertical drag from mini, overlay sheet above the active shell route, synchronized presentation metrics, and automated parity tests. The widget keeps `_expandController` for shell overlay progress while `PlayerPresentationController` + `PlayerShellOverlayHost` own expand/collapse commands instead of pushing `/player` on shell screens.

## Technical Context

**Language/Version**: Flutter 3.44+, Dart 3.x  
**Primary Dependencies**: `flutter_bloc`, `go_router`, `get_it`, `ui_kit` player organisms  
**Testing**: `package:test` + `package:checks`; Maestro on Android emulator  
**Target Platform**: Android (primary QA), iOS (manual smoke)  
**Performance Goals**: 60 fps during drag; no pointer stall after overlay open  
**Constraints**: RTL, theme tokens only, ADR-001 shell preservation, no `BuildContext` in controller

## Constitution Check

- **Clean Architecture Boundaries**: PASS — playback stays in `AudioPlayerBloc`; presentation in controller + widget; navigation via `QuranPlayerNavigation` / shell host.
- **BLoC and GoRouter**: PASS — shell expand does not push `/player`; typed route retained for other entry points.
- **Atomic Design and Tilawa UI Kit**: PASS — expanded/mini chrome uses existing player UI kit organisms.
- **Responsive and Adaptive UI**: PASS — metrics from `QuranPlayerExpandPhysics` + footer layout.
- **Performance and Low Jank**: PASS — stable mini during drag; `IgnorePointer` on overlay during drag.
- **Structured Logging**: PASS — optional `QURAN_PLAYER_DEBUG_LOG` dart-define (off in release).
- **Testing Discipline**: PASS — unit tests + Maestro parity flow.
- **Safe Refactoring and Delivery**: PASS — legacy embed path untouched; post-release deletion listed.

## Architecture (as shipped)

```text
AppShellScreen
  └── QuranPlayerWidget (embeddedInShellFooter: true)
        ├── Footer mini (GestureDetector + optional PointerRoute)
        ├── AnimationController _expandController  ← visual progress (shell)
        ├── OverlayPortal → expanded sheet / scrim / morph
        └── binds PlayerShellOverlayHost → PlayerPresentationController

PlayerPresentationController.expand/collapse
  └── shell host → widget animateTo / drag snap (no /player on shell)
```

### Key files

| Area | Path |
|------|------|
| Widget / gestures / overlay | `apps/tilawa/lib/shared/widgets/quran_player_widget.dart` |
| Drag metrics | `apps/tilawa/lib/shared/widgets/quran_player_expand_physics.dart` |
| Presentation authority | `apps/tilawa/lib/features/audio_player/presentation/player_presentation_controller.dart` |
| Shell host contract | `apps/tilawa/lib/features/audio_player/presentation/player_shell_overlay_host.dart` |
| Visual mode labels | `apps/tilawa/lib/shared/widgets/quran_player_visual_mode.dart` |
| Unit tests | `apps/tilawa/test/shared/widgets/quran_player_expand_physics_test.dart`, `player_presentation_controller_test.dart` |
| Maestro | `.maestro/quran_player/quran_player_collapse_expand_parity.yaml` |

### Gesture fixes (release-critical)

1. `stop(canceled: false)` on drag start; do not reset `_isUserDraggingExpand` on `AnimationStatus.dismissed` during drag.
2. Keep footer mini in tree at opacity 0 while dragging.
3. `IgnorePointer` on overlay sheet/morph when `_isUserDraggingExpand`.
4. Optional shell `PointerRoute` for move/end after overlay covers mini.
5. Re-sync presentation on controller tick during drag.

### Interactive physics (YTM-aligned)

- `showMorphLayer: false` during user drag.
- Mini opacity holds until ~78% progress; sheet presentation opacity ramps late.
- Linear `sheetMotionT` tied to `expandProgress` for 1:1 finger tracking.

## Verification

```sh
cd apps/tilawa
dart analyze lib/shared/widgets/quran_player_widget.dart \
  lib/shared/widgets/quran_player_expand_physics.dart \
  lib/features/audio_player/presentation/
flutter test test/shared/widgets/quran_player_expand_physics_test.dart \
  test/features/audio_player/presentation/player_presentation_controller_test.dart
```

```sh
# From repo root (emulator)
maestro --device emulator-5554 test \
  .maestro/quran_player/quran_player_collapse_expand_parity.yaml
adb logcat | grep 'QuranPlayer.*drag\.'  # only when QURAN_PLAYER_DEBUG_LOG=true
```

## Post-release refactor (not blocking ship)

See [tasks.md](./tasks.md) § Post-release — Phase C deletions, single progress owner, docs/ADR alignment, expanded-route path audit.

## Related docs to keep aligned

- [docs/architecture/player-presentation.md](../../docs/architecture/player-presentation.md) — shell overlay mode section
- [docs/architecture/player-migration-roadmap.md](../../docs/architecture/player-migration-roadmap.md) — QA checklist + Phase C
