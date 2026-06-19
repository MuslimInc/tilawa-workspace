# Quran Reader Architecture

## Overview

The Quran reader renders a 604-page mushaf using per-page QCF4 bitmap fonts. Each page has its own font file (`QCF_P001.woff`–`QCF_P604.woff`), registered dynamically with the Flutter engine. Pages are laid out as a 15-line RTL text grid using `TextPainter`.

---

## Android rendering backend

**Policy:** Tilawa ships **Skia** on Android and keeps **Impeller disabled** until
Flutter's Impeller backend is stable for our workload (604 per-page bitmap fonts,
heavy glyph-atlas churn, verse-marker tessellation).

Configuration: `apps/tilawa/android/app/src/main/AndroidManifest.xml`

```xml
<meta-data
    android:name="io.flutter.embedding.android.EnableImpeller"
    android:value="false" />
```

**Why:** On real devices we saw first-frame raster spikes (17–55 ms) from Impeller's
lazy glyph-atlas build when switching pages/fonts. Warm-up mitigations help, but
Skia is the safer default until Impeller behaviour is predictable across our
device matrix.

**Re-enable checklist (when revisiting):**

1. Remove or set `EnableImpeller` to `true` in the manifest above.
2. Cold-start and page-flip on mid-range Android (profile mode); compare raster
   thread timings vs Skia baseline.
3. Re-run glyph warm-up paths (`precacheTextGlyphs`, verse-marker warm-up) and
   confirm no regression on orientation change.
4. Check `adb logcat` for `Using the Impeller rendering backend`.

Glyph warm-up and `PreparedQuranPage` pre-layout remain renderer-agnostic; they
benefit both Skia and Impeller.

---

## Stack

```
QuranFontLoaderScreen          — font/data readiness gate
  └── QuranReaderScreen        — stateful reader host
        └── _ReaderScaffold    — page controller, prepared-window notifier
              └── QuranPageView
                    └── PageContent (×604, windowed)
                          └── QuranLine (TextPainter-backed custom painter)
```

**Services (singletons):**
- `QuranFontService` — font file download, engine registration, glyph atlas warm-up
- `QuranDataService` — loads `qpc-v4.json` (word→surah/ayah/glyph mapping for all 604 pages)
- `QuranPagePreparationService` — builds and caches `PreparedQuranPage` (pre-laid-out `TextPainter` blocks)

---

## Original Architecture & Performance Issues

### Loading gate (`_LoadingView`)

`QuranFontLoaderScreen` guarded the reader behind two async barriers:

1. **`registering` state** — font registered + data loaded + glyph atlas warmed (~200–500 ms) → showed `_LoadingView` spinner.
2. **`_isReaderPrepared` gate** — even after `success`, the reader was rendered `Offstage` until `onInitialPreparedWindowReady` fired. This callback was called only after `_ReaderScaffoldState` had mounted, triggered `_prepareVisibleWindow()` asynchronously (font check → data check → `endOfFrame` yield → `TextPainter.layout()` × 15), and published the window notifier. Typically added another 1–3 frames of latency.

Result: user saw a spinner for 200–700 ms every time they opened the reader, even on subsequent opens when fonts were already cached on disk.

### First-frame raster jank (~17–55 ms)

On Impeller (disabled on Android — see [Android rendering backend](#android-rendering-backend)), the engine builds its glyph atlas lazily — the first frame that paints a glyph for a given `(fontFamily, fontSize)` pays the GPU texture upload cost on the raster thread. With 604 per-page fonts, every new page triggered a ~17–21 ms raster spike. Skia has similar atlas work but behaved more predictably on our device matrix, which is why we default to Skia for now.

### `PageContent` build-time work

Without a `PreparedQuranPage`, `PageContent.build()` called:
- `QuranDataService.getPageData()` (dict lookup)
- `_buildLineWidgets()` → 15 `TextPainter()..layout()` calls (~3–8 ms)
- `SpacedLines` list construction

All on the UI thread, inside `build()`.

---

## Bottleneck Summary

| Bottleneck | Cost | Source |
|---|---|---|
| `_LoadingView` visible | 200–700 ms | Async font + data init before reader shown |
| `_isReaderPrepared` gate | 1–3 frames | Offstage prepare + callback round-trip |
| First-frame glyph atlas | 17–55 ms raster | Lazy atlas build on first paint (Impeller; mitigated via warm-up; Skia on Android) |
| `PageContent` build work | 3–8 ms UI | 15× `TextPainter.layout()` in `build()` |

---

## Refactoring Plan

### Principle: move all readiness work before the reader is shown

The reader should mount with everything already prepared. `build()` must be zero-cost: no data lookups, no `TextPainter` construction, no async gates.

### Step 1 — Await glyph atlas before `emit(success)`

In `QuranFontLoaderBloc._onInitialize`:
```
loadFontsToEngine()       → font registered in engine
ensureQuranDataLoaded()   → JSON data available
warmInitialPage()         → glyph atlas pre-built (off-screen warm-up)
emit(success)             → reader shown
```

This ensures the first on-screen frame finds the atlas already warm. The user waits on the font-loader screen (which now shows nothing for the ~200 ms registering phase), then the reader appears with no raster spike.

### Step 2 — Pre-compute `PreparedQuranPageWindow` before mounting reader

`QuranFontLoaderScreen.build()` now computes the initial ±2 page window synchronously when it receives `success`:

```dart
_initialPreparedWindow ??= _buildInitialPreparedWindow(initialPageNumber);
```

`_buildInitialPreparedWindow` calls `QuranPagePreparationService.preparePage()` for pages `[p-2 … p+2]` (only those whose fonts are loaded). This runs 15 `TextPainter.layout()` calls per page — ~5 ms total — synchronously on the UI thread, once, before the reader widget tree is created.

### Step 3 — Publish window synchronously in `initState`

`_ReaderScaffoldState.initState` initialises `_preparedWindowNotifier` directly with the pre-computed window:

```dart
_preparedWindowNotifier = ValueNotifier<PreparedQuranPageWindow?>(
  widget.initialPreparedWindow,
);
```

On the first `build()` call, `QuranPageView` already has a complete `PreparedQuranPageWindow`. `PageContent` receives a `PreparedQuranPage` and its `build()` is zero-cost: no data lookups, no layout work.

### Step 4 — Remove `_LoadingView` and `_isReaderPrepared` gate

`_LoadingView`, `_isReaderPrepared`, `_cachedReaderView` (offstage pattern), and `onInitialPreparedWindowReady` are all deleted. The `success` branch in `QuranFontLoaderScreen` builds `QuranReaderScreen` directly and returns it.

### Step 5 — Await atlas warm-up for programmatic jumps

`ensureSingleFontLoaded` now awaits `_precacheGlyphAtlas` instead of fire-and-forget. In `_jumpToPage`, the current page stays visible while the awaited warm-up runs (~50–100 ms), then `jumpToPage` fires — the new page appears with no raster spike, no loading indicator.

---

## New Architecture

### Startup sequence

```
App cold start
  │
  ├── QuranFontService.loadFontsToEngine()
  │     └── FontLoader.load() for initial page font
  │
  ├── QuranDataService.ensureLoaded()
  │     └── parse qpc-v4.json (~2 MB, isolate-parsed)
  │
  ├── QuranFontService.warmInitialPage(p)
  │     └── precacheTextGlyphs() → PictureRecorder → picture.toImage()
  │           └── renderer builds glyph atlas on GPU (off-screen)
  │
  ├── emit(success)   ← bloc emits here
  │
  ├── QuranFontLoaderScreen._buildInitialPreparedWindow(p)
  │     └── QuranPagePreparationService.preparePage() × 5 pages
  │           └── TextPainter.layout() × 15 per page (sync, ~5 ms)
  │
  └── QuranReaderScreen mounts
        └── _preparedWindowNotifier already has the window
              └── PageContent.build() → zero-cost paint
```

### Jump sequence

```
User taps surah
  │
  ├── current page stays visible (no spinner)
  │
  ├── await ensureSingleFontLoaded(target)
  │     ├── FontLoader.load()
  │     └── await _precacheGlyphAtlas()   ← atlas warmed before jump
  │
  ├── _pageController.jumpToPage(target - 1)
  │
  └── target page renders instantly (atlas already built)
```

### Page window management

`_ReaderScaffoldState` maintains a `±2` page window in `_preparedWindowNotifier`. After the initial synchronous publish:
- On page change: `_scheduleVisibleWindowPreparation` prepares new pages one-per-frame to avoid stalling the raster thread.
- `QuranPagePreparationService` keeps an 8-entry LRU cache of `PreparedQuranPage` objects, keyed by `(pageNumber, fontSize, fontHeight, viewportWidth, textColor)`.
- On orientation/theme change: cache is cleared and the window is re-prepared.

### Memory budget

| Object | Size (est.) | Count |
|---|---|---|
| `PreparedQuranPage` (TextPainter × ~15) | ~40 KB | 8 (LRU) |
| Font bytes in engine | ~80 KB/font | window × 5 |
| Glyph atlas texture | ~512 KB | per font loaded |
| `PageContent` widget state | ~2 KB | kept-alive ±1 |

Total RSS impact: ~5–10 MB for a 5-page window, well within budget.

---

## How Instant Rendering Is Achieved

1. **No work in `build()`** — `PageContent` receives a complete `PreparedQuranPage` (pre-laid `TextPainter` blocks). `build()` iterates the blocks list and returns `QuranLine` widgets; no data access, no layout computation.

2. **Glyph atlas pre-built** — `precacheTextGlyphs()` drives an off-screen `PictureRecorder → Canvas → picture.toImage()` pipeline that forces the active renderer (Skia on Android) to upload glyphs before the page is on-screen. The raster thread has nothing to build on first paint.

3. **No async gap on mount** — `_preparedWindowNotifier` is initialised with the pre-computed window in `initState`. `QuranPageView`'s first `build()` already has a non-null `PreparedQuranPageWindow`. There is no frame where `PageContent` must fall back to on-demand computation.

4. **Window-based, not full-corpus** — Only ±2 pages around the current page are prepared at any time. Background preparation is one-page-per-frame, gated behind `endOfFrame` yields and interaction pauses, so it never competes with user-visible rendering.

---

## KMP Analogy

The Android KMP reader (`QuranKmpReader`) achieves instant rendering via the same principle: all `TextMeasurer.measure()` calls (equivalent to `TextPainter.layout()`) are performed on a background `CoroutineScope` before the `Canvas` draw call. The Compose recomposition that triggers `drawText()` finds pre-measured layout objects ready in a `SnapshotStateMap` — zero measurement cost in the draw phase.

The Flutter implementation mirrors this: `QuranPagePreparationService.preparePage()` is the `TextMeasurer.measure()` equivalent, `PreparedQuranPage` is the layout cache, and `QuranLine` (which calls `painter.paint()` directly) is the draw-only phase.
