# Decode-First Page Navigation

This document describes the current decode-first page navigation work for
`quran_image`, including the implementation shape and the validation
cases that should be used to verify it.

## Goal

The reader should behave like the Ayah native app during page navigation:

- `QuranImagePage` renders synchronously.
- Page navigation waits for the target page to be prepared before commit.
- Large jumps do not show placeholders, line-by-line appearance, or delayed UI
  swaps.
- Per-page build cost stays near zero because the page widget only constructs
  providers and layout; decode readiness is handled outside the widget.

## Implemented Architecture

### 1. `QuranImagePage` is synchronous again

File:

```text
lib/quran_image_page.dart
```

What changed:

- Removed widget-side waiting logic.
- Removed placeholder / loading-surface rendering.
- Removed cache polling from the page widget.
- Restored a synchronous build path that always renders immediately from local
  `ImageProvider`s.

Current rule:

- If a page is visible, navigation was already responsible for warming it.
- `QuranImagePage` never blocks on readiness.

### 2. Decode readiness moved into the cache service

Files:

```text
lib/domain/services/decoded_quran_image_cache.dart
lib/data/services/flutter_decoded_quran_image_cache.dart
```

What changed:

- `DecodedQuranImageCache` now exposes future-based warmup methods:
  - `prewarmLineImage(...)`
  - `prewarmFileImage(...)`
- The implementation deduplicates in-flight warmups and reuses warm entries.
- Warmup completion is driven by the image stream completion callback rather than
  polling `ImageCache`.

Why:

- The old approach waited by repeatedly checking cache state.
- The new approach treats warmup as an async preparation job and awaits the
  decode completion directly.

### 3. Navigation now owns page readiness

Files:

```text
lib/domain/services/quran_image_prewarmer.dart
lib/data/services/quran_image_prewarm_service.dart
lib/quran_image_reader.dart
```

What changed:

- Added `QuranImagePrewarmer.ensurePageReady(...)`.
- Added `handleMemoryPressure()` to the prewarm/cache contracts.
- Removed the old `prewarmJumpTargetAndWait(...timeout...)` contract.
- `QuranImagePrewarmService` now:
  - gathers all 15 line-image futures for a page,
  - awaits them as a single readiness boundary,
  - caches only a bounded set of ready page keys,
  - logs partial / failed warmups,
  - keeps settled-window warmup,
  - throttles preview warmup to the latest scrub target only.

Navigation flow now:

1. Request target page.
2. Start jump-target prewarm immediately.
3. Await `ensurePageReady(...)`.
4. For long jumps, capture a prerendered page snapshot before committing the jump.
5. Commit `jumpToPage(...)` or `animateToPage(...)`.

This keeps all waiting outside `QuranImagePage`.

### 4. Snapshot-based prerender for long jumps

File:

```text
lib/quran_image_reader.dart
```

What changed:

- Replaced the old "insert hidden page and wait two frames" heuristic.
- Long jumps now use a hidden `RepaintBoundary` plus `RenderRepaintBoundary.toImage(...)`.
- The captured `ui.Image` is shown as a temporary `RawImage` overlay during
  the `PageView.jumpToPage(...)` commit.
- Readiness is now based on a successful snapshot capture, not on a fixed frame
  delay.

Why:

- Flutter still does not expose a public "GPU upload complete" callback.
- `toImage(...)` is the strongest deterministic public signal available that
  the subtree has actually been painted.
- The snapshot overlay removes the bad UX where the previous page stays visible
  while the jump target catches up.

### 5. Preview warmup is no longer aggressive

File:

```text
lib/data/services/quran_image_prewarm_service.dart
```

What changed:

- Slider preview warmup is now latest-only and debounced.
- The old preview-window warmup path was removed.
- Intermediate scrub pages no longer decode 45 images at a time while the thumb
  is still moving.

Why:

- This was the main source of the repeated `preview-window` work visible in the
  profile logs.
- The final jump path already blocks on `ensurePageReady(...)`, so preview does
  not need to decode every page the slider crosses.

### 6. Memory policy

Files:

```text
lib/data/services/flutter_decoded_quran_image_cache.dart
lib/data/services/quran_image_prewarm_service.dart
lib/quran_image_reader.dart
```

Current policy:

- Decoded line/provider cache: max 6 warmed pages
  - `6 * 15 = 90` line entries
  - plus up to `8` file/banner entries
- Ready-page metadata cache: max `6` pages
- Jump snapshot cache: max `1` full-page snapshot
- All caches are LRU bounded.
- On memory pressure:
  - pending preview / drain timers are cancelled,
  - ready-page metadata is cleared,
  - decoded/provider cache entries are evicted,
  - Flutter `imageCache.clear()` is called,
  - cached jump snapshots are disposed.

### 7. Failure handling

What changed:

- Warmup failures are now logged explicitly.
- Partial page warm failures do not deadlock navigation.
- Snapshot capture has a bounded retry loop and logs a fallback if paint never
  stabilizes.
- If snapshot capture fails, navigation still proceeds instead of blocking
  indefinitely.

## Files Affected

Implementation files:

```text
lib/quran_image_page.dart
lib/quran_image_reader.dart
lib/preloading_screen.dart
lib/data/services/flutter_decoded_quran_image_cache.dart
lib/data/services/quran_image_prewarm_service.dart
lib/domain/services/decoded_quran_image_cache.dart
lib/domain/services/quran_image_prewarmer.dart
pubspec.yaml
```

Validation file:

```text
test/quran_image_page_test.dart
test/quran_image_prewarm_service_test.dart
```

## Automated Validation

### Static analysis

Run:

```sh
flutter analyze
```

Expected result:

- No analyzer errors or warnings related to the new prewarm contracts or page
  navigation path.

### Automated test suite

Run:

```sh
flutter test
```

Expected result:

- All tests pass.

### Targeted widget test

Relevant file:

```text
test/quran_image_page_test.dart
```

What it validates:

- `QuranImagePage` builds synchronously.
- No loading-surface widget is present.
- The page tree contains the expected `Image` widgets immediately.

Targeted run:

```sh
flutter test test/quran_image_page_test.dart
```

Expected result:

- The test passes with no loading surface found.

### Targeted service test

Relevant file:

```text
test/quran_image_prewarm_service_test.dart
```

What it validates:

- Preview warmup only prepares the latest scrub target.
- Memory pressure cancels pending preview work and clears prewarm state.

Targeted run:

```sh
flutter test test/quran_image_prewarm_service_test.dart
```

## Manual Validation Matrix

Run the app in profile mode on the target device:

```sh
flutter run --profile
```

Use the following cases.

### Case 1: Initial app open

Steps:

1. Cold launch the app.
2. Wait for the reader to appear.

Expected:

- The first page appears fully rendered.
- No placeholder or delayed line appearance is visible.

### Case 2: Long jump `1 -> 300`

Steps:

1. Open the navigation slider on page 1.
2. Jump directly to page 300.

Expected:

- Navigation commit happens only after the target page is ready.
- Page 300 appears already complete.
- No previous-page flash.
- No blank surface, no line-by-line fill, no delayed swap.

### Case 3: Long jump `300 -> 1`

Steps:

1. From page 300, jump back to page 1.

Expected:

- Same behavior as Case 2.
- Revisited warm pages should appear immediately.

### Case 4: Fast slider scrubbing

Steps:

1. Drag the slider rapidly across many pages.
2. Release on a far target.

Expected:

- Preview updates do not enqueue repeated `preview-window` work.
- Releasing on a far target should show one jump snapshot path, then the live
  page.

## Proof Logs To Watch

In a profile run, the key log lines are now:

```text
[PerfLogger][QuranImageReader] snapshot ready page=... attempt=1 size=...x... elapsedMs=...
[PerfLogger][QuranImageReader] jump snapshot shown page=...
[PerfLogger][QuranImageReader] jump snapshot cleared page=... attempts=1
[PerfLogger][QuranImagePrewarmService] page ready reason=ensure-page page=... images=15 elapsedMs=...
[PerfLogger][QuranImagePrewarmService] memory pressure handled readyPagesCleared=true
[PerfLogger][FlutterDecodedQuranImageCache] memory pressure handled evictedProviders=... evictedWarmEntries=...
```

`attempt=1` on every jump and `attempts=1` on every clear confirms the
snapshot pipeline is working end-to-end. Any value above 1 indicates the
warmup subtree was not yet painted when the first capture was attempted.

What should disappear from the old logs:

- `snapshot failed … Null check operator used on a null value`
- `snapshot unavailable page=... reason=paint-never-stabilized`
- repeated `reason=preview-window` during slider scrubbing
- `Another exception was thrown: Instance of 'ErrorSummary'`
- previous-page flash or reversion to old page in `NavigationSliderOverlay`
- raster frames of 20–25 ms during the decode window before a jump commit

### Case 5: Adjacent navigation

Steps:

1. Use next / previous page controls repeatedly.

Expected:

- Neighbor pages should feel instant because settled-window decode prewarm
  should already have run.

### Case 6: Swipe navigation

Steps:

1. Swipe normally between adjacent pages.

Expected:

- No visible difference between swipe and jump in how the page appears.

### Case 7: Repeat jump to already visited page

Steps:

1. Jump to page 200.
2. Jump away.
3. Jump back to page 200.

Expected:

- Return navigation should be faster because both decode readiness and raster
  snapshot readiness may already exist for that viewport.

### Case 8: Orientation / viewport change

Steps:

1. Change orientation or otherwise alter the viewport.
2. Repeat long-jump navigation.

Expected:

- Warmup should re-run for the new viewport key.
- The page should still appear fully rendered after navigation commit.

## Performance Validation

Profile with Flutter DevTools timeline while running Cases 2, 4, and 6.

What to inspect:

- Raster time for the first visible frame after navigation.
- Whether the `snapshot ready` log appears before the jump commit.
- Whether the visible post-navigation frame remains stable.

Useful `PerfLogger` signals:

- `QuranImagePrewarmService page ready ...`
- `QuranImageReader slider jump delta=...`
- `QuranImagePage page=... build ...`

Expected profile characteristics:

- No placeholder frame.
- No delayed appearance of image lines.
- Lower raster pressure on the first visible frame after the navigation commit.

## Important Constraint

This implementation keeps the logic outside the presentation widget itself, but
`quran_image_reader.dart` still owns the navigation-time snapshot coordination because
it controls the `PageView` commit point. The page widget remains presentation
only and synchronous.

## Current Practical Limitation

Flutter does not currently provide a clean public signal that definitively means
"the image is uploaded to GPU and the first visible frame is guaranteed cheap".

The current implementation uses the following practical sequence:

1. Await image decode completion in batches of 5 lines at a time
   (`_warmBatchSize = 5`) to avoid bursting all 15 decode callbacks into a
   single vsync window.
2. Render the target page through a hidden `RepaintBoundary` pushed off-screen
   with `Transform.translate(offset: Offset(0, 100000))`.
3. Require a successful `toImage(...)` snapshot capture, gated by
   `renderObject.attached && renderObject.hasSize` (works in all build modes).
4. Commit `jumpToPage(...)` while that snapshot is shown as a `RawImage`
   transition overlay — the user sees the pre-rasterised image, not the live
   page, during the commit frame.
5. Hold the overlay until `_lastSettledPageIndex == targetIndex` plus one
   additional `endOfFrame`, giving the raster thread time to paint the live
   page before the overlay is removed.
6. Clear the preview state only after settle, so `NavigationSliderOverlay`
   never reverts to the old committed page during the decode window.

That is the mechanism currently implemented to approximate "GPU-ready before
navigation" within Flutter's public rendering model.

### Known trade-off

Batching decode into three sequential groups of 5 increases total decode time
from ~120 ms to ~330–380 ms compared to firing all 15 concurrently. This extra
latency is fully hidden: it occurs while the user is still on the old page and
the slider overlay still shows the target page number. The user experiences it
as a slightly longer pause before the jump commits, not as a visual artifact.

---

## Fix Log

### Fix 1 — Snapshot readiness check (all build modes)

**File:** `lib/quran_image_reader.dart`

The original code guarded `toImage(...)` with:

```dart
(kDebugMode && renderObject.debugNeedsPaint)
```

`debugNeedsPaint` is a `late bool` on `RenderObject` that is never initialised
in profile or release builds. In those modes the guard was skipped entirely,
meaning `toImage()` could be attempted on a render object that had not yet
completed layout. The fix replaces it with public properties that work in all
build modes:

```dart
!renderObject.attached || !renderObject.hasSize
```

`hasSize` is false until layout has run; `attached` guards against a boundary
removed from the tree between frames.

### Fix 2 — Overlay clear timing

**File:** `lib/quran_image_reader.dart`

The snapshot overlay was cleared as soon as `_lastSettledPageIndex == targetIndex`.
That flag is set by `onPageChanged`, which fires from the PageView scroll
callback — before the raster thread has painted the live page. The fix adds one
additional `endOfFrame` wait after the settle signal, so the raster thread has
committed at least one frame of the live page before the overlay disappears.

### Fix 3 — Hidden warmup pages composited on every frame

**File:** `lib/quran_image_reader.dart`

The hidden warmup `RepaintBoundary` subtree was placed in a plain `Stack` below
the `PageView`. Flutter composited and painted it on every frame even though it
was invisible. `Offstage` was tried first but skips the paint phase entirely,
causing `toImage()` to crash with a null layer. The fix uses
`Transform.translate(offset: Offset(0, 100000), ...)` to push the subtree
100 000 logical pixels below the screen. The full render pipeline (layout +
paint + raster layer) runs normally so `toImage()` succeeds, but the content
is never inside the visible viewport and is never composited into the
on-screen layer tree.

### Fix 4 — Redundant scroll-listener dispatches

**File:** `lib/quran_image_reader.dart`

`_onScrollPositionChanged` called `prewarmCurrentTarget` on every scroll tick
(60–120 times per second during a swipe). Because the target is computed via
`page.round()`, the actual page number only changes at page boundaries. A
`_lastScrollPrewarmPage` guard was added so `prewarmCurrentTarget` is only
called when the rounded page changes.

### Fix 5 — `QuranImagePage.build()` hot-path logging cost

**File:** `lib/quran_image_page.dart`

`PerfLogger.startTimer()` / `logElapsed()` were called unconditionally on every
`build()` invocation. In profile and release builds this still allocated a
`Stopwatch`, formatted strings, and called the log sink — on every frame for
every page in the `PageView` cache. The logging is now gated behind `kDebugMode`
so profile and release builds pay zero cost for page builds.

### Fix 6 — `toImage()` crash from `Offstage` warmup container

**File:** `lib/quran_image_reader.dart`

`Offstage` was used to prevent the warmup subtree from appearing on screen.
`Offstage` skips the paint phase entirely — no raster layer is ever produced —
so `RenderRepaintBoundary.toImage()` null-dereferences the missing layer and
throws `Null check operator used on a null value` on every jump attempt. The
snapshot overlay was therefore never shown in practice.

The fix replaces `Offstage` with
`Transform.translate(offset: Offset(0, 100000), ...)`. The subtree goes through
the full layout + paint + rasterisation pipeline (raster layer exists, so
`toImage()` works), but its translated position places it 100 000 logical pixels
below the screen so it is never visible and never composited into the on-screen
frame.

Proof: after this fix every jump shows `snapshot ready page=N attempt=1` in
the logs, where previously every jump showed
`snapshot failed … Null check operator used on a null value`.

### Fix 7 — NavigationSliderOverlay flicker on long jump

**File:** `lib/quran_image_reader.dart`

`_clearPreviewPage()` was called at the start of the long-jump path, before
decode or `jumpToPage` ran. This nulled `_previewPageStateNotifier`
immediately, causing `effectivePageState` in the overlay to fall back to
`committedPageState` — which was still the old page for the entire ~130 ms
decode window. The overlay briefly showed the old page, then corrected when
`PageChanged` reached the BLoC.

The fix removes `_clearPreviewPage()` from the start of the long-jump path
entirely. It is called only after the jump has settled and the snapshot overlay
is cleared — at which point `committedPageState` already reflects the new page,
so nulling the preview causes no visible change.

### Fix 8 — Raster spikes from concurrent decode callback burst

**File:** `lib/data/services/quran_image_prewarm_service.dart`

`_warmPageImmediate` was firing all 15 `prewarmLineImage` futures simultaneously
via a single `Future.wait`. All 15 decodes completed at roughly the same time
(~110–130 ms later) because they all started at once, and their
`ImageStreamListener` callbacks arrived on the main isolate in a single burst.
That burst — 15 callbacks each doing map mutations, `image.dispose()`, and
`completer.complete()` — landed on the main thread during a vsync window and
pushed raster frame time to 20–25 ms.

The fix splits the 15 line-image decodes into sequential batches of 5
(`_warmBatchSize = 5`), awaiting each batch before starting the next. Each
batch's callbacks land in a separate event-loop turn so no single vsync window
sees more than 5 decode completions. Total decode time increases by roughly
the decode time of two additional batch rounds (~220–260 ms), but this latency
is invisible to the user because it occurs while they are still looking at the
old page before `jumpToPage` commits.
