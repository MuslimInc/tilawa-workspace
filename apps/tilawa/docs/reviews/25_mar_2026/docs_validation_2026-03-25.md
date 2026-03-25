# Documentation Validation - 2026-03-25

Scope: validate all review documents in `apps/tilawa/docs/reviews/25_mar_2026` against the current codebase.

Documents checked:
- `audit_report.md`
- `google_play_pre_release_audit_2026-03-25.md`
- `quizzical-humming-plum.md`

## Verdict

- `google_play_pre_release_audit_2026-03-25.md`: Valid and aligned with the current codebase. This is the only document in the folder that is release-safe as a source of truth.
- `audit_report.md`: Partially validated. It contains some real observations, but several headline items are stale, target unused code, or overstate severity.
- `quizzical-humming-plum.md`: Partially validated. It mixes valid code smells with speculative or incorrect release-risk claims.

## Per-Document Validation

### 1. `google_play_pre_release_audit_2026-03-25.md`

Status: Valid

Notes:
- The core findings match the current codebase:
  - Firestore seeding from startup in `lib/core/bootstrap/app_startup.dart` and `lib/core/services/firebase_initialization_service.dart`
  - Downloads error-state crash path in `lib/features/downloads/presentation/screens/downloads_screen.dart`
  - Invalid notification deep-link crash path in `lib/features/notifications/presentation/services/fcm_notification_handler_service.dart` and `lib/features/quran_reader/presentation/screens/quran_reader_screen.dart`
  - Qibla lifecycle issue across `lib/core/providers/app_providers.dart`, `lib/screens/main_screen.dart`, and `lib/features/qibla`
  - Startup delay from `warmUpSplashWordmark()`
  - Large concurrent font registration in `packages/quran/lib/src/services/quran_font_service.dart`
  - Dead router test file causing `flutter test` failure
- This document is currently the best canonical release audit in the folder.

### 2. `audit_report.md`

Status: Partially validated

Validated points:
- The startup-delay observation is real:
  - `lib/core/bootstrap/app_startup.dart:193-197`
  - `lib/core/bootstrap/app_startup.dart:265-294`
- The audio queue reset observation is real:
  - `lib/shared/audio/audio_player_handler_impl.dart:452-456`
  - `lib/shared/audio/audio_player_handler_impl.dart:352-417`
- The page-slider recomputation concern is real:
  - `lib/features/quran_reader/presentation/screens/quran_reader_screen.dart:348-401`
  - `lib/features/quran_reader/presentation/screens/quran_reader_screen.dart:490-508`
- The swallowed stream-error observation in `AudioPlayerBloc` is real:
  - `lib/features/audio_player/presentation/bloc/audio_player_bloc.dart:142-199`

Not validated / stale / overstated:
- The top "Critical" item about `SurahTextSection` rebuilding on word playback targets `lib/features/quran_reader/presentation/widgets/quran_page_widget.dart`, but that widget is not used by the active Quran reader path.
  - The current reader uses `QuranPageView` from `lib/features/quran_reader/presentation/screens/quran_reader_screen.dart:240-264`.
  - Repo search shows `QuranPageWidget` is only referenced inside its own file.
- The low-severity gesture-recognizer issue has the same problem: it refers to unused `quran_page_widget.dart`, so it is not a current production-path finding.
- The "fragile page navigation sync" concern is directionally plausible, but the cited line anchors are stale and the issue is described too strongly for the evidence available.
- The "offline reliability" claim about `RecitersRepositoryImpl` hanging on a corrupted local asset is not supported by the repository logic:
  - `_getRecitersData()` falls back from local to remote in `lib/features/reciters/data/repositories/reciters_repository_impl.dart:101-107`
  - public methods wrap failures into `Left(ServerFailure(...))` in `lib/features/reciters/data/repositories/reciters_repository_impl.dart:111-120`

Conclusion for this doc:
- Keep only the validated items.
- Remove or downgrade the `quran_page_widget.dart` findings unless that widget is reintroduced into the live reader flow.

### 3. `quizzical-humming-plum.md`

Status: Partially validated

Validated points:
- `QuranFontService` does load fonts concurrently:
  - `packages/quran/lib/src/services/quran_font_service.dart:121-163`
- `QuranFontService` does create `Dio()` with no explicit timeouts:
  - `packages/quran/lib/src/services/quran_font_service.dart:10`
- The shared Dio client does accept any status `< 500`:
  - `lib/core/di/external_dependencies_module.dart:64-77`
- `HydratedStorage.build()` failure is swallowed with only a debug log:
  - `lib/core/bootstrap/app_startup.dart:398-410`
- `_specialLinesCache` and static Quran page caches exist:
  - `packages/quran/lib/src/page_content.dart:72-77`
  - `packages/quran/lib/src/page_content.dart:485-491`
- `PageContent` uses `AutomaticKeepAliveClientMixin`:
  - `packages/quran/lib/src/page_content.dart:69-92`
- `_SurahHeaderBanner` does hardcode black text:
  - `packages/quran/lib/src/page_content.dart:576-584`
- `SplashCubit` does silently swallow all exceptions:
  - `lib/features/splash/presentation/cubit/splash_cubit.dart:51-54`
- `DevicePreview(enabled: false)` still wraps the root app:
  - `lib/core/bootstrap/app_startup.dart:258-262`
- The audio notification channel ID is still the example value:
  - `lib/core/bootstrap/app_startup.dart:554-560`
- `BottomPlayerWidget` does call `setState()` from animation listeners every frame:
  - `lib/shared/widgets/bottom_player_widget.dart:68-84`

Incorrect or not validated:
- "No retry/recovery in QuranFontLoaderBloc error state" is false.
  - The error UI exposes a retry button in `lib/features/quran_reader/presentation/screens/quran_font_loader_screen.dart:69-74`.
- "Firebase init has no timeout and can block startup indefinitely on network issues" is not validated.
  - `Firebase.initializeApp()` here uses bundled app options; this document presents a network-hang theory without code evidence.
- "No Dio interceptors for auth token injection" is unproven as a release issue.
  - The code does not show that the affected endpoints require bearer auth.
- "AudioService.init() race will break audio if user taps quickly after launch" is plausible but unproven from the current code alone.
- The font-concurrency issue is real, but the document overstates it as a confirmed OOM crash risk without device evidence.
- `_specialLinesCache` is real, but calling it a "memory leak" is too strong. It is a bounded cache, not unbounded growth.

Severity inflation:
- Several items marked `CRITICAL` or `HIGH` should be downgraded to `MEDIUM` or `LOW` unless backed by profiling or a reproducible crash.

## Recommended Action

Use `google_play_pre_release_audit_2026-03-25.md` as the authoritative release-review document.

For the other two files:
- `audit_report.md`: rewrite or archive
- `quizzical-humming-plum.md`: rewrite or archive

If these documents need to stay in the repo, add a short header marking them as draft / partially validated so they are not mistaken for release-ready audit outputs.
