# Research: Custom Player Background

## Overview
This research phase focuses on identifying the best tools and patterns for image selection, persistence, and UI integration within the Tilawa audio player.

## Decision 1: Image Selection Tool
- **Decision**: Use the `image_picker` package.
- **Rationale**: It is the industry standard for Flutter, well-maintained by the Flutter team, and supports both gallery selection and camera capture.
- **Alternatives considered**: `photo_manager` (too complex for simple picker), `file_picker` (less optimized for camera/photos).

## Decision 2: Image Persistence Strategy
- **Decision**: Copy the selected image to the application's documents directory using `path_provider`.
- **Rationale**: Relying on original gallery paths is unsafe (user might delete the original). Copying to app storage ensures the background remains valid regardless of external changes.
- **Alternatives considered**: Store the original path only (risk of data loss), store image bytes in database (too heavy for large photos).

## Decision 3: Configuration Persistence
- **Decision**: Use `HydratedCubit` (from `hydrated_bloc`) to manage and persist `PlayerBackgroundConfiguration`.
- **Rationale**: Tilawa already uses BLoC for state management. `HydratedCubit` simplifies persistence of simple configuration objects without manual JSON handling in repositories.
- **Alternatives considered**: `shared_preferences` (manual mapping), `Hive` directly (overkill for a single config).

## Decision 4: UI Integration (Background Layer)
- **Decision**: Add a `Stack` at the root of the expanded player view. The bottom-most layer will be a `CustomBackgroundView` that renders either the default gradient or the custom image.
- **Rationale**: Allows for clean separation between content and background. Using a dedicated widget makes it easier to apply blurs or overlays.
- **Alternatives considered**: Set background on the `Scaffold` (not flexible enough for localized overlays).

## Decision 5: Image Optimization
- **Decision**: Use `Image.file` with `cacheWidth` or `cacheHeight` and potentially pre-process via `flutter_image_compress` if memory issues arise.
- **Rationale**: Prevent OOM errors on low-end devices when users pick 4K+ images.
- **Alternatives considered**: Load raw bytes (high memory pressure).
