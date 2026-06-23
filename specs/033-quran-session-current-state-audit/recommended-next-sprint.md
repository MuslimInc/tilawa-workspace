# Recommended Next Sprint

**Sprint:** 5 (per `specs/032-quran-session-delivery-plan/sprint-plan.md`)  
**Name:** Session join + notifications + booking on staging  
**Duration:** 2 weeks (solo/small team)  
**Audit date:** 2026-06-23 (refreshed same day)

---

## Sprint priority decisions

Answers: *Sprint 0 vs security-first vs teacher vs student booking vs availability perf vs admin vs delay reports/disputes vs disable paid.*

| Option | Verdict | Rationale |
|--------|---------|-----------|
| **Sprint 0** (scope freeze, architecture) | ✅ **Done** | `030`–`033` specs delivered; no more planning sprints |
| **Security-first** (App Check, rules hardening, audit export) | **Defer to Sprint 7** prod gate | Eligibility tests (US-061) + join path deliver more Beta user value now; App Check `enforceAppCheck: false` is **Should fix** before public, not before internal |
| **Teacher flows first** | **Parallel / mostly done** | Apply, availability, dashboard ✅; remaining work is **ops seed** (US-034) + meeting URL on profiles — not new teacher screens |
| **Student booking + join first** | ✅ **YES — Sprint 5 focus** | Highest user happiness; unblocks book→join→complete; items US-052, US-008, US-006, US-058 |
| **Availability perf** | **No — Sprint 7+** | `availability_operations_perf_test.dart` exists; US-066 manual matrix not launch-blocking; optimize after join works |
| **Admin build-out** | **Split Sprint 5–6** | Reports queue (A-10) **in Sprint 5** with mobile report — US-015 is P0 safety; disputes admin (A-11) **Sprint 6**; session actions panel polish ongoing |
| **Delay reports/disputes** | **No for reports** / **Yes for disputes mobile** | Cannot ship closed Beta without report path; dispute **mobile** modal (S-13) can lag if admin A-11 + CF triage exists |
| **Disable paid** | ✅ **Already correct** | `DisabledPaymentProvider`, `paymentProviderStatus.ts`, CF smoke #10 — keep off entire Free Beta |

**Recommended sequencing:** Student join journey → eligibility tests → staging flags + teacher supply → report (mobile + admin) → FCM device proof → smoke → disputes admin → rollback drill → Play internal.

---

## Sprint goal

A signed-in student on **staging** can: complete profile → book free slot → see session in My Sessions → **tap join and open meeting URL** → receive booking confirmation push. Admin can triage one safety report.

---

## Stories in scope

| Priority | Story | Deliverable | Owner lens |
|----------|-------|-------------|------------|
| P0 | US-052 | `meeting_link` on session doc in `createSessionBooking.ts` | Backend |
| P0 | US-008, US-031 | Wire `ExternalMeetingCallProvider` in bloc + `session_detail_screen.dart` | Flutter |
| P0 | US-058 | `quranSessionsBookingEnabled=true` + `teacherApplicationEnabled=true` on staging build | Release |
| P0 | US-034 | ≥5 verified free EG teachers seeded | Ops + Admin |
| P0 | US-061 | `validate_booking_eligibility_usecase_test.dart` (12 cases) | QA |
| P0 | US-015, US-040 | Report concern bottom sheet + admin reports list (read-only resolve OK) | Flutter + Admin |
| P1 | US-009, US-055 | FCM booking confirm on staging device | Backend + QA |
| P1 | US-010 | Cancel from session detail; reason min 20 chars | Flutter |
| P1 | US-014 | Session detail shows teacher name, call type, action CTAs | UX |

**Out of sprint (YAGNI):** reschedule E2E, disputes mobile UI, filter chips, EN l10n migration, App Check (unless prod deploy same sprint).

---

## Technical tasks (ordered)

```
1. TeacherProfile / platform config: add externalMeetingUrl source field
2. createSessionBooking.ts: set meeting_link on session + booking mirror
3. CF integration test: assert meeting_link non-null for externalMeeting
4. MySessionsBloc._onJoinRequested: load session → CallProvider.openUrl
5. session_detail_screen: join FAB, cancel, report entry
6. session_detail_screen_test + my_sessions join test
7. validate_booking_eligibility_usecase_test.dart (UC-VE-01..12)
8. Staging flags in CI/build flavor (dart-define)
9. Ops: approve 5 teachers, run seed:market-configs if needed
10. npm run quran-sessions:staging-smoke — target 8/10 minimum this sprint
11. ReportConcernSheet + reportSessionConcern gateway call
12. tilawa_admin: reports route + list component (minimal)
```

---

## Exit criteria

| # | Criterion | Verify |
|---|-----------|--------|
| 1 | Fresh student books on staging | Manual + smoke script |
| 2 | Join opens browser with valid URL | Manual |
| 3 | `flutter test packages/quran_sessions` green incl. new eligibility tests | CI |
| 4 | `npm test` + `npm run test:integration` green | CI |
| 5 | ≥5 teachers visible in student list | Admin + app |
| 6 | One report filed → visible in admin | E2E |
| 7 | Booking confirm push received on test device | Manual |
| 8 | `dart analyze` clean | CI |

---

## Risks

| Risk | Mitigation |
|------|------------|
| Teachers lack meeting URLs | Platform default URL in `quran_session_platform_config` |
| FCM token missing on test account | Document sign-in + notification permission path |
| Smoke fails on idempotency | Fix before widening Beta cohort |

---

## Following sprint (6) preview

Reports/disputes polish, admin dispute queue (A-11), reschedule confirm UX, T-24h reminder E2E, rollback drill (US-072).
