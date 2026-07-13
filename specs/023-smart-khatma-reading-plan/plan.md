# Implementation Plan: Smart Khatma (Al-Khatmah MVP)

**Branch**: `feature/khatmah` | **Date**: 2026-07-13 | **Spec**: [spec.md](spec.md)

## Summary

Ship one local active Khatma with explicit Surah/Ayah or Mushaf page boundaries,
duration or target-date scheduling, preview-before-save, frozen daily
assignments, explicit progress confirmation, edit/delete, and calm daily/full
completion states. Today Plan and the Android Wird widget remain default-off.

## Technical Context

**App**: Flutter, `flutter_bloc`, `get_it`, GoRouter typed routes, SharedPreferences v2 persistence.  
**Quran metadata**: `quran_qcf` (`getPageNumber`, `getVerseCount`).  
**UI**: Tilawa UI Kit tokens, `context.l10n`, RTL/LTR, dynamic text.  
**Testing**: `package:test` + `package:checks`; widget tests with l10n + theme.

## Architecture

| Layer | Responsibility |
|---|---|
| `domain/khatma_plan_boundaries.dart` | Surah/Ayah → page resolution, range validation, target-date → duration |
| `domain/entities/khatma_plan.dart` | Plan invariant, daily assignment, resume page, completion |
| `domain/usecases/*` | Preview/confirm create, update duration, progress, extend, reset |
| `data/datasources/khatma_plan_local_datasource.dart` | `smart_khatma.active_plan.v2` JSON |
| `presentation/screens/smart_khatma_hub_screen.dart` | Seven canonical hub states + creation |
| `presentation/widgets/smart_khatma_plan_actions.dart` | Reader entry, Save Progress sheet, edit/delete |
| `presentation/widgets/smart_khatma_home_entry_card.dart` | Contextual Home entry |

## Canonical Flow (shipped)

```text
Home card → Hub
  No plan → boundary mode (Surah/Ayah or Page) → duration OR target date
          → preview → confirm → persist
  Active  → today range + Start/Resume → KhatmaReaderRoute(initialPage)
          → Save Progress confirmation → derived completion
  Edit    → duration/target-date sheet → preview → save (progress kept)
  Delete  → confirmed reset
  Complete → Start another / Return to Quran
  Error   → Retry / Reset (raw v2 preserved)
```

## Release Flags

| Flag | Default | Notes |
|---|---|---|
| `TILAWA_LAUNCH_SMART_KHATMA_ENABLED` | `true` | Home card + hub |
| `TILAWA_LAUNCH_TODAY_PLAN_ENABLED` | `false` | Khatma-backed task reconciliation deferred |
| `TILAWA_LAUNCH_WIRD_WIDGET_ENABLED` | `false` | Native widget deferred |

## Verification

```sh
melos run fix:format
cd apps/tilawa && dart analyze lib/features/smart_khatma/
flutter test test/features/smart_khatma/
```

## Remaining Pre-Store Gates

1. Production App Bundle build on CI or release lane.
2. Physical-device smoke: create → read → save → next day rollover.
3. Optional: full seven-state widget matrix at 1.4 text scale in Arabic.
