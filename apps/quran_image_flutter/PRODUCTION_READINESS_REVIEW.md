# Quran Image Flutter Production Readiness Review

Date: 2026-04-16

## Scope

Reviewed the current `apps/quran_image_flutter` implementation against:

- Clean Architecture
- SOLID principles
- Near O(1) lookup and cache behavior on hot paths

This pass was intentionally limited to production-facing correctness and lifecycle issues. No broad refactors were introduced.

## Changes Made

### 1. Prevented stale prewarm state after cancel or memory pressure

Files:

- `lib/data/services/quran_image_prewarm_service.dart`
- `lib/data/services/flutter_decoded_quran_image_cache.dart`
- `test/quran_image_prewarm_service_test.dart`

Changes:

- Added generation invalidation in `QuranImagePrewarmService` so an in-flight `ensurePageReady()` started before `cancel()` cannot repopulate `_readyPageKeys` after the service has been reset.
- Added generation invalidation in `FlutterDecodedQuranImageCache` so in-flight image resolves started before `handleMemoryPressure()` cannot repopulate `_warmKeys` after cache eviction.
- Added a regression test covering stale in-flight page warm completion after `cancel()`.

Why this was necessary:

- Without invalidation, old futures could mark pages as ready/warm after the cache had already been cleared. That can cause the next navigation to skip a required decode/prewarm cycle and reintroduce cold-frame jank.

### 2. Hardened `AssetVerseMarkerRepository` ownership boundaries

File:

- `lib/data/repositories/asset_verse_marker_repository.dart`

Changes:

- Disposed the repository-owned `initializedNotifier` in `dispose()`.
- Cleared repository-held caches on disposal.
- Returned immutable `List<VerseMarkerData>` snapshots from cached/build paths instead of exposing mutable internal collections.

Why this was necessary:

- The repository was exposing mutable cached collections, which allowed external callers to corrupt repository state accidentally.
- The owned notifier was never disposed even though the DI container already wires a repository dispose callback.

### 3. Added fail-fast validation for page lookup tables

Files:

- `lib/page_mapping.dart`
- `test/page_mapping_test.dart`

Changes:

- Added centralized validation that `_surahByPage`, `_juzByPage`, and `_hizbByPage` each contain exactly `PageState.quranPageCount` entries before building the lookup list.
- Made the generated `pages` list immutable.
- Added tests for lookup table size, representative page metadata, and invalid page guards.

Why this was necessary:

- These hardcoded tables are the source of truth for O(1) page metadata lookup. A future manual edit that changes table length would otherwise fail later as an opaque runtime indexing error instead of a clear startup failure.

## Verification

Executed after the changes:

- `dart format lib/data/services/quran_image_prewarm_service.dart lib/data/services/flutter_decoded_quran_image_cache.dart lib/data/repositories/asset_verse_marker_repository.dart lib/page_mapping.dart test/quran_image_prewarm_service_test.dart test/page_mapping_test.dart`
- `flutter analyze`
- `flutter test`

## Coverage Expansion

Date: 2026-04-16

Additional test coverage work completed after the production-readiness fixes.

### New Test Files Added

- `test/app_message_mapper_test.dart`
- `test/asset_verse_marker_repository_test.dart`
- `test/flutter_decoded_quran_image_cache_test.dart`
- `test/in_memory_repositories_test.dart`
- `test/navigation_bloc_test.dart`
- `test/navigation_layers_test.dart`
- `test/preloading_screen_test.dart`
- `test/quran_image_app_test.dart`
- `test/quran_image_extract_isolate_test.dart`
- `test/quran_image_reader_test.dart`
- `test/verse_marker_test.dart`

### Coverage Areas Added

- Marker path generation and verse marker warm-up/rendering
- Asset marker repository production and debug loading paths
- Preloading screen success, retry, and marker-init failure flows
- Navigation bloc lifecycle, debounce save, retry, and auto-hide behavior
- Navigation widgets, overlay interactions, and presentation-layer state
- Decoded image cache warmup, trimming, memory-pressure handling, and error propagation
- Reader lifecycle, swipe navigation, and memory-pressure handling
- In-memory repositories and isolate extraction helpers
- App bootstrap flow for preload and navigation-init error recovery

### Coverage Result

Package coverage after this pass:

- `flutter test --coverage`
- `lcov --summary coverage/lcov.info`

Measured line coverage:

- `82.0% (2336 / 2848 lines)`

### Notes

- This is a material increase from the earlier baseline (`38.1%`).
- Reaching `90%+` package-wide would require a broader test pass across the remaining large modules, especially:
  - `lib/quran_image_reader.dart`
  - `lib/data/repositories/cloudflare_quran_image_cache_repository.dart`
  - `lib/data/services/quran_image_prewarm_service.dart`
  - additional debug-preload branches in `lib/data/repositories/asset_verse_marker_repository.dart`

## Review Summary

### Clean Architecture

- The project already has recognizable domain/data/presentation boundaries and repository abstractions.
- There is still service-locator usage inside UI layer classes, which is a layering smell, but it was not changed because it is not currently a production correctness blocker and would require broader restructuring.

### SOLID

- Single-responsibility is generally reasonable in the cache and repository layers.
- The concrete fixes above address the main production issues found in lifecycle ownership and state encapsulation.

### Data Structures and Complexity

- Page metadata lookup remains O(1) through indexed tables.
- Marker lookup remains near O(1) through page-keyed caches and flat-buffer offsets.
- Line-image path resolution remains O(1) through flat integer cache keys.
- Prewarm state remains bounded through queueing and small LRU-style sets/maps.
