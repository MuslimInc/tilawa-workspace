# Production release status

**Target:** Google Play `1.0.3+28` (version code **28**) via Shorebird full release.  
**Previous live build:** `1.0.2` (version code **27**).

## Blockers cleared (2026-05-20)

| Area | Status |
|------|--------|
| Client Firestore seeding on startup | Read-only prefetch; `subscriptionServiceEnabled` defaults false |
| Downloads error UI crash | Uses `SizedBox.expand` + `TilawaIllustratedState` |
| Invalid surah from push payload | Validated in `FcmNotificationHandlerService` (1–114) |
| Qibla stream lifecycle | `StopQiblaStream` on dispose |
| `dart analyze` (tilawa) | Clean |
| Main screen startup tests | Fixed (GoRouter + `MainScreenCubit` harness) |

## Pre-upload checklist

1. Bump committed: `apps/tilawa/pubspec.yaml` → `1.0.3+28`
2. Tag: `git tag v1.0.3+28`
3. Quality: `melos run analyze` and `cd apps/tilawa && flutter test`
4. Kotlin: `cd apps/tilawa/android && ./gradlew test`
5. Build: `cd apps/tilawa && shorebird release android --flutter-version=3.44.0`
6. Upload `build/app/outputs/bundle/release/app-release.aab` to Internal testing
7. Staged rollout after pre-launch report

See also: [google_play_release_checklist.md](google_play_release_checklist.md), [shorebird.md](shorebird.md).
