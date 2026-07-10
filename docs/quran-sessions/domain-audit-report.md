# Quran Sessions — Domain Audit Report

**Audit date:** 2026-07-03  
**Scope:** `packages/quran_sessions/`, `apps/tilawa/lib/features/quran_sessions/`, `functions/src/quranSessions/`, related specs  
**Verdict:** Rich domain model exists on paper and in package; production wiring is **partial** with **dual-status debt**, **fake MVP path**, and **unresolved product forks** blocking production-ready business flows.

---

## Executive summary

| Area | Maturity | Production-ready? |
|------|----------|-------------------|
| Domain enums & transition table | High | Yes (spec) / Partial (enforcement) |
| Flutter clean architecture | High | Yes |
| Firestore + CF backend | Medium | Conditional |
| Admin panel ops | Low | No |
| Payments / fees | Low | No — blocked |
| Video-only product intent | Low | No — voice/external still exposed |
| Fake/dev backend | High (dev) | Must not ship |

**Do not treat as MVP:** Specs 030–038 explicitly target production; codebase still carries Free Beta paths (`SessionModePolicy.freeBeta`, mock RTC, external meeting defaults).

---

## What exists (strengths)

### Package domain (`packages/quran_sessions/`)

- **Canonical lifecycle:** `SessionLifecycleStatus` (22 states) + `SessionTransitionTable` + `SessionLifecycleGuard` pattern mirrored in TS (`sessionLifecycleGuard.ts`).
- **Legacy bridge:** `legacy_status_lifecycle_mapper.dart` maps old `QuranSessionStatus` / `BookingStatus` — migration in progress.
- **Policies:** `SessionListClassifier`, `SessionModePolicy`, `QuranTutorBookingMode`, `ConfigurableCancellationPolicy` (spec), booking eligibility chain.
- **Use cases:** 40+ domain/application use cases; server mutations via `SessionMutationGateway` / `SessionCommandGateway`.
- **Market config:** `MarketConfig` with admin-driven min/max price, commission — no hardcoded fees in entity layer.

### App integration (`apps/tilawa/lib/features/quran_sessions/`)

- **Dual DI:** `QuranSessionsFirebaseModule` (production path) vs `QuranSessionsMvpModule` (fake in-memory).
- **Backend switch:** `QuranSessionsBackendMode` via `TILAWA_QURAN_SESSIONS_BACKEND`.
- **Feature flags:** `QuranSessionsFeatureConfig`, launch policy, router guards with tests.
- **Firebase data layer:** Firestore repos for teachers, bookings, sessions, policies, wallet (sandbox), availability.

### Backend (`functions/src/quranSessions/`)

- Callables: create/cancel/reschedule/complete/no-show/compensation/dispute/report.
- Scheduled: reminders, expire pending reservations.
- Lifecycle guard aligned with Dart transition table.

### Tests

- Domain: lifecycle mapper, session mode policy, session list classifier, booking flow, tutor booking mode.
- Widget: booking screen, my sessions, teacher dashboard (partial).
- Router: session guards, nav.

---

## Critical gaps

### G1 — Dual status model (UI vs domain)

Three parallel status systems coexist:

| Layer | Enum | Values |
|-------|------|--------|
| Canonical | `SessionLifecycleStatus` | 22 states |
| Legacy session | `QuranSessionStatus` | 6 states |
| Legacy booking | `BookingStatus` | 7 states |

**Risk:** Firestore rows with only legacy fields mis-classify lists (`noShow` → `bothNoShow`). UI uses `effectiveLifecycleStatus` fallback but server/client must agree on writes.

**Evidence:** `legacy_status_lifecycle_mapper.dart`, `quran_session.dart` lines 83–84.

---

### G2 — Fake MVP backend still first-class

`QuranSessionsMvpModule` registers **12+ FakeMvp* repositories** with instant confirm booking, example meeting URLs, no tutor approval, no payment, no CF validation.

**Risk:** Local dev without Firebase mirrors production rules poorly. Fake booking auto-sets `BookingStatus.confirmed` + `scheduled` — hides approval/payment flows.

**Evidence:** `fake_mvp_booking_repository.dart`, `quran_sessions_mvp_module.dart`.

---

### G3 — Video-only intent not enforced

User requirement: **VIDEO CALL ONLY**. Current state:

- `SessionModePolicy.freeBeta` enables external + voice + video.
- Production launch default: `enabledCallProviders = external,mock` (not in-app video).
- Booking default when no external URL: **voice** (`SessionModePolicy.defaultCallType`).
- `BookingSelecting.selectedCallType` default: `SessionCallType.voiceCall`.
- L10n still prompts "Choose voice or video."

**Blocked by:** Q-VC-01, Q-VC-02 in `questions.md`.

---

### G4 — Tutor approval fork unresolved

Code supports both paths:

- `QuranTutorBookingMode.autoConfirm` (staging default)
- `QuranTutorBookingMode.requiresTutorApproval` (`play_production` default)

CF + transition table support `pendingTutorApproval` → accept/reject/expired. Fake MVP **skips** approval entirely.

**Blocked by:** Q-BK-01, Q-BK-02, Q-TA-01.

---

### G5 — Fees / paid booking not production-ready

- `SessionPricingType.fixedPerSession` modeled; wallet UI gated off (`walletEnabled` default false).
- `DisabledPaymentProvider` in Firebase module; sandbox only.
- Egypt `ManualPaymentPrice` is **presentation-only** — not a payment engine.
- Admin policy editor 🔴 missing.

**Blocked by:** Q-FE-01 through Q-FE-04, Q-AD-03.

---

### G6 — UI state vs business state mismatches

| Issue | Detail |
|-------|--------|
| Upcoming list filtering | `GetStudentSessionsUseCase` puts cancelled sessions in `upcoming` bucket then UI re-filters — confusing data layer contract |
| `pendingTutorApproval` | Excluded from Upcoming (correct) but no dedicated Pending tab (Q-BK-02) |
| Hardcoded reschedule gate | `_canStudentRequestReschedule` uses 24h constant — should be policy-driven |
| Join eligibility | Client uses `canJoinSession` on lifecycle; server must also enforce join window (Q-VC-03) |

**Evidence:** `get_student_sessions_usecase.dart`, `my_sessions_screen.dart` line 514–522.

---

### G7 — Admin / ops gaps

Per `specs/033-quran-session-current-state-audit/implementation-status.md`:

- Reports queue UI 🔴
- Disputes queue UI 🔴
- Policy editor 🔴
- Financial ledger ⏸️

Production domain rules exist in spec 031 `business-rules.md` but **configuration UI** to change them is missing.

---

### G8 — Client-only validation risk

Some gates run client-side only (eligibility pre-check, cancel button visibility, reschedule 24h). CF lifecycle guard protects mutations, but **action availability** should come from server (Q-SR-02).

---

## Persistence map

| Aggregate | Firestore collection | Client write | Mutations |
|-----------|---------------------|--------------|-----------|
| User profile | `users/{uid}` (quranSessionsProfile) | Partial (rules gated) | Profile use cases |
| Teacher profile | `quran_teacher_profiles` | Denied | CF moderation |
| Booking | `quran_bookings` | Denied | `createSessionBooking` CF |
| Session | `quran_sessions` | Denied | CF callables |
| Events | `quran_session_events` | Denied | CF |
| Market config | `quran_session_market_configs` | Admin | Admin panel / console |
| Platform config | `quran_session_platform_config/global` | Admin | Admin panel / console |

---

## Test coverage snapshot

| Rule | Tested? |
|------|---------|
| Terminal states excluded from upcoming | Partial — extended 2026-07-03 |
| Tutor booking mode parsing | Yes |
| Session mode policy | Yes |
| Full lifecycle transition guard (Dart) | Yes (package) |
| CF lifecycle integration | Yes (functions tests) |
| Paid booking E2E | No |
| Tutor approval E2E | No |

---

## Recommendations (safe now)

1. Resolve P0 questions in `questions.md` before booking/payment/call-modality work.
2. Complete `lifecycleStatus` backfill; deprecate legacy status writes.
3. Wire `SessionModePolicy.videoOnly` only after Q-VC-01 sign-off.
4. Add server `allowedActions` to session detail API (design in `production-domain-model.md`).
5. Keep fake MVP behind explicit dart-define; never default in release builds.

---

## Related docs

- [questions.md](./questions.md) — decision checklist
- [production-domain-model.md](./production-domain-model.md) — target model
- [session-lifecycle.md](./session-lifecycle.md) — transition table
- [remaining-risks.md](./remaining-risks.md) — approval-needed risks
- Specs: `specs/030-quran-sessions-domain/`, `specs/031-quran-session-blueprint/`
