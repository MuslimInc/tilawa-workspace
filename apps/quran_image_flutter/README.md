# Quran Image Flutter

A high-performance Flutter Quran reader that renders 604 pages of pre-rastered PNG line images with verse markers, surah headers, and smooth navigation.

---

## Features

- **Image-based line rendering** — 15 pre-rendered PNG images per page (1440×232 each), zero text layout overhead during scroll
- **Verse marker overlay** — QCF-style golden markers with Arabic verse-number glyphs painted in a single custom-paint pass per page
- **Surah header banners** — Calibrated decorative banner images aligned to header lines via a linear-regression layout policy
- **Slider navigation** — Drag-to-preview with live prewarm, instant jump for large deltas, animated scroll for small deltas
- **Portrait and landscape** — Layout adapts; landscape wraps content in a scroll view when it exceeds the viewport
- **Clean Architecture** — Domain / Data / Presentation layers with dependency injection via `get_it`

---

## Architecture

```text
lib/
├── core/
│   ├── constants/          # Layout constants, CDN URLs
│   ├── design_tokens/      # Colors, durations
│   └── di/                 # Dependency injection (get_it)
├── domain/
│   ├── entities/           # PageState, VerseMarkerData, SurahHeaderData, …
│   ├── repositories/       # Abstract repository interfaces
│   ├── services/           # DecodedQuranImageCache, QuranImagePrewarmer (abstractions)
│   └── usecases/           # PrepareQuranImageCache, GetLastVisitedPage, …
├── data/
│   ├── repositories/
│   │   ├── asset_verse_marker_repository.dart   # Flat-packed JSON marker data
│   │   ├── cloudflare_quran_image_cache_repository.dart  # Download + extract pipeline
│   │   └── static_surah_header_repository.dart
│   └── services/
│       ├── flutter_decoded_quran_image_cache.dart  # Wraps Flutter's ImageCache
│       └── quran_image_prewarm_service.dart        # Queue-based background prewarm
└── presentation/
    ├── bloc/navigation/    # NavigationBloc — page state, slider, auto-hide
    └── widgets/            # Slider overlay, bottom bar, navigation controls
```

---

## Setup

### 1. First run — cache download

On first launch the app downloads and extracts the Quran image archive from the CDN. A progress screen shows download and extraction status. Subsequent launches skip directly to the reader via a fast-path metadata check.

### 2. Run in debug

```bash
flutter run
```

### 3. Run in profile mode (performance measurement)

```bash
flutter run --profile
```

Profile mode activates `PerfLogger`, which logs slow frames (build > 20 ms or raster > 20 ms) and timing spans for key operations.

---

## Performance Design

### Image pipeline

Each page renders 15 `_QuranLineImage` widgets. Each uses:

```dart
ResizeImage.resizeIfNeeded(cacheWidth, null, FileImage(path))
```

`cacheWidth` is the physical-pixel screen width, computed once in `didChangeDependencies`. This ensures Flutter's LRU image cache (180 MB / 300 items) stores images at the exact resolution needed by the device — avoiding re-decode on subsequent views and preventing GPU over-upload from full-resolution textures.

### Prewarm service

`QuranImagePrewarmService` maintains a background decode queue. It is triggered by five events:

| Trigger | Method | Timing |
| --- | --- | --- |
| App open | `startInitialPrewarm` | 800 ms after first frame |
| Scroll tick | `prewarmCurrentTarget` | Immediate, deduplicated |
| Slider drag | `prewarmPreviewTarget` | 80 ms debounce |
| Large jump (delta > 3) | `prewarmJumpTarget` | Immediate — see below |
| Page settled | `prewarmSettledWindow` | 220 ms delay, radius ±1 |

The queue drains in batches of 8 images with a 2 ms budget per batch and 16 ms gaps, preventing main-thread starvation while keeping decodes progressing between frames.

### Verse marker repository

Production mode loads `verse_marker_coordinates.json` (≈779 KB) using `rootBundle.load` (returns `ByteData`, avoiding a 70 ms UTF-16 string allocation), then decodes it on a background isolate via `compute`. The result is a `Float64List` transferred zero-copy across the isolate boundary.

A lightweight page-offset index is built on the UI thread (~0.1 ms for 604 pages), mapping each page number to its slice in the flat buffer. Individual pages are decoded lazily on first access (~0.1 ms each), eliminating the 60 ms "unpack all 6 000 objects at once" spike.

Individual `QuranImagePage` widgets subscribe to `initializedNotifier` and rebuild in a staggered pattern (1–6 frame delay by page number) so the marker-ready frame does not burst-rebuild all visible pages simultaneously.

---

## Performance Improvements (April 2025)

The following targeted fixes address real bottlenecks identified in profile-mode logs.

### 1. Marker warm-up at actual render size

#### Problem — SLOW FRAME #5, build=61.7 ms

`VerseMarker.warmUpFont()` was called unconditionally at a hardcoded `fontSize: 20.0` and path `Size(20, 25)`. Both the `TextPainter` cache and the QCF path cache are keyed by size. At paint time `_VerseMarkersPainter` uses:

```dart
markerWidth  = pageWidth * 0.05138889   // ≈ 55 px on a 1080 px screen
markerHeight = pageWidth * 0.06527778
```

The 20 px warm-up produced **zero cache hits** when the first page painted. Every `TextPainter.layout()` call ran cold in the marker-ready rebuild frame, causing the 61.7 ms build spike.

#### Fix

`warmUpFont` now accepts the actual logical-pixel marker width:

```dart
VerseMarker.warmUpFont({double markerWidth = 20.0})
```

`QuranImageReader` computes `_markerWidth = screenWidth * 0.05138889` in `didChangeDependencies` (alongside `_cacheWidth`) and passes it to `warmUpFont` in the first post-frame callback. The warm-up now hits the same cache keys the painter will use.

#### Files changed (warm-up fix)

- [lib/verse_marker.dart](lib/verse_marker.dart)
- [lib/quran_image_reader.dart](lib/quran_image_reader.dart)

---

### 2. Slider-jump images resolve before `jumpToPage`

#### Root cause — far-page jumps render several frames of gray placeholders

Two separate bugs combined to prevent immediate rendering after a large jump.

##### Bug A — dedup guard silently skipped the prewarm

`_prewarmAround` has a deduplication guard:

```dart
if (_lastPrewarmedCenter == safeCenter && …) return;
```

If the user dragged the slider near the target page (e.g. page 197) before committing the jump, `_lastPrewarmedCenter` was already 197. The guard returned early without enqueuing anything — the jump target had **zero images in the decode pipeline**.

##### Bug B — queue drain fired after `jumpToPage`, not before

`_scheduleDrain()` uses `Timer(Duration.zero, _drainBatch)`. A zero-duration timer fires on the **next event-loop tick** — after `jumpToPage` has already been called. `jumpToPage` triggers a synchronous frame build of the target page with `FileImage` providers. Those providers start loading, but the prewarm queue has not drained yet. With 15 images per page, 8-per-batch draining at 16 ms gaps requires at least two batches (~32 ms) before all images are decoded. The page already rendered placeholder frames.

#### Solution

`prewarmJumpTarget` now:

1. Resets all three dedup fields unconditionally before every jump, so the guard never skips a target regardless of previous preview state.
2. Calls `_prewarmPageImmediate()` — a new private method that calls `provider.resolve()` for all 15 line images **synchronously on the current event-loop tick**, giving the image codec maximum head-start before `jumpToPage` is called at the call site.
3. Still enqueues via `_prewarmAround` as a safety net for cache eviction on low-memory devices.

The call site in `QuranImageReader` is unchanged — `prewarmJumpTarget` is still called before `jumpToPage`.

#### Files changed (jump fix)

- [lib/data/services/quran_image_prewarm_service.dart](lib/data/services/quran_image_prewarm_service.dart)

---

### 3. Prewarm queue batch size increased

#### Root cause — settled-window prewarm drained too slowly

With a batch size of 5 and a 16 ms inter-batch delay, warming 45 images (3-page window) required 9 batches taking at minimum 144 ms. Pages two positions ahead of the current page were frequently still cold when reached by swiping.

#### Solution

`_prewarmImagesPerBatch` increased from 5 to 8. The 2 ms budget check per batch remains the real throttle, so no additional jank is introduced on any device. Fewer batches are needed to drain the same queue depth.

#### Files changed (batch size fix)

- [lib/data/services/quran_image_prewarm_service.dart](lib/data/services/quran_image_prewarm_service.dart)

---

## Safety Guarantees

All changes were made without modifying:

- Verse marker position formula (`centerX * pageWidth`, clamped to page bounds)
- Line Y-offset formula (`(layoutHeight - lineHeight) / 14 * i`, matching the Ayah app)
- Surah header banner layout policy (linear regression model, portrait/landscape aware)
- `RepaintBoundary` isolation for the marker overlay
- `gaplessPlayback: true` on all image widgets
- `allowImplicitScrolling: false` on `PageView`
- Flat-buffer marker data format and O(1) page-offset index
- Staggered page rebuild on `initializedNotifier`
- Clean Architecture layer boundaries (no business logic moved to presentation)

---

## Verification Checklist

Run in profile mode and confirm:

- `[SLOW FRAME #5]` build time drops from ~61 ms to < 20 ms (marker warm-up cache hit)
- Log shows `jump-target immediate resolve page=X images=15` **before** `QuranImagePage page=X build` on every large jump
- Jump from page 1 → 450 or 450 → 89: line images appear on the first rendered frame, no gray placeholders
- Jump to a page previously visited via slider drag: images still appear instantly (dedup reset confirmed)
- Verse markers render at correct positions on pages 1, 2, and 604
- Surah header banners render correctly on pages that begin a new surah
- Portrait and landscape orientations both display correctly
