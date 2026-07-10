# Implementation Plan: Islamic Home Screen Widget Suite (v1)

**Branch**: `041-islamic-widget-suite` | **Date**: 2026-07-11 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/041-islamic-widget-suite/spec.md`

## Summary

Complete the Android widget suite around the already-delivered prayer-times widget: add QCF Ayah, morning/evening Athkar, and Hijri date providers; add QCF share cards; and retain Flutter as the source of truth for religious content and settings. Flutter prepares versioned, privacy-safe snapshots and bounded QCF image artifacts. Native Android providers persist and render those snapshots without starting Flutter, schedule only boundary refreshes, and deep-link into typed GoRouter destinations.

## Technical Context

**Language/Version**: Dart 3.12.2 / Flutter workspace; Kotlin 2.2.20 targeting JVM 17

**Primary Dependencies**: flutter_bloc, get_it/injectable, go_router, shared_preferences, firebase_analytics, share_plus, quran_qcf, Tilawa UI Kit; Android AppWidgetProvider, RemoteViews, AlarmManager, WorkManager

**Storage**: Existing app preferences plus app-private Android SharedPreferences for versioned widget snapshots; app cache/files for bounded PNG artifacts

**Testing**: flutter_test, package:checks, JUnit 4, kotlin-test, MockK, Robolectric, Android WorkManager test support; manual launcher/device-matrix QA

**Target Platform**: Android API 24–36 home-screen widgets; Arabic and English; Egypt-first OEM matrix

**Project Type**: Flutter mobile application with native Android widget hosts

**Performance Goals**: Widget render completes within 10 seconds of placement/reboot; native updates avoid launching Flutter; QCF artwork generation occurs off hot UI paths; no per-second background wakeups; no visible clipped glyphs at supported sizes

**Constraints**: Offline-first religious content; minute-level prayer countdown; OEM background restrictions; RemoteViews limitations; multiple widget instances; RTL/LTR and 200% text scaling; bounded persistent images; privacy-safe analytics

**Scale/Scope**: Four widget types, at least two size classes and light/dark/auto appearance per type, roughly 90 curated daily Ayat, one-to-five-verse share cards, Android only in v1

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Design response | Gate |
|---|---|---|
| I. Clean Architecture | Widget selection, Hijri adjustment, Athkar period logic, and share-card validation live in domain/use-case APIs. Android owns host lifecycle/rendering only and consumes versioned DTO snapshots. | PASS |
| II. BLoC & GoRouter | In-app configuration/preview flows use Cubit/BLoC; widget taps resolve through typed GoRouter routes. Native providers do not contain app business rules. | PASS |
| III. UI Kit & responsive design | Flutter previews/cards use UI Kit tokens. Native resources mirror approved tokens and provide explicit compact/expanded, RTL/LTR, and accessibility states. | PASS |
| IV. Performance-first | QCF raster work is precomputed and cached off hot paths; providers render from local snapshots; refreshes occur at content boundaries with OS backstops. Profiling and bitmap budgets are mandatory. | PASS |
| V. Observability | Structured events cover add/remove/tap/render failure/staleness/share preview/share completion without Quran content or precise location. | PASS |
| VI. Safe delivery | Stories remain independently releasable behind provider registration and curated content readiness. Existing P1 behavior is preserved and regression-tested. | PASS |

**Post-design re-check**: PASS. The data model keeps business decisions in Flutter domain/application layers, contracts constrain the native boundary to display-ready snapshots, and the quickstart includes architecture, performance, accessibility, privacy, and restart verification. No constitutional waiver is required.

## Project Structure

### Documentation (this feature)

```text
specs/041-islamic-widget-suite/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── widget-bridge.md
└── tasks.md
```

### Source Code (repository root)

```text
apps/tilawa/
├── lib/
│   ├── features/islamic_widgets/
│   │   ├── app/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── features/prayer_times/       # existing P1 snapshot producer
│   ├── features/quran_reader/        # Ayah selection/deep link source
│   ├── features/athkar/              # Athkar content and flow
│   ├── features/share/               # share composer integration
│   └── router/                       # typed widget destinations
├── android/app/src/main/
│   ├── kotlin/com/tilawa/app/
│   │   ├── prayer/widget/            # existing P1 provider/store/logic
│   │   └── widget/                   # shared host bridge + new providers
│   └── res/{layout,drawable,values,values-ar,xml}/
├── test/features/islamic_widgets/
└── android/app/src/test/kotlin/com/tilawa/app/widget/

packages/quran_qcf/
├── lib/src/presentation/             # reusable bounded QCF raster service
└── test/
```

**Structure Decision**: Keep feature-owned religious data in the existing Flutter features and add one orchestration feature for widget snapshot creation/configuration. Extend the existing native provider pattern for launcher lifecycle. Put only reusable QCF raster capability in `quran_qcf`; do not move widget-specific policy into that package.

## Delivery Sequence

1. **Foundation/P1 hardening**: formalize the versioned bridge, shared store, instance preferences, analytics, deep links, staleness, and lifecycle test harness around the existing prayer widget.
2. **P2 Ayah widget**: curated deterministic selection, bounded QCF raster output, compact/expanded providers, offline cache, fallback state, and Mushaf deep link.
3. **P3 Athkar widget**: display-ready period snapshots, persisted per-instance progress, advance action, period reset, and Athkar deep link.
4. **P4 Hijri widget**: shared ±2-day setting, local-midnight rollover, compact/expanded layouts, and app-wide consistency tests.
5. **P5 share cards**: one-to-five consecutive Ayah validation, three curated backgrounds, preview/cancel/share flow, attribution, temporary-file cleanup, and analytics.
6. **Release gates**: Arabic/English and RTL/LTR QA, 200% scaling, API 24/target API, Xiaomi/Redmi and Samsung reboot/Doze tests, QCF corpus visual review, battery/profile evidence, staged rollout instrumentation.

## Complexity Tracking

No constitution violations require justification.
