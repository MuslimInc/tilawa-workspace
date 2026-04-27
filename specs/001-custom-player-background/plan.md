# Implementation Plan: Custom Player Background

**Branch**: `001-custom-player-background` | **Date**: 2026-04-25 | **Spec**: [spec.md](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/001-custom-player-background/spec.md)

## Summary
Implement a feature allowing users to personalize the expanded audio player background using images from their gallery or camera. The solution involves integrating `image_picker` for media acquisition, `path_provider` for persistent local storage of selected images, and a `HydratedCubit` for managing the background configuration state.

## Technical Context

**Language/Version**: Flutter 3.x, Dart 3.x
**Primary Dependencies**: `image_picker`, `path_provider`, `flutter_bloc`, `hydrated_bloc`, `tilawa_ui_kit`
**Storage**: Hydrated BLoC for configuration, File system (App Documents) for image storage
**Testing**: Widget tests for the background layer, Unit tests for the Configuration Cubit, Integration test for the picker flow
**Target Platform**: Android, iOS
**Performance Goals**: 60 fps background rendering, <100ms config load
**Constraints**: Support RTL, ensure high-res images don't cause OOM errors via cache resizing.

## Constitution Check

- **Clean Architecture Boundaries**: PASS - Configuration lives in domain, persistence in data, UI in presentation.
- **BLoC and GoRouter**: PASS - Background state managed by a dedicated `PlayerBackgroundCubit`.
- **Atomic Design and Tilawa UI Kit**: PASS - Background rendering logic will be encapsulated in a new `PlayerBackgroundLayer` organism or molecule.
- **Responsive and Adaptive UI**: PASS - Custom images will be fitted using `BoxFit.cover` to handle all aspect ratios.
- **Performance and Low Jank**: PASS - Using `Image.file` with `cacheWidth/Height` to prevent excessive memory usage.
- **Structured Logging and Diagnostics**: PASS - Logging picker results and processing errors.
- **Testing Discipline**: PASS - Logic and UI states will be fully tested.
- **Safe Refactoring and Delivery**: PASS - No breaking changes to existing audio logic.

## Project Structure

### Documentation (this feature)

```text
specs/001-custom-player-background/
├── plan.md              
├── research.md          
├── data-model.md        
└── quickstart.md        
```

### Source Code

```text
apps/tilawa/
├── lib/
│   ├── features/audio_player/
│   │   ├── presentation/
│   │   │   ├── cubit/player_background_cubit.dart
│   │   │   └── widgets/player_background_layer.dart
│   │   ├── domain/
│   │   │   └── entities/player_background_configuration.dart
│   │   └── data/
│   │       └── repositories/player_background_repository_impl.dart
```

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Local Image Copy | Avoid data loss | Storing raw paths fails if original is moved/deleted |

## Phase 1: Design & Contracts
- **Entity**: `PlayerBackgroundConfiguration` (Immutable)
- **Cubit**: `PlayerBackgroundCubit` (Hydrated)
- **UI**: `PlayerBackgroundLayer` widget to be integrated into `BottomPlayerUI`.

## Phase 2: Implementation (Task List Generation)
*Ready for tasks.md generation.*
