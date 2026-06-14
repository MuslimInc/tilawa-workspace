# Frozen share / FFmpeg implementation

Native FFmpeg (`ffmpeg_kit_flutter_new`) is **not** linked in production builds
to keep the Play Store AAB smaller. The full Dart implementation is preserved
here so it can be restored without rewriting feature logic.

## What is frozen

| Snapshot | Original path |
|----------|----------------|
| `lib/data/services/video_service.dart` | `lib/features/share/data/services/` |
| `lib/data/services/audio_clip_service.dart` | Direct `FFmpegKit` usage (pre-port) |
| `lib/data/ffmpeg/ffmpeg_kit_runner.dart` | Production plugin adapter |
| `lib/presentation/widgets/share_preview_widgets.dart` | `video_player` preview |
| `lib/presentation/widgets/share_audio_config_sheet.dart` | `chewie` reel review |
| `test/data/services/video_service_test.dart` | Unit tests |
| `test/data/services/fakes/fake_ffmpeg_runner.dart` | Test fake |

Active app code under `lib/features/share/` still contains [VideoService],
[FFmpegRunner], and audio-clip logic wired to [DisabledFfmpegRunner] until
FFmpeg is turned back on.

## Re-enable checklist

1. Add to `apps/tilawa/pubspec.yaml`:
   - `ffmpeg_kit_flutter_new: ^4.1.0`
   - `video_player: ^2.11.1`
   - `chewie: ^1.13.0`
2. Restore Android Gradle ext in `android/build.gradle`:
   ```gradle
   ext { ffmpegKitPackage = "full-gpl" }
   ```
3. Copy `frozen/share/lib/data/ffmpeg/ffmpeg_kit_runner.dart` to
   `lib/features/share/data/ffmpeg/ffmpeg_kit_runner.dart`.
4. Change injectable binding: remove `@LazySingleton(as: FFmpegRunner)` from
   `disabled_ffmpeg_runner.dart` (or delete it) and use `FfmpegKitRunner`.
5. Set `kShareFfmpegNativeEnabled` / `SHARE_FFMPEG_ENABLED=true` in
   `share_feature_flags.dart` or via `--dart-define`.
6. Merge any presentation widget changes from this folder if preview UI was
   simplified while frozen.
7. `melos run gen` (or `dart run build_runner build --workspace` from repo root)
8. Full Shorebird **release** (not patch) — native binaries changed.
