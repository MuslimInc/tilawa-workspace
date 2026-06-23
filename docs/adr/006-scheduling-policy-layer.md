# ADR-006: Quran Sessions Scheduling Policy Layer (Phased Rollout)

**Status:** Accepted  
**Date:** 2026-06-22  
**Deciders:** Engineering team

---

## Context

Teachers think in **calendar weeks** (“this week”, “next week”, “review Friday
before Saturday”). The booking engine thinks in a **recurring weekly template**
(`WeeklySchedule` rules + overrides → `SlotGenerator`).

Without an explicit policy layer, week-scoped UX (dashboard sections, Friday
reminders) would be bolted onto presentation code and drift from bookability
rules. We also need a safe path to a future **published-week** model without
rewriting slot generation twice.

---

## Decision

Introduce a **scheduling policy layer** on top of the existing recurring
`SlotGenerator` pipeline. Admin-owned `MarketSchedulingConfig` is resolved per
teacher market; `SchedulingPolicyResolver` maps config into presentation gates
and analytics context. Bookability stays on recurring generation until Phase 3
data supports a change.

### Phased rollout

| Phase | Scope | Bookability |
|-------|--------|-------------|
| **1 (shipped)** | Week-scoped teacher dashboard, Friday review banner, baseline analytics | `SchedulingMode.recurring` only — locked |
| **2 (this ADR)** | Complete learn metrics, persistent banner dismiss, ops playbook | No change — still recurring |
| **3 (conditional)** | `PublishedWeekAvailability`, hybrid / weekly_publish modes | Only if Phase 2 go/no-go passes |

Phase 2 deliberately does **not** add `PublishedWeekAvailability`, publish flows,
or hybrid/weekly_publish bookability.

---

## Architecture

### Firestore config paths

Global defaults:

```
quran_session_platform_config/global
  └── scheduling: { scheduling_mode, week_start_day, ... }
```

Per-market overrides:

```
quran_session_market_configs/{countryCode}
  └── scheduling: { ... partial override ... }
```

Host implementation:
`apps/tilawa/lib/features/quran_sessions/data/firebase/firestore_market_scheduling_config_data_source.dart`

DTO → domain mapping:
`packages/quran_sessions/lib/src/data/mappers/market_scheduling_config_mapper.dart`

### Resolver contract

`SchedulingPolicyResolver` (`packages/quran_sessions/lib/src/domain/services/scheduling_policy_resolver.dart`):

- `resolve(global, marketOverride)` — merge admin config
- `effectiveBookabilityMode(config)` — Phase 1–2 always `recurring`
- `partitionBookableSlots(...)` — this week / next week buckets via `WeekCalendar`
- `evaluateFridayBanner(...)` — Friday + reminder hour + empty next week + not dismissed

`WeekCalendar` (`packages/quran_sessions/lib/src/domain/services/week_calendar.dart`)
owns week keys (`weekKey`), Friday detection, and slot partitioning.

### Fragmentation guards

- **Single bookability path:** `GetTeacherAvailabilityUseCase` + `SlotGenerator`
  unchanged in Phase 1–2.
- **Mode enum reserved:** `SchedulingMode.weeklyPublish` / `hybrid` exist for
  analytics and future wiring; resolver does not branch bookability on them yet.
- **Teacher vs admin policy:** `SchedulingPolicy` on `WeeklySchedule` (min notice,
  horizon) remains per-teacher; `MarketSchedulingConfig` is admin-only.
- **Dismiss scope:** `FridayReviewReminderStore` keys by
  `teacherId` + `nextWeekKey` so dismiss resets each week.

### Analytics boundary

Host wires `QuranSessionsSchedulingAnalyticsCallbacks`
(`packages/quran_sessions/lib/src/presentation/config/quran_sessions_scheduling_analytics_callbacks.dart`)
via `apps/tilawa/lib/features/quran_sessions/presentation/quran_sessions_scheduling_analytics.dart`.

Phase 2 events: `weekly_template_saved`, `booking_lost_due_to_no_availability`.

### Persistent Friday dismiss (Phase 2)

- Interface: `FridayReviewReminderStore`
- Production: `SharedPreferencesFridayReviewReminderStore` (Firebase DI)
- MVP / tests: `InMemoryFridayReviewReminderStore`

Key format:
`quran_sessions.friday_review_dismiss.{teacherId}.{nextWeekKey}` → until epoch ms.

---

## Key code references

| Concern | Location |
|---------|----------|
| Domain config | `packages/quran_sessions/lib/src/domain/entities/market_scheduling_config.dart` |
| Use case | `packages/quran_sessions/lib/src/domain/usecases/get_market_scheduling_config_usecase.dart` |
| Teacher dashboard | `packages/quran_sessions/lib/src/presentation/blocs/teacher_dashboard/teacher_dashboard_bloc.dart` |
| Friday banner UI | `packages/quran_sessions/lib/src/presentation/widgets/friday_review_reminder_banner.dart` |
| Weekly template editor | `packages/quran_sessions/lib/src/presentation/screens/weekly_availability_screen.dart` |
| Booking empty-slot signal | `packages/quran_sessions/lib/src/presentation/blocs/booking/booking_bloc.dart` |
| DI (package) | `packages/quran_sessions/lib/src/di/quran_sessions_module.dart` |
| DI (Firebase host) | `apps/tilawa/lib/features/quran_sessions/di/quran_sessions_firebase_module.dart` |

---

## Consequences

**Positive**

- Week-scoped UX without forking slot generation.
- Phase 2 learn window produces quantitative go/no-go for Phase 3.
- Market-level kill switch via Firestore `scheduling` overrides.

**Negative / deferred**

- Phase 2 does not reduce student booking failures — only measures them.
- `weekly_publish` / `hybrid` modes require Phase 3 entities and migration work.

---

## Related documents

- Phase 2 learn playbook: [`docs/quran_sessions_scheduling_phase2_learn.md`](../quran_sessions_scheduling_phase2_learn.md)
- Backend-agnostic sessions: [ADR-002](002-quran-sessions-backend-agnostic-architecture.md)
