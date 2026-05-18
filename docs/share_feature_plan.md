# Tilawa Share Feature — Implementation Plan

## Context

Users want to share Quran content from the Tilawa app to social media (WhatsApp Status, TikTok, Facebook, etc.). This requires two shareable content types: **audio clips** (verse-range recitations) and **page screenshots** (branded Mushaf images). The app currently has `share_plus` installed and an `AyahOptionsSheet` with a text-only share option — but no audio clipping, screenshot capture, or rich media sharing.

The scope is **not limited to Flutter** — native modules (Android/iOS), backend services, or media processing tools (e.g., FFmpeg) may be introduced where they provide the most reliable, production-ready solution.

---

## 1. Product / UX Flow

### 1A. Entry Points

**Entry Point 1 — Reader Bottom Bar (new share button):**
1. User reads Quran in `QuranReaderScreen` → taps screen to show overlay
2. A share icon appears in the `_PageNavigationBar`
3. Tap opens `ShareOptionsSheet` bottom sheet with two cards: **"Share Page Screenshot"** and **"Share Audio Clip"**

**Entry Point 2 — Ayah Options Sheet (existing long-press):**
1. User long-presses a verse → `AyahOptionsSheet` opens
2. The existing "Share Ayah" option is enhanced to show a sub-menu:
   - "Share as Text" (current behavior, unchanged)
   - "Share Page Screenshot"
   - "Share Verse Audio Clip" (pre-fills that single verse)

### 1B. Screenshot Flow
1. User taps "Share Page Screenshot"
2. UI overlays are hidden temporarily
3. Current Mushaf page is captured via `RepaintBoundary`
4. A branded image is composited: page image + bottom strip with Tilawa logo, surah name, page number, "Shared via Tilawa"
5. Native share sheet opens with the PNG file + caption text
6. Temp files cleaned up after share sheet closes

### 1C. Audio Clip Flow
1. User taps "Share Audio Clip"
2. `ShareAudioConfigSheet` opens showing:
   - Surah name (auto-filled from current page)
   - Verse range pickers: "From Ayah __ to Ayah __" (defaults: current page's first/last verse, or long-pressed verse)
   - Reciter selector (favorites first, then full list from `RecitersRepository`)
   - Estimated clip duration label
   - "Generate & Share" button
3. User configures and taps "Generate & Share"
4. Progress overlay: "Downloading verse 3 of 7…" with a cancel button
5. Verse-level MP3 files are downloaded, concatenated, and written to temp
6. Native share sheet opens with the MP3 file + caption: "Surah Al-Fatiha (1-7) — Recited by Al-Afasy — Shared via Tilawa"
7. Cleanup on dismiss

---

## 2. Technical Architecture

### 2.1 New Feature Structure

```
apps/tilawa/lib/features/share/
├── data/
│   ├── services/
│   │   ├── audio_clip_service.dart        # Download + concatenate verse audio
│   │   ├── screenshot_service.dart        # Capture widget → branded PNG
│   │   └── share_file_manager.dart        # Temp file lifecycle
│   └── repositories/
│       └── share_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── share_content.dart             # Sealed class: AudioClip | Screenshot
│   │   └── audio_clip_config.dart         # Surah, verse range, reciter
│   ├── repositories/
│   │   └── share_repository.dart          # Abstract interface
│   └── usecases/
│       ├── generate_audio_clip_use_case.dart
│       ├── capture_screenshot_use_case.dart
│       └── share_content_use_case.dart
└── presentation/
    ├── cubit/
    │   ├── share_cubit.dart               # Ephemeral Cubit (not HydratedBloc)
    │   └── share_state.dart               # Freezed state
    └── widgets/
        ├── share_options_sheet.dart        # "Screenshot" or "Audio Clip"
        ├── share_audio_config_sheet.dart   # Verse range + reciter picker
        └── branded_page_overlay.dart       # Offscreen branding compositor
```

### 2.2 State Management — `ShareCubit`

Ephemeral `Cubit<ShareState>` (no persistence needed):

```dart
@freezed
class ShareState with _$ShareState {
  const factory ShareState({
    @Default(ShareStatus.idle) ShareStatus status,
    // Audio config
    int? surahNumber,
    int? fromAyah,
    int? toAyah,
    ReciterEntity? selectedReciter,
    // Progress
    @Default(0.0) double progress,
    String? progressMessage,
    // Result
    String? generatedFilePath,
    String? errorMessage,
  }) = _ShareState;
}

enum ShareStatus { idle, configuring, generating, readyToShare, sharing, error }
```

### 2.3 DI Registration

Register via `@Injectable` / `@LazySingleton` annotations (same pattern as existing features). Key registrations:
- `AudioClipService` → `@LazySingleton`, depends on `Dio`
- `ScreenshotService` → `@LazySingleton`
- `ShareFileManager` → `@LazySingleton`
- `ShareCubit` → `@Injectable`

Provide `ShareCubit` in `AppProviders` alongside other BLoC providers.

---

## 3. Audio Clip Implementation

### 3.1 Audio Source Strategy

The `mp3quran.net` CDN serves **full surah files** (no verse-level granularity). Two verse-level audio sources are available:

| Source | URL Pattern | Pros | Cons |
|--------|------------|------|------|
| **Quran.com Verse API** | `https://verses.quran.com/{reciter}/{surah}{ayah}.mp3` | Real reciter voice, per-verse files | Limited reciter catalog, external API dependency |
| **QuranCDN WBW** | `https://audio.qurancdn.com/wbw/{surah}_{ayah}_{word}.mp3` | Already used in app, covers all verses | Single narrator voice (not the selected reciter), word-level not verse-level |

**Primary approach: Quran.com verse-level audio**

1. Maintain a **reciter mapping** (`reciter_audio_mapping.dart`) that maps the app's `mp3quran.net` reciter IDs/server paths → Quran.com reciter folder names for the top ~30 reciters (Husary, Al-Afasy, Sudais, Shuraim, Abdul-Basit, Minshawi, etc.)
2. For a selected verse range, download each verse MP3 in parallel (concurrency limit: 5)
3. Concatenate raw MP3 bytes (MP3 is frame-based — byte concatenation produces valid output)
4. Write to temp file

**Fallback: Full surah download + FFmpeg trim (for unmapped reciters)**

If a reciter is not in the Quran.com mapping but has a locally downloaded surah file (or can be streamed from `mp3quran.net`), use **FFmpeg** to extract the verse range. This requires verse timing data.

### 3.2 FFmpeg Integration (Native Module)

For production-quality audio clipping of full surah files:

**Package:** `ffmpeg_kit_flutter_audio: ^6.0.3` (audio-only variant, ~8MB vs ~30MB for full FFmpeg)

**When used:**
- Reciter not mapped to Quran.com verse API
- User has the full surah already downloaded locally
- Future v2: generating video (audio + page image) for WhatsApp Status / TikTok

**FFmpeg trim command:**
```
-i input.mp3 -ss {startTime} -to {endTime} -c copy -y output.mp3
```

**Verse timing data:** Quran.com provides verse timestamps via `https://api.quran.com/api/v4/quran/recitations/{id}` with timing info. Cache this data per reciter in Hive for offline access.

**Decision: Defer FFmpeg to Phase 2.** Phase 1 uses verse-level downloads only, which covers the majority of popular reciters with zero new native dependencies.

### 3.3 AudioClipService

```dart
@LazySingleton()
class AudioClipService {
  AudioClipService(this._dio, this._fileManager);

  /// Downloads verse-level audio and concatenates into a single MP3.
  /// Max 30 verses per clip.
  Future<String> generateClip({
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
    required String reciterFolder, // Quran.com reciter folder
    void Function(double progress, String message)? onProgress,
  });
}
```

**Implementation details:**
- Download verse files in parallel via `Dio` with concurrency pool of 5
- Cache individual verse files in `getApplicationSupportDirectory()/verse_cache/` for reuse
- Concatenate using `dart:io` `RandomAccessFile` for streaming writes (no full in-memory load)
- Run concatenation in `Isolate.run()` for verse ranges > 10
- LRU cache eviction at 100MB

### 3.4 Backend Service (Optional, for Scale)

For a more robust solution (especially for FFmpeg trimming), a lightweight **Cloud Function** or **backend microservice** could handle audio clipping server-side:

```
POST /api/clip
{
  "reciter_id": "husary",
  "surah": 2,
  "from_ayah": 255,
  "to_ayah": 257
}
→ Returns: presigned URL to the generated MP3 clip
```

**Advantages:** No FFmpeg on device, instant for cached clips, smaller app binary.
**Trade-off:** Requires infrastructure, adds latency, ongoing hosting cost.

**Decision: Not in scope for v1.** The client-side verse-level download approach works well for the initial release. A backend clip service can be added in v2 if demand warrants it.

---

## 4. Screenshot Implementation

### 4.1 Capture Approach

The `QuranReaderScreen` builds `QuranPageView` with `key: _pageViewKey`, but this is not wrapped in a `RepaintBoundary`.

**Changes to `quran_reader_screen.dart`:**

1. Add a new `GlobalKey _screenshotBoundaryKey`
2. Wrap the `QuranPageView` widget in a `RepaintBoundary(key: _screenshotBoundaryKey, ...)`
3. Before capture: hide UI overlays via `_uiVisibilityCubit.hide()`, wait one frame
4. Capture: `RenderRepaintBoundary.toImage(pixelRatio: 2.0)` → `ui.Image` → PNG bytes
5. After capture: restore UI visibility

### 4.2 Branded Screenshot Compositing

Using `dart:ui` Canvas (no external packages needed):

1. Draw the captured page image as background
2. Draw a semi-transparent bottom strip (64px height, app primary color at 80% opacity)
3. Draw Tilawa logo (loaded from assets), surah name, page number, "Shared via Tilawa" text
4. Encode to PNG via `image.toByteData(format: ui.ImageByteFormat.png)`
5. Save to temp file via `ShareFileManager`

```dart
@LazySingleton()
class ScreenshotService {
  Future<Uint8List> captureAndBrand({
    required GlobalKey boundaryKey,
    required String surahName,
    required int pageNumber,
    double pixelRatio = 2.0,
  });
}
```

### 4.3 Platform-Specific Screenshot Enhancement (Optional)

For **iOS**: Consider using a native MethodChannel to capture the view via `UIGraphicsImageRenderer` if the Flutter RepaintBoundary approach produces artifacts with the `SnapshotWidget` cache used in `PageContent`. This is a fallback only — test Flutter-side capture first.

---

## 5. Share Sheet Integration

### 5.1 Using share_plus (Already Installed)

```dart
await Share.shareXFiles(
  [XFile(filePath, mimeType: 'image/png')],  // or 'audio/mpeg'
  text: 'Surah Al-Fatiha, Page 1 — Shared via Tilawa',
  subject: 'Quran from Tilawa',
);
```

### 5.2 Platform Behavior

| Platform | Screenshot (PNG) | Audio Clip (MP3) |
|----------|-----------------|------------------|
| **Android** | `ACTION_SEND` chooser → works everywhere | `ACTION_SEND` chooser → WhatsApp (as file), Telegram, etc. |
| **iOS** | `UIActivityViewController` → all apps | Same → Messages, AirDrop, WhatsApp, etc. |
| **WhatsApp Status** | Directly supported (image) | Not supported (requires video) — shared as chat attachment instead |
| **TikTok** | Not directly supported via share sheet | Not supported — would need TikTok SDK (out of scope) |
| **Instagram Stories** | Possible via deep link (`com.instagram.sharedSticker`) | Not supported via share sheet |

**v1 scope:** Use the OS share sheet only. Platform-specific deep links (Instagram Stories, TikTok SDK) are deferred to v2.

---

## 6. Required Dependencies

### Phase 1 (No new dependencies)

All needed packages are already installed:
- `share_plus: ^12.0.1` — share sheet
- `dio: ^5.9.0` — HTTP downloads
- `path_provider: ^2.1.5` — temp directory
- `permission_handler: ^12.0.1` — runtime permissions (if needed)

### Phase 2 (Future — optional)

- `ffmpeg_kit_flutter_audio: ^6.0.3` — for full surah trimming + video generation (~8MB binary increase)
- No other new packages needed

---

## 7. Permissions & Platform Configuration

### No New Permissions Required

All existing permissions cover the sharing use case:
- **Android**: `INTERNET` (downloading verse audio), `WRITE_EXTERNAL_STORAGE` (saving temp files) — already present
- **iOS**: Photo library descriptions already present; `share_plus` uses `UIActivityViewController` which requires no additional entitlements

### FileProvider (Android)

`share_plus` on Android 7+ requires a `FileProvider` to share files. Verify that `AndroidManifest.xml` has the `<provider>` entry for `share_plus`. If missing, add:

```xml
<provider
    android:name="dev.fluttercommunity.plus.share.ShareFileProvider"
    android:authorities="${applicationId}.share_plus"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_provider_paths" />
</provider>
```

And create `android/app/src/main/res/xml/file_provider_paths.xml` if not present.

---

## 8. Edge Cases & Error Handling

| Scenario | Handling |
|----------|----------|
| **No internet during audio generation** | Check connectivity before starting. Show: "Internet required to generate audio clip." |
| **Verse download fails mid-clip** | Retry individual verse up to 3 times. On persistent failure, abort with message. Clean up partial files. |
| **Large verse range (>30 verses)** | Cap at 30 verses. Show toast: "Maximum 30 verses per clip." |
| **Reciter not in Quran.com mapping** | Show message: "Verse audio unavailable for this reciter. Using [default] instead." Or offer text-only share. |
| **Screenshot before page loads** | Guard with null check on render object. Show: "Please wait for the page to load." |
| **Low memory during screenshot** | Try `pixelRatio: 2.0` first; on OOM, retry with `1.0`. |
| **Disk full** | Catch `FileSystemException`, show: "Not enough storage space." |
| **User cancels mid-generation** | `ShareCubit` supports cancellation token. Clean up partial downloads/files. |
| **Share sheet dismissed without sharing** | Normal flow — clean up temp files. |
| **App backgrounded during generation** | Continue in background (audio download is async). Show local notification on completion if app is still backgrounded. |
| **SnapshotWidget interfering with capture** | The `PageContent` uses `SnapshotWidget` for scroll perf. `RepaintBoundary.toImage()` captures the raster cache, which is actually fine. If quality is insufficient, temporarily disable snapshotting before capture. |

---

## 9. Performance Considerations

### Audio Clip
- **Parallel downloads** with concurrency pool of 5 (not unlimited — avoids rate limiting)
- **Verse cache**: Persist downloaded verse files in app support directory for reuse; LRU eviction at 100MB
- **Isolate for concatenation**: For verse ranges >10, run file concatenation in `Isolate.run()` to avoid UI jank
- **Streaming file writes**: Use `RandomAccessFile` to write concatenated bytes without loading all files into memory

### Screenshot
- **Pixel ratio capped at 2.0**: Higher ratios are overkill for social media (platforms compress anyway). Keeps memory usage reasonable.
- **Post-frame capture**: Execute `toImage()` in `addPostFrameCallback` to avoid frame drops
- **Dispose `ui.Image`**: Call `.dispose()` immediately after encoding to bytes

### General
- **Temp file cleanup**: `ShareFileManager.cleanup()` runs on `ShareCubit.close()`, app resume, and a scheduled periodic sweep
- **No blocking the UI thread**: All I/O (download, write, encode) runs asynchronously or in isolates

---

## 10. Testing Scenarios

### Unit Tests
1. `AudioClipService`: Correct URL construction, parallel download orchestration, MP3 concatenation byte correctness, retry logic, max verse cap, progress reporting
2. `ScreenshotService`: PNG encoding from mock boundary, branding overlay positioning, error on null render object
3. `ShareFileManager`: Temp dir creation, unique naming, cleanup deletes all, handles missing dir
4. `ShareCubit`: State transitions (idle → configuring → generating → sharing → idle), cancel resets state, error resets after ack

### Widget Tests
1. `ShareOptionsSheet`: Renders both options, taps invoke correct callbacks
2. `ShareAudioConfigSheet`: Verse range picker validates bounds, reciter list populates, "Generate" disabled when invalid
3. `AyahOptionsSheet` (updated): New share sub-options appear, each invokes correct callback

### Integration Tests
1. End-to-end screenshot: Open reader → share → verify share sheet with PNG
2. End-to-end audio clip: Configure → generate → verify share sheet with MP3
3. Network failure: Mock Dio failure → verify error state and user message
4. Cancel mid-generation: Verify cleanup and state reset

### Manual QA Checklist
- [ ] Share screenshot to WhatsApp (chat + status)
- [ ] Share screenshot to Telegram, Facebook
- [ ] Share audio clip to WhatsApp (as audio file)
- [ ] Share from RTL pages (pages 1-2 special layout)
- [ ] Share from landscape orientation
- [ ] Cancel mid-audio-generation
- [ ] Share with no internet
- [ ] Share 30 verses (boundary), attempt 31 (should be rejected)
- [ ] Dark mode screenshot renders correctly
- [ ] Reciter not in Quran.com mapping — fallback behavior
- [ ] Repeated shares reuse cached verse files (verify no re-download)

---

## 11. Risks & Limitations

### Known Limitations (v1)
1. **Reciter coverage**: Quran.com verse API covers ~30-40 popular reciters. Reciters outside this set will fall back to a default reciter with a notification.
2. **No video generation**: WhatsApp Status and TikTok require video. Audio-only MP3 can be sent as a chat attachment but not posted to Status/Stories. Video generation (audio + page image) requires FFmpeg and is deferred to v2.
3. **MP3 concatenation gaps**: Simple byte concatenation may produce ~20ms gaps at frame boundaries. Acceptable for sharing, not broadcast quality.
4. **Online-only audio clips**: Verse-level audio requires a network connection. Full offline clips would need locally downloaded surah files + verse timing + FFmpeg (v2).
5. **No direct Instagram Stories / TikTok posting**: Uses the OS share sheet, which may not expose all platform-specific features.

### Risks
1. **Quran.com API rate limiting**: Mitigated by concurrency cap (5) and verse caching
2. **Quran.com API changes**: URL patterns encapsulated in one service method for easy updates
3. **App size**: Zero new native dependencies in v1 → no size impact. FFmpeg in v2 adds ~8MB.

---

## 12. Implementation Phases

### Phase 1 — Screenshot Sharing (2-3 days)
1. Create `features/share/` folder structure (all layers)
2. Implement `ScreenshotService` + `ShareFileManager`
3. Implement `ShareCubit` with screenshot flow
4. Add `RepaintBoundary` wrapper in `quran_reader_screen.dart`
5. Create `ShareOptionsSheet` widget
6. Wire share button into `_PageNavigationBar`
7. Add localization keys (AR + EN)
8. Verify `FileProvider` setup on Android

### Phase 2 — Audio Clip Sharing (3-4 days)
1. Create `reciter_audio_mapping.dart` (mp3quran → Quran.com mapping)
2. Implement `AudioClipService` (download + concatenate)
3. Create `ShareAudioConfigSheet` (verse range picker + reciter selector)
4. Extend `ShareCubit` for audio clip flow
5. Add verse range validation + progress reporting
6. Implement verse audio caching

### Phase 3 — Polish & Integration (2 days)
1. Enhance `AyahOptionsSheet` with share sub-menu
2. Branded screenshot watermark with Tilawa logo
3. Error handling and edge case coverage
4. Unit + widget tests
5. Manual QA on both platforms

### Phase 4 (Future) — Video Generation & Backend
1. Add `ffmpeg_kit_flutter_audio` for video generation (audio + page image → MP4)
2. Full surah trimming with verse timing data
3. Optional backend clip service for server-side processing
4. Instagram Stories deep link, TikTok SDK integration

---

## 13. Critical Files to Modify

| File | Change |
|------|--------|
| [quran_reader_screen.dart](apps/tilawa/lib/features/quran_reader/presentation/screens/quran_reader_screen.dart) | Add `RepaintBoundary`, share button in bottom bar, provide `ShareCubit` |
| [ayah_options_sheet.dart](apps/tilawa/lib/features/quran_reader/presentation/widgets/ayah_options_sheet.dart) | Enhance `onShare` to show sub-menu (text / screenshot / audio clip) |
| [app_providers.dart](apps/tilawa/lib/core/providers/app_providers.dart) | Register `ShareCubit` |
| [injection.dart](apps/tilawa/lib/core/di/injection.dart) | DI picks up new `@Injectable` services automatically via build_runner |
| [app_en.arb](apps/tilawa/lib/l10n/app_en.arb) + [app_ar.arb](apps/tilawa/lib/l10n/app_ar.arb) | Add localization keys |
| [AndroidManifest.xml](apps/tilawa/android/app/src/main/AndroidManifest.xml) | Verify/add `FileProvider` for `share_plus` |

## 14. Reusable Existing Code

| What | Where | Reuse How |
|------|-------|-----------|
| `share_plus` package | Already in pubspec | `Share.shareXFiles()` for both image and audio |
| `Dio` HTTP client | `external_dependencies_module.dart` | Inject for verse audio downloads |
| `RecitersRepository` | `features/reciters/` | Populate reciter selector dropdown |
| `QuranPageAudioController` | `features/quran_reader/presentation/controllers/` | Reference for `qurancdn.com` URL pattern |
| `ShareFileManager` pattern | `features/downloads/utils/download_path_utils.dart` | Reuse path sanitization logic |
| `UiVisibilityCubit` | `core/presentation/cubit/` | Hide overlays before screenshot capture |
| `getPageData()`, `getSurahNameArabic()` | `packages/quran_qcf/` | Page metadata for branding overlay |
