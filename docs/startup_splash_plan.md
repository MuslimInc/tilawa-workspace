# Startup & splash — plan (Noon / Amazon style)

**Priority:** P0 (see [`TODO.md`](TODO.md))  
**Goal:** One calm branded splash until the app is **ready** for the first
meaningful screen — no “empty home” then widgets popping in over 5+ seconds.

---

## What large apps do (pattern)

| Principle | Noon / Amazon–style behavior |
|-----------|------------------------------|
| **Single gate** | Branded splash stays until a defined **ready** condition. |
| **Ready ≠ all work done** | Ship first screen when **shell + route decision + first tab skeleton** are safe; defer heavy work with inline loading. |
| **No double splash confusion** | Native + Flutter should feel like **one** continuous splash. |
| **Time cap** | Max splash duration (e.g. 8–12s) then proceed with degraded mode + retry UI. |
| **Measure** | Cold-start timeline in profile/release; optimize P95, not debug JIT. |

---

## Tilawa today (two splashes, early navigation)

```mermaid
sequenceDiagram
  participant Native
  participant BootGate as _BootGate launch splash
  participant Critical as runCriticalInit
  participant App as TilawaApp
  participant Splash as /splash SplashScreen
  participant Home as MainScreen shell

  Native->>BootGate: runApp
  BootGate->>BootGate: postFrame critical init
  Critical->>Critical: Firebase, Hydrated, DI, router, chrome
  BootGate->>App: _ready = true
  App->>Splash: initial route
  Splash->>Splash: auth / onboarding / notification routing only
  Splash->>Home: go home (fast)
  Note over Home: 260ms shell, 1200ms tab, 5200ms UI warmup, 800ms audio
```

**Files**

| Layer | Role |
|-------|------|
| [`app_bootstrapper_phases.dart`](../apps/tilawa/lib/core/bootstrap/app_bootstrapper_phases.dart) | `runApp` + post-frame `runCriticalInit` |
| [`app_startup_widgets.dart`](../apps/tilawa/lib/core/bootstrap/app_startup_widgets.dart) | `_BootGate` / `_LaunchSplash` |
| [`app_startup_tasks.dart`](../apps/tilawa/lib/core/bootstrap/app_startup_tasks.dart) | Critical vs `nonCriticalStartupDelay` (3.2s) background |
| [`splash_bloc.dart`](../apps/tilawa/lib/features/splash/presentation/bloc/splash_bloc.dart) | Route + shell prep via [AppStartupReadiness](../apps/tilawa/lib/core/bootstrap/app_startup_readiness.dart) |
| [`main_screen_cubit.dart`](../apps/tilawa/lib/screens/cubit/main_screen_cubit.dart) | Deferred shell/tab/audio timers after home visible |

**Gap:** User leaves splash while **MainScreen** is still staging work (up to ~5.2s UI warmup). That feels unlike a “ready” retail app.

---

## Target architecture

### 1. Define `AppStartupReadiness` (explicit contract)

One injectable coordinator (or extend `AppStartupTasks`) exposes:

```dart
enum StartupPhase { bootGate, routing, shellPrep, interactive }

class AppStartupReadiness {
  Future<void> get ready;           // completes when gate opens
  Stream<StartupPhase> get phases;  // optional progress for splash subtitle
  bool get timedOut;                // proceeded after cap
}
```

**`ready` must include (minimum for `HomeRoute`):**

- [x] Today’s **critical init** (Firebase, Hydrated, DI, router, notification launch state, SystemChrome)
- [ ] **Splash routing** (onboarding / auth / cold-start notification decision)
- [ ] **Shell prep** (move from `MainScreenCubit` delays that block first paint of home tab):
  - `isShellActivated`
  - `isInitialTabMounted` (or first tab **skeleton** built, not full data)
- [ ] **Optional:** Google sign-in prepare when destination is login (already on splash today)

**Still deferred after `ready` (background or post-transition):**

- Hive phase 0, credential manager, analytics (unless needed for first screen)
- Notification channels, athkar/prayer schedulers, downloads DB, audio service init
- Quran asset prefetch, Crashlytics, prayer watchdog
- `isStartupUiWarm` heavy SVG/icons (show placeholders until warm)

**Hard cap:** `maxSplashDuration` (suggest **10s** release, **15s** debug). On timeout: log + navigate with banner “Still loading…” on home.

### 2. Unify splash UI

- Keep **one** visual: `_LaunchSplash` wordmark (match native Android 12 splash).
- **Option A (smaller diff):** Extend `_BootGate` until `AppStartupReadiness.ready`, then go straight to resolved route (skip duplicate `/splash` when not needed for auth spinner).
- **Option B:** Keep `/splash` but drive it from `AppStartupReadiness` (splash screen = progress + same artwork).

Prefer **Option A** for Noon-like continuity; keep `/splash` route for deep-link tests and notification-only flows if required.

### 3. Move work from `MainScreenCubit` into splash phase

| Current delay | Action |
|---------------|--------|
| 260ms `isShellActivated` | Run during splash; home mounts with shell already active |
| 1200ms `isInitialTabMounted` | Pre-build first tab widget tree (or lightweight skeleton) before `go(home)` |
| 5200ms `isStartupUiWarm` | Stay post-ready; use skeletons on Reciters/home |
| 800ms audio binding | Stay post-ready unless player visible on frame 1 |

### 4. Parallelize safe critical work

Already parallel: Firebase + Hydrated, notification + SystemChrome.

**Candidates to pull into critical (measure first):**

- `initializeCredentialManager` — if login is common cold path
- Minimal **SharedPreferences / settings** read for theme + locale before first frame

**Do not pull into critical without profiling:**

- Full `runPhase3NotificationsAndAudio`
- Quran image cache prefetch

### 5. Observability

- Extend [`LaunchTimeline`](../apps/tilawa/lib/core/bootstrap/launch_timeline.dart) with phases: `ready_gate`, `route_resolved`, `shell_prep_done`.
- Log `ColdStartNavigationMetrics` when gate opens vs when first home frame is **stable** (existing perf logs in `MainScreenCubit`).
- Add widget test: splash does not navigate until `ready` future completes.

---

## Implementation phases

### Phase 1 — Readiness gate (MVP) `P0`

1. Add `AppStartupReadiness` + unit tests (fake slow deps).
2. `SplashBloc` + `SplashStarted` awaits `AppStartupReadiness` before navigate.
3. Move shell activation + initial tab mount prep into readiness (extract from `MainScreenCubit`).
4. Add 10s timeout + analytics event `startup_ready_timeout`.
5. Profile cold start on mid-range Android (`flutter run --profile`).

**Exit criteria:** Home opens without 1.2s “blank shell” delay; no regression on notification cold start.

### Phase 2 — Single splash surface `P1`

1. Merge `_BootGate` + `/splash` visuals; document in AGENTS.md.
2. Optional subtle progress (indeterminate bar) after 2s on splash.

### Phase 3 — Background budget `P2`

1. Re-tune `nonCriticalStartupDelay` vs readiness (may reduce to 0 once splash holds longer).
2. Per-feature “lazy init on first visit” registry (Downloads, Share, etc.).

---

## Risks

| Risk | Mitigation |
|------|------------|
| Longer splash on slow devices | Hard cap + timeout path; show % or “Preparing…” after 2s |
| Notification cold start | Keep notification routing in readiness; test FCM/local launch |
| Hot reload / tests | `AppStartupReadiness.resetForTesting()` like existing startup test hooks |
| Shorebird | Dart-only phases 1–2 are patch-friendly |

---

## References in repo

- Boot gate comment: first-frame vs init tradeoff in
  [`app_startup_widgets.dart`](../apps/tilawa/lib/core/bootstrap/app_startup_widgets.dart)
- Launch config flags: [`app_launch_config.dart`](../apps/tilawa/lib/core/bootstrap/app_launch_config.dart)
- Pre-release audit (startup risk): [`google_play_pre_release_audit_2026-03-25.md`](../apps/tilawa/docs/reviews/25_mar_2026/google_play_pre_release_audit_2026-03-25.md)

---

*Created: 2026-05-23*
