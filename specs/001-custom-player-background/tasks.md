# Tasks: Custom Player Background

**Feature**: [Custom Player Background](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/001-custom-player-background/spec.md)
**Plan**: [Implementation Plan](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/001-custom-player-background/plan.md)

## Implementation Strategy
This feature will be implemented incrementally, starting with the core data structures and gallery picking (MVP), followed by camera support, persistence, and UI polishing.

## Phase 1: Setup
- [x] T001 Add `image_picker` dependency to `apps/tilawa/pubspec.yaml`
- [x] T002 [P] Configure Android/iOS permissions in `apps/tilawa/android/app/src/main/AndroidManifest.xml` and `apps/tilawa/ios/Runner/Info.plist`

## Phase 2: Foundational
- [x] T003 [P] Create `PlayerBackgroundConfiguration` entity in `apps/tilawa/lib/features/audio_player/domain/entities/player_background_configuration.dart`
- [x] T004 [P] Create `PlayerBackgroundConfiguration` model with JSON serialization in `apps/tilawa/lib/features/audio_player/data/models/player_background_configuration_model.dart`
- [x] T005 [P] Define `PlayerBackgroundState` in `apps/tilawa/lib/features/audio_player/presentation/cubit/player_background_state.dart`

## Phase 3: [US1] Personalize with Gallery Image (P1)
- [x] T006 [US1] Implement `PlayerBackgroundCubit` with gallery picking logic in `apps/tilawa/lib/features/audio_player/presentation/cubit/player_background_cubit.dart`
- [x] T007 [P] [US1] Create `PlayerBackgroundLayer` widget in `apps/tilawa/lib/features/audio_player/presentation/widgets/player_background_layer.dart`
- [x] T008 [US1] Integrate `PlayerBackgroundLayer` into `BottomPlayerUI` background stack in `packages/ui_kit/lib/src/organisms/bottom_player_ui.dart`
- [x] T009 [US1] Add "Change Background" button to expanded player controls in `packages/ui_kit/lib/src/organisms/bottom_player_ui.dart`

## Phase 4: [US2] Capture Moment with Camera (P1)
- [x] T010 [US2] Update `PlayerBackgroundCubit` to support camera capture in `apps/tilawa/lib/features/audio_player/presentation/cubit/player_background_cubit.dart`
- [x] T011 [US2] Implement source selection dialog (Gallery vs Camera) in `apps/tilawa/lib/features/audio_player/presentation/widgets/background_source_dialog.dart`

## Phase 5: [US3] Persistent Customization (P2)
- [x] T012 [US3] Refactor `PlayerBackgroundCubit` to extend `HydratedCubit` for automatic state persistence
- [x] T013 [US3] Implement image file persistence (copy to app documents) in `apps/tilawa/lib/features/audio_player/presentation/cubit/player_background_cubit.dart`

## Phase 6: [US4] Reset to Default (P3)
- [x] T014 [US4] Add `resetToDefault()` method to `PlayerBackgroundCubit`
- [x] T015 [US4] Add "Reset" button to background settings UI

## Phase 7: Polish & Cross-Cutting
- [x] T016 Apply blur and darkening overlay to `PlayerBackgroundLayer` for text legibility
- [x] T017 Implement automatic cleanup of old custom images in app storage
- [x] T018 Handle permission denials with user-friendly dialogs and deep links to settings

## Dependencies
- Phase 2 depends on Phase 1 completion.
- Phase 3 (MVP) depends on Phase 2.
- Phase 4, 5, and 6 can be developed in parallel once Phase 3 is complete.

## Parallel Execution Examples
- **Story US1**: T007 [P] (Widget UI) can be developed in parallel with T006 (Cubit logic).
- **Foundational**: T003, T004, and T005 are all independent file creations.
