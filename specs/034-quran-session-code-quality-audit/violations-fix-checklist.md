# Violations Fix Checklist — Quran Sessions

**Audit date:** 2026-06-23  
**Sources:** All `specs/034-quran-session-code-quality-audit/` lenses + `specs/033-quran-session-current-state-audit/` blockers  
**Method:** Read-only synthesis; key paths verified in repo  
**Row cap:** ~42 deduplicated rows (same root cause merged)

---

## Intro — Severity vs Criticality vs Priority

These three terms are **not interchangeable**. Use each for its job.

| Term | Meaning | Example |
|------|---------|---------|
| **Severity** (P0 / P1 / P2) | Inherent **technical blast radius** if the defect ships — from 034 audit lenses | P0 empty join handler → join journey dead |
| **Criticality** (Critical / High / Medium / Low) | **Product, safety, or release** importance for Free Beta — from 033 gates + security review | Critical = cohort cannot complete book→join; Low = spacing token drift |
| **Priority** (P0 / P1 / P2) | **Scheduling weight** for engineers this sprint — may **differ** from severity when dependencies block work | P2 App Check is High criticality for public prod but P2 priority until closed Beta |

**Order column** = real **execution sequence** (1 = do first). It follows the 16-tier philosophy below — **not** a generic P0→P2 sort.

### Ordering philosophy (16 tiers)

1. Release / Free Beta blockers  
2. Security / safety / privacy  
3. Firestore rules / authorization gaps  
4. Data consistency / state integrity  
5. Booking / session lifecycle  
6. Child / guardian / abuse reporting  
7. Admin operability  
8. User impact / UX blockers  
9. Dependency order (backend → UI polish)  
10. Test coverage gaps for critical flows  
11. Performance visible to users  
12. Clean Architecture / SOLID bug-risk  
13. UI Kit / Atomic Design  
14. DRY / Clean Code cleanup  
15. YAGNI remove / postpone  
16. Paid-session postponed  

### Dependency rules (hard)

- No UI polish before backend / authz / lifecycle safe  
- No admin dispute UI polish before reports / disputes secure + triage exists  
- No availability UI optimize before correctness proven  
- No paid UX before payment provider  

---

## Main checklist

| Order | Priority | Criticality | Severity | Decision | Category | Violation | File(s) | User Impact | Security/Safety Risk | Data Consistency Risk | Dependency | Tests Required | Estimated Effort | Free Beta Blocker |
|-------|----------|-------------|----------|----------|----------|-----------|---------|-------------|----------------------|----------------------|------------|----------------|------------------|-------------------|
| 1 | P0 | Critical | P0 | Fix Now | Backend / Lifecycle | `meeting_link` not written on session doc at booking create | `functions/src/quranSessions/createSessionBooking.ts` | Join URL missing — book→join journey broken | Low (field empty, not leaked) | High — client/CF shape mismatch | Teacher `externalMeetingUrl` or platform default source | CF integration: assert `meeting_link` non-null after free create | 1–2 d | **Y** |
| 2 | P0 | Critical | P0 | Fix Now | DIP / Wiring | `CallProvider` not registered in app DI; `ExternalMeetingCallProvider` unused | `apps/tilawa/lib/features/quran_sessions/di/quran_sessions_firebase_module.dart`, `packages/quran_sessions/lib/src/boundaries/call/external_meeting_call_provider.dart` | Join cannot launch URL even if field exists | Low | Medium — dead abstraction | Row 1 (URL must exist) | DI smoke: provider resolvable | 0.5 d | **Y** |
| 3 | P0 | Critical | P0 | Fix Now | Clean Code / Arch | Empty `_onJoinRequested` handler — event swallowed | `packages/quran_sessions/lib/src/presentation/blocs/my_sessions/my_sessions_bloc.dart` (L96–99) | Join CTA does nothing | Low | Low | Rows 1–2 | `my_sessions_bloc_test`: join invokes `CallProvider` | 1 d | **Y** |
| 4 | P0 | Critical | P0 | Fix Now | UI / Atomic | Session detail missing join CTA / link preview | `packages/quran_sessions/lib/src/presentation/screens/session_detail_screen.dart` | Cannot join from detail (US-008, US-014) | Low | Low | Rows 1–3 | Widget: join visible when link + joinable status | 1 d | **Y** |
| 5 | P0 | Critical | P0 | Fix Now | LSP / Testability | Fake repo sets `meetingLink`; CF does not — behavioral divergence | `apps/tilawa/lib/features/quran_sessions/data/fake_mvp/fake_mvp_booking_repository.dart`, `createSessionBooking.ts` | False confidence in dev/tests | Low | High — prod surprise | Row 1 | Contract / parity test session doc shape | 0.5 d | **Y** |
| 6 | P0 | Critical | P0 | Fix Now | Release / Config | Booking + teacher-application flags default off on staging | `packages/quran_sessions/lib/src/presentation/config/quran_sessions_feature_config.dart`, staging build flavor | Students cannot book; teachers cannot apply | Low | Low | None | Manual: flags on in staging CI | 0.5 d | **Y** |
| 7 | P0 | Critical | P0 | Fix Now | Ops / Supply | &lt;5 verified teachers seeded in staging | Ops + `apps/tilawa_admin` application review (US-034) | Empty teacher browse; no bookable supply | Low | Low | Application approval flow | Manual: ≥5 teachers visible | 1–2 d (ops) | **Y** |
| 8 | P0 | Critical | P1 | Fix Now | Testability / Safety | `ValidateBookingEligibilityUseCase` — 0 dedicated unit tests (US-061) | `packages/quran_sessions/lib/src/domain/usecases/validate_booking_eligibility_usecase.dart` | Wrong gate could ship (child, market, limits) | **High** — eligibility regression | Medium | None | New `validate_booking_eligibility_usecase_test.dart` (~12 cases) | 1–2 d | **Y** |
| 9 | P0 | Critical | P1 | Fix Now | Safety / Product | Mobile report concern UI missing (CF exists) | New `ReportConcernSheet` + gateway wire; `functions/src/quranSessions/sessionReportCallables.ts` | Users cannot report safety issues | **High** | Low | CF participant check ✅ | Widget + callable integration | 2 d | **Y** |
| 10 | P0 | Critical | P1 | Fix Now | Admin / Safety | Admin reports queue missing (US-040 / A-10) | `apps/tilawa_admin/src/app/features/quran-sessions/` (new route) | Ops cannot triage reports | **High** | Low | Row 9 | Admin component smoke | 2 d | **Y** |
| 11 | P1 | High | P1 | Fix Before Beta | Admin / Safety | Admin disputes queue missing (US-041 / A-11) | `apps/tilawa_admin` (new route); `sessionDisputeCallables.ts` | Ops cannot resolve disputes | Medium | Medium | Rows 9–10 | Admin list + CF read | 2 d | **Y** |
| 12 | P1 | High | P1 | Fix Before Beta | Safety | `videoCallAllowedForChildren` not enforced in call-type picker | Booking / profile UI (per 033 security) | Child may see disallowed call type | **High** | Low | Eligibility step 8 | Unit: picker filters by teacher + profile | 1 d | N |
| 13 | P1 | High | P2 | Fix Before Beta | Security | `enforceAppCheck: false` on session callables | `functions/src/quranSessions/createSessionBooking.ts` (L55) + siblings | Callable abuse on public deploy | **High** (prod) | Low | Staging join path stable | Enable App Check prod; smoke | 1 d | N (Y prod) |
| 14 | P1 | High | P2 | Fix Before Beta | Firestore Rules | Thin rules test coverage for `quran_bookings` / `quran_sessions` | `firestore.rules`, `functions/test-rules/` | Regressions on US-047 undetected | Medium | Medium | None | New rules tests for participant read / deny write | 1–2 d | N |
| 15 | P1 | High | P1 | Fix Before Beta | Data Integrity | `parseLifecycleStatus` unknown → `scheduled` fallback | `apps/tilawa/lib/features/quran_sessions/data/firebase/session_firestore_mapper.dart` | Wrong status shown; hides bad data | Low | **High** | None | Mapper: unknown → failure not scheduled | 0.5 d | N |
| 16 | P1 | High | P1 | Fix Before Beta | Data Integrity | `legacyStatusForLifecycle` default `"pending"` for unknown | `functions/src/quranSessions/sessionLifecycleService.ts` | Silent legacy drift | Low | **High** | Row 15 | CF unit: unknown throws in strict mode | 0.5 d | N |
| 17 | P1 | High | P1 | Fix Before Beta | Clean Code | Review failure swallowed in `MySessionsBloc` | `my_sessions_bloc.dart` (L114–116) | User thinks review saved | Low | Medium | None | Bloc test: failure state emitted | 0.5 d | N |
| 18 | P1 | High | P1 | Fix Before Beta | Testability | No join widget test; session detail untested | `my_sessions_bloc_test.dart`, (new) `session_detail_screen_test.dart` | Join regressions undetected | Low | Low | Rows 1–4 | Widget + bloc tests | 1 d | N |
| 19 | P1 | High | P1 | Fix Before Beta | Release / QA | FCM booking confirm + T-24h reminder E2E unverified | `deliverSessionNotification.ts`, `sessionReminders.ts` | Missed confirmations / reminders | Low | Low | Rows 1–7 | Staging device manual + smoke | 1 d | N* |
| 20 | P1 | High | P1 | Fix Before Beta | Release / QA | Staging smoke 10/10 not evidenced (US-065) | `functions/scripts/stagingFreeBetaSmoke.ts` | Unknown prod regressions | Medium | Medium | Rows 1–10 | Run smoke ≥8/10 Sprint 5 | 1 d | **Y** |
| 21 | P1 | Medium | P1 | Fix Before Beta | UX / l10n | Timeline shows raw `event.action.name` (not localized) | `session_detail_screen.dart` (L61–63) | Poor AR UX on detail | Low | Low | Row 4 | Widget: localized timeline labels | 0.5 d | N |
| 22 | P1 | Medium | P1 | Fix Before Beta | UX | Cancel reason min 3 chars vs spec 20 (US-010) | `cancel_session_sheet.dart` (L110) | Weak cancel audit trail | Low | Low | None | Widget validation test | 0.5 d | N |
| 23 | P1 | Medium | P1 | Fix Before Beta | Admin | Admin session actions panel partial (US-039) | `session-detail.component.ts` | Ops limited session intervention | Low | Low | Rows 10–11 | Manual admin QA | 1 d | N |
| 24 | P2 | Medium | P1 | Fix Before Beta | UI Kit | Debug amber panel visible in release path | `teacher_application_status_screen.dart` (L305–342) | Unprofessional teacher status UI | Low | Low | None | Gate `kDebugMode` | 0.25 d | N |
| 25 | P2 | Medium | P2 | Fix After Beta | SOLID / KISS | `TeacherDashboardBloc` ~822 LOC — 6 responsibilities | `teacher_dashboard_bloc.dart` | Slot-delete bugs; slow changes | Low | Medium | Join stable | Characterization tests before split | 3–5 d | N |
| 26 | P2 | Low | P1 | Fix After Beta | Atomic | `TeacherDashboardScreen` ~1011 LOC — needs organisms | `teacher_dashboard_screen.dart` | UI bugs; review cost | Low | Low | Row 25 | Optional widget extractions | 3–5 d | N |
| 27 | P2 | Low | P1 | Fix After Beta | Atomic | `ProfileCompletionScreen` / `WeeklyAvailabilityScreen` oversized | `profile_completion_screen.dart`, `weekly_availability_screen.dart` | Maintenance cost | Low | Low | None | Step widget tests | 2–3 d each | N |
| 28 | P2 | Low | P2 | Fix After Beta | Arch | Router god file + `getIt` / `MvpStore` coupling | `quran_sessions_nav.dart` | Heavy route tests | Low | Low | None | Route test refactor | 2 d | N |
| 29 | P2 | Low | P2 | Fix After Beta | Testability | `MySessionsBloc` no injectable `now` | `my_sessions_bloc.dart` (L44) | Flaky midnight partition tests | Low | Low | None | Add `now` ctor param | 0.5 d | N |
| 30 | P2 | Low | P2 | Fix After Beta | UI Kit | Sessions list raw Material (`Card`, `ElevatedButton`, hardcoded padding) | `session_card.dart`, `my_sessions_screen.dart`, `cancel_session_sheet.dart` | Visual inconsistency | Low | Low | Rows 1–4 | Golden optional | 2 d | N |
| 31 | P2 | Low | P2 | Fix After Beta | UI Kit | Avatar hardcoded hex palette | `teacher_initials_avatar.dart` (L75–81) | Off-brand avatars | Low | Low | None | Token-based colors | 0.5 d | N |
| 32 | P2 | Low | P2 | Fix After Beta | DRY / Atomic | Admin filter + loading template duplicated | `sessions.component.html`, `teacher-applications.component.html` | Admin UI drift | Low | Low | Rows 10–11 | Component test | 1–2 d | N |
| 33 | P2 | Low | P1 | Fix After Beta | DRY | Teacher specialization ID list duplicated | `teacher_application_screen.dart`, `complete_teacher_public_profile_screen.dart` | Form drift | Low | Low | None | Shared `teacher_specializations.dart` | 0.5 d | N |
| 34 | P2 | Low | P2 | Fix After Beta | KISS | Dual fake + Firebase backend modules | `quran_sessions_mvp_module.dart`, `injection.dart` | Parity bugs | Low | Medium | Post-join | Consolidate fake to test-only | 2–3 d | N |
| 35 | P2 | Low | P2 | Fix After Beta | KISS / DRY | Legacy + lifecycle dual-write; parallel Dart/TS transition tables | `createSessionBooking.ts`, `session_transition_table.dart`, `sessionLifecycleGuard.ts` | Field sprawl; drift risk | Low | Medium | Production gate | Codegen spike | 3–5 d | N |
| 36 | P2 | Low | P2 | Fix After Beta | KISS | `quran_sessions_failure.dart` monolith ~430 LOC | `packages/quran_sessions/lib/src/domain/failures/quran_sessions_failure.dart` | Merge conflicts | None | Low | None | Split by subdomain | 1 d | N |
| 37 | P2 | Low | P2 | Fix After Beta | KISS | Optimistic slot delete + 5s undo timer complexity | `teacher_dashboard_bloc.dart` | Slot-delete edge cases | Low | Medium | Row 25 | Timer characterization tests | 2 d | N |
| 38 | P2 | Low | P2 | Postpone to Production | Product | Guardian linking UI (block only today) | `GuardianApprovalRequiredFailure` emitted; no UI | Guardians cannot approve children | Medium | Low | Production scope | Defer per ADR-003 | — | N |
| 39 | P2 | Low | P2 | Remove from Free Beta scope | Product | Teacher filter/search UI (US-017) | Not implemented | No filter chips | None | None | Production | — | — | N |
| 40 | P2 | Low | P2 | Remove from Free Beta scope | Product | Admin policy editor UI (A-14) | Use scripts / Firestore | Ops uses scripts | None | None | None | — | — | N |
| 41 | P2 | Low | P1 | Postpone to Paid Sessions | Clean Code / Paid | Hardcoded `SessionPricingType.free` in cancel sheet | `my_sessions_screen.dart` (L178) | Wrong policy copy when paid | Low | Medium | PSP provider | Pass `session.pricingType` | 0.5 d | N |
| 42 | P2 | Low | P2 | Postpone to Paid Sessions | YAGNI | Financial ledger + refund admin UI (CF exists, no UI) | `financialLedgerService.ts`, `approveSessionRefund.ts` | None in Free Beta | Low | Medium (paid) | Payment provider | Paid E2E | 5+ d | N |
| 43 | P2 | Low | P1 | Ignore for now | YAGNI | Agora / WebRTC call providers throw if miswired | `agora_call_provider.dart`, `web_rtc_call_provider.dart` | Crash only if registered | Low | Low | Not in DI | Do not register | — | N |
| 44 | P2 | Low | P2 | Ignore for now | YAGNI | Metrics aggregation — no dashboard consumer | `metricsAggregationService.ts` | None | None | Low | None | Keep | — | N |
| 45 | P2 | Low | P2 | Postpone to Production | Performance | Availability perf optimization (US-066) | `weekly_availability_screen.dart` | Minor latency | None | Low | Correctness first | Perf tests exist | 2+ d | N |

\*FCM E2E treated as closed-Beta blocker per 033; not code-structure blocker.

---

## 1. Top 5 fixes to do first (+ why)

| Order | Violation | Why first |
|-------|-----------|-----------|
| **1** | CF `meeting_link` on create | Root data defect — nothing downstream can work without URL on session doc |
| **2** | `CallProvider` DI registration | Simplest join path already built (`ExternalMeetingCallProvider`); unblocks bloc |
| **3** | Implement `_onJoinRequested` | Completes presentation→boundary wire; pairs with rows 1–2 |
| **4** | Session detail join CTA | Same journey, second entry point; US-008 acceptance |
| **8** | Eligibility use case unit tests | Independent safety gate; prevents wrong bookings while join work lands |

*Rows 5–7 (fake parity, staging flags, teacher seed) run parallel once row 1 is specced.*

---

## 2. Top 5 that can safely wait (+ why)

| Order | Violation | Why wait |
|-------|-----------|----------|
| **26** | Split `TeacherDashboardScreen` | Large refactor; dashboard works; join doesn't depend on it |
| **30** | UI Kit pass on sessions list | Cosmetic; booking/availability already use tokens |
| **35** | Legacy dual-write / lifecycle codegen | Mappers handle dual-read; production cleanup |
| **42** | Financial ledger admin UI | Explicitly out of Free Beta; CF gated |
| **44** | Metrics aggregation consumer | Low cost server-side; no user path |

---

## 3. Issues to remove from Free Beta scope

| Item | Rationale |
|------|-----------|
| Teacher filter/search (US-017) | Per `032` → Production |
| Admin policy editor (A-14) | Ops uses scripts / Firestore seed |
| OTP phone verify | ADR-003 deferred |
| Agora / WebRTC in-app call | External meeting sufficient for Beta |
| EN l10n complete migration (US-018) | Production polish |
| Lifecycle backfill scripts (US-060) | Pre-launch ops, not code blocker |

---

## 4. Issues to postpone until Paid Sessions

| Order | Item |
|-------|------|
| 41 | Cancel sheet hardcoded free pricing |
| 42 | Financial ledger + refund admin UI |
| — | `approveSessionRefund.ts` workflows |
| — | `DisabledPaymentProvider` → real PSP module |
| — | Paid booking E2E / smoke #10 |
| — | `amountPaidUsd` admin column (hide for free markets) |

---

## 5. Recommended exact next PR

**Title:** `feat(quran-sessions): wire join path — meeting_link, CallProvider, detail CTA`

**Scope (Phase 1 / Sprint 5):**

| Area | Files |
|------|-------|
| CF | `functions/src/quranSessions/createSessionBooking.ts` |
| DI | `apps/tilawa/lib/features/quran_sessions/di/quran_sessions_firebase_module.dart` |
| Bloc | `packages/quran_sessions/lib/src/presentation/blocs/my_sessions/my_sessions_bloc.dart` |
| UI | `packages/quran_sessions/lib/src/presentation/screens/session_detail_screen.dart` |
| Optional | `packages/quran_sessions/lib/src/presentation/widgets/session_card.dart` |
| Tests | `my_sessions_bloc_test.dart`, new `validate_booking_eligibility_usecase_test.dart`, CF create-booking test |

**Out of PR:** admin reports, disputes, UI Kit polish, dashboard split.

**Exit:** Staging book → Firestore has URL → tap join opens browser from My Sessions **and** detail.

---

## 6. Recommended exact next sprint (Sprint 5 from 033)

**Name:** Session join + notifications + booking on staging  
**Duration:** 2 weeks  

**In scope:** Orders 1–10, 20 (smoke ≥8/10), parallel 6–7 (flags + teacher seed), 8 (eligibility tests), 19 (FCM device proof P1).

**Sprint goal:** Signed-in student on staging completes profile → books free slot → sees session → **join opens meeting URL** → booking push received. Admin can triage one safety report.

**Out of scope:** Disputes mobile UI, reschedule E2E, filter chips, App Check prod, dashboard split.

**Exit criteria (from 033):** `flutter test packages/quran_sessions` green; `npm test` green; ≥5 teachers; one report E2E; `dart analyze` clean.

---

## 7. Updated Free Beta Go / No-Go

| Milestone | Verdict | Condition to flip |
|-----------|---------|-----------------|
| **Today (code + product)** | **NO-GO** | Join broken at CF + bloc + UI; flags off; safety queues missing |
| **After Sprint 5** | **CONDITIONAL GO** | Orders 1–10 + 20 partial; staging book→join manual green |
| **After Sprint 6–7** | **GO (closed cohort)** | Reports/disputes admin, smoke 10/10, rollback drill, FCM proven |
| **Play staged rollout** | **NO-GO** | Requires US-069 closed testing success post Sprint 7–8 |
| **Paid Sessions** | **NO-GO** | Correct — PSP off, ledger UI postponed |

**Gates passed today:** 6/17 (`033` go-no-go-summary)  
**Code quality lens (`034`):** ~72% — architecture sound; **wiring gap** not rewrite  
**Smallest path to Play internal:** Sprint 5 → 6 → 7 → upload AAB (~6 weeks)

---

## Metadata (agent return)

### Fix log (batch 1 — 2026-06-23)

| Order | Status | Fixed in | Tests | Verification |
|-------|--------|----------|-------|--------------|
| 1 | `[x] Fixed` | `createSessionBooking.ts`, `meetingLinkResolver.ts` | `meetingLinkResolver.test.ts`, integration | `npm test` pass |
| 2 | `[x] Fixed` | `quran_sessions_firebase_module.dart`, `quran_sessions_mvp_module.dart` | — | `dart analyze` DI |
| 3 | `[x] Fixed` | `my_sessions_bloc.dart` | `my_sessions_bloc_test.dart` | 6/6 pass |
| 4 | `[x] Fixed` | `session_detail_screen.dart`, `session_detail_bloc.dart` | — | staging manual next |
| 5 | `[x] Fixed` | CF integration parity | integration test | meetingLink asserted |
| 8 | `[x] Fixed` | `validate_booking_eligibility_usecase_test.dart` | 11 cases | all pass |

**Still open (same sprint):** 11, 12, 20.

### Fix log (batch 2 — 2026-06-23)

| Order | Status | Fixed in | Tests | Verification |
|-------|--------|----------|-------|--------------|
| 6 | `[x] Fixed` | `app_launch_config.dart` (`TILAWA_DISTRIBUTION` staging defaults) | `app_launch_staging_flags_test.dart` | `dart analyze` |
| 7 | `[x] Fixed` | `functions/scripts/seedStagingTeachers.ts`, `package.json` scripts | — | `npm run seed:staging-teachers` dry-run |
| 9 | `[x] Fixed` | `report_concern_sheet.dart`, `SessionMutationGateway.reportSessionConcern`, `session_detail_*` | `report_concern_sheet_test.dart` | `flutter test` |
| 10 | `[x] Fixed` | `tilawa_admin` reports list + detail routes | — | manual admin QA |

| Metric | Value |
|--------|-------|
| **Row count** | 45 |
| **Top 5 order numbers** | 1, 2, 3, 4, 8 |
| **Next PR title** | `feat(quran-sessions): wire join path — meeting_link, CallProvider, detail CTA` |
