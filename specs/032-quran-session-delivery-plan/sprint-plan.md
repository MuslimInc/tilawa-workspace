# Sprint Plan — Quran Sessions (Sprints 0–8)

**Duration assumption:** 2 weeks per sprint (solo/small team). Adjust velocity as needed.  
**Stories:** [user-stories.md](./user-stories.md)  
**Free Beta launch target:** End of Sprint 8 (Google Play staged rollout begins).

---

## Sprint overview

| Sprint | Goal | Story range | Key deliverable |
|--------|------|-------------|-----------------|
| 0 | Blueprint review & scope freeze | — | Signed plan + locked P0 list |
| 1 | Data/security/lifecycle hardening | US-045–048, US-047, US-060, US-061, US-063, US-064 | CF + rules + profile + tests |
| 2 | Teacher onboarding & admin approval | US-019–022, US-033–034, US-035 | ≥5 teachers on staging |
| 3 | Teacher availability & dashboard | US-023–027, US-031, US-025 | Auth-aware dashboard + schedule |
| 4 | Student discovery & booking | US-001–006, US-050–052, US-058–059 | Booking on staging |
| 5 | Session lifecycle, cancel, reschedule, no-show | US-008–011, US-013–014, US-028–030, US-053–057 | meetingLink + FCM + cancel |
| 6 | Reports, disputes, admin ops | US-015–016, US-037–042, US-039 | Admin queues + mobile report UI |
| 7 | QA, staging, backfill, performance | US-062, US-065–067, US-072, US-071 | Smoke 10/10 + rollback drill |
| 8 | Internal testing & Google Play release | US-068–070, US-069 | Play closed → staged rollout |

---

## Sprint 0 — Blueprint review and scope freeze

**Dates:** Week 0 (3–5 days)  
**Goal:** Approve blueprint `031`, freeze Free Beta scope, lock priorities — **no feature code**.

### Stories

None (planning only). Review all 72 stories; confirm P0 list (44 stories).

### Dependencies

- Blueprint `031` complete
- Stakeholder availability for sign-off

### Deliverables

- [ ] Signed approval on `031-quran-session-blueprint/README.md` decisions
- [ ] This plan (`032`) approved with Free Beta IN/OUT explicit
- [ ] P0 story list frozen; change control process documented
- [ ] State machine acceptance: `SessionLifecycleStatus` locked (no enum changes without ADR)
- [ ] Test accounts provisioned (student, teacher, admin) on staging Firebase
- [ ] Ops contact + on-call for Beta assigned

### Tests

- N/A (documentation sprint)

### Demo checklist

- Walkthrough: student-flow, teacher-flow, admin-flow diagrams with stakeholders
- Review screen-inventory gaps vs sprint mapping
- Confirm Paid Sessions explicitly postponed (US-P01–P08)

### Exit criteria

- [ ] Written sign-off on scope freeze (email/doc)
- [ ] No open P0 ambiguities on booking flag, compensation, or payment off
- [ ] Sprint 1 backlog groomed and estimated

### Risks

| Risk | Mitigation |
|------|------------|
| Scope creep into paid features | IN/OUT list in README; US-P* marked postponed |
| Stakeholder unavailable | Async review with 48h comment window |

---

## Sprint 1 — Data, security, and lifecycle hardening

**Goal:** Real auth, profile persistence, rules enforcement, policy wiring, critical unit tests.

### Stories

| ID | Title | Priority |
|----|-------|----------|
| US-045 | Real auth UID everywhere | P0 |
| US-046 | quranSessionsProfile Firestore | P0 |
| US-047 | Deny client booking/session writes | P0 |
| US-048 | Configurable policies from Firestore | P0 |
| US-059 | Market config Firestore | P0 |
| US-060 | Lifecycle backfill scripts (dry-run on staging) | P0 |
| US-061 | ValidateBookingEligibilityUseCase tests | P0 |
| US-063 | CF integration + rules CI gate | P0 |
| US-064 | ProfileCompletionBloc tests | P0 |

### Dependencies

- Sprint 0 exit
- Firebase staging project access
- JDK 21+ for emulator tests

### Deliverables

- [ ] `requireQuranSessionsUserId` verified on all session BLoCs/routes
- [ ] `UserProfileRepositoryImpl` + auto-create on sign-in working on staging
- [ ] `firestore.rules` deployed to staging; `npm run test:rules` green
- [ ] `ConfigurableCancellationPolicy` used in cancel path (not `StandardCancellationPolicy` alone)
- [ ] Backfill dry-run report reviewed by ops
- [ ] 12 eligibility tests + ProfileCompletionBloc tests in CI

### Tests

- `flutter test packages/quran_sessions`
- `cd functions && npm run test:integration && npm run test:rules`
- `dart analyze` clean

### Demo checklist

- Fresh sign-in → profile shell created in Firestore console
- Blocked user cannot book (smoke #3) on staging
- Eligibility test report in CI

### Exit criteria

- [ ] All Sprint 1 P0 stories acceptance criteria met
- [ ] No `'student_mvp'` hardcode in production module paths
- [ ] Integration tests green locally and CI

### Risks

| Risk | Mitigation |
|------|------------|
| Emulator flaky in CI | Pin JDK 21; cache emulator |
| Legacy status drift | US-060 dry-run before any booking enable |

---

## Sprint 2 — Teacher onboarding and admin approval

**Goal:** Teacher apply → admin approve → public profile; seed ≥5 teachers on staging.

### Stories

| ID | Title | Priority |
|----|-------|----------|
| US-019 | Start teacher application | P0 |
| US-020 | Submit application for review | P0 |
| US-021 | View application status | P1 |
| US-022 | Complete public teacher profile | P0 |
| US-033 | Admin review applications | P0 |
| US-034 | Seed ≥5 approved teachers | P0 |
| US-035 | Suspend/revoke teacher | P1 |

### Dependencies

- Sprint 1 profile + rules
- Admin panel access (`apps/tilawa_admin`)
- `reviewTeacherApplication` CF deployed

### Deliverables

- [ ] End-to-end: apply on device → approve in admin → teacher visible in marketplace (flag permitting)
- [ ] ≥5 verified free teachers in EG with bios, languages, specializations
- [ ] Teacher application + status screens verified with real auth (not debug simulate only)
- [ ] Admin applications list/detail QA pass

### Tests

- `TeacherApplicationBlocTest` (existing) still green
- Manual: admin approve/reject flows
- Firestore: applicant write rules

### Demo checklist

- Live demo: new teacher application → admin approval → profile completion
- Show teacher card on student teacher list (behind discoverability flag)

### Exit criteria

- [ ] ≥5 teachers bookable on staging (slots may come Sprint 3)
- [ ] Reject cooldown and revoke permanent block verified
- [ ] Admin approval SLA process documented (<24h during Beta)

### Risks

| Risk | Mitigation |
|------|------------|
| Low teacher recruitment | Recruit before sprint; use team accounts as seed teachers |
| Admin panel auth issues | Verify admin claim early day 1 |

---

## Sprint 3 — Teacher availability and dashboard

**Goal:** Weekly schedule, overrides, auth-aware dashboard, booking notifications prep.

### Stories

| ID | Title | Priority |
|----|-------|----------|
| US-023 | Weekly availability schedule | P0 |
| US-024 | Vacation/overrides | P1 |
| US-025 | Teacher dashboard (auth-aware) | P0 |
| US-026 | Teacher booking notification | P0 |
| US-027 | Toggle slot from dashboard | P1 |
| US-031 | Teacher join meeting link | P0 |
| US-049 | Slot generation + integrity (server) | P0 |

### Dependencies

- Sprint 2 approved teachers
- Slot generator CF/backend path

### Deliverables

- [ ] Teacher dashboard uses authenticated teacher ID (fix `teacher_1` hardcode)
- [ ] Weekly availability saves and generates 14-day slots
- [ ] Vacation day blocks slot generation
- [ ] Dashboard shows upcoming sessions (may be empty until Sprint 4)
- [ ] Server-side `BookingIntegrityValidator` integrated in create path

### Tests

- `TeacherDashboardBlocTest` green
- Unit: slot_generator, schedule validators
- Manual: student sees slots after teacher saves schedule

### Demo checklist

- Teacher sets Mon/Wed schedule → student booking screen shows slots
- Dashboard toggle removes slot from student view

### Exit criteria

- [ ] At least 3 teachers with active schedules on staging
- [ ] No auth UID mismatch on teacher routes
- [ ] Slot integrity unit tests BI-01..BI-06 green

### Risks

| Risk | Mitigation |
|------|------------|
| Timezone confusion | Document device-local display; store UTC in Firestore |
| Schedule validation edge cases | Use existing validators in `packages/quran_sessions` |

---

## Sprint 4 — Student discovery and booking

**Goal:** Student browses teachers and books free session on staging with flag on.

### Stories

| ID | Title | Priority |
|----|-------|----------|
| US-001 | Sessions home entry + profile gate | P0 |
| US-002 | Browse teacher list | P0 |
| US-003 | Teacher profile | P0 |
| US-004 | Profile completion | P0 |
| US-005 | Booking eligibility errors | P0 |
| US-006 | Book free session | P0 |
| US-050 | createSessionBooking CF E2E | P0 |
| US-051 | Session/booking Firestore reads | P0 |
| US-052 | Meeting link on create | P0 |
| US-058 | Feature flags per environment | P0 |

### Dependencies

- Sprint 3 slots available
- `quranSessionsBookingEnabled=true` on **staging only**

### Deliverables

- [ ] Staging: full book flow persists to Firestore
- [ ] Booking flag enabled staging; prod remains off
- [ ] Idempotency + slot lock verified (smoke #4, #5)
- [ ] Paid teacher blocked with `payment_provider_unavailable` (smoke #10)
- [ ] Student My Sessions shows new booking

### Tests

- `BookingBlocTest`, `CreateSessionBookingUseCase` tests
- CF integration: createSessionBooking
- Manual: two students race same slot — one fails

### Demo checklist

- Student: home → teachers → profile → book → My Sessions
- Firestore console: booking + session docs created
- Feature flag kill preview (don't execute full rollback yet)

### Exit criteria

- [ ] Booking success rate >95% on staging (10+ test bookings)
- [ ] All Sprint 4 P0 acceptance criteria met
- [ ] `flutter test` + integration tests green

### Risks

| Risk | Mitigation |
|------|------------|
| Booking flag on without supply | Sprint 2 seed teachers + Sprint 3 schedules |
| Client still attempting direct writes | Verify repository uses `SessionCommandGateway` only |

---

## Sprint 5 — Session lifecycle, cancellation, reschedule, no-show

**Goal:** Join link visible, cancel with reason, FCM confirm/reminder, reschedule E2E, no-show paths.

### Stories

| ID | Title | Priority |
|----|-------|----------|
| US-007 | My upcoming/past sessions | P0 |
| US-008 | Join via meeting link | P0 |
| US-009 | Booking confirmation push | P0 |
| US-010 | Cancel with reason | P0 |
| US-011 | Request reschedule | P1 |
| US-013 | T-24h reminder | P0 |
| US-014 | Session detail + actions | P1 |
| US-028 | Teacher cancel + compensation | P0 |
| US-029 | Teacher confirm reschedule | P1 |
| US-030 | Mark student no-show | P1 |
| US-032 | Teacher request reschedule | P2 |
| US-053 | cancelSessionBooking CF | P0 |
| US-054 | Reschedule CFs | P1 |
| US-055 | FCM delivery wire | P0 |
| US-056 | manual_pending ledger | P0 |
| US-057 | Scheduled jobs | P0 |

### Dependencies

- Sprint 4 bookings exist on staging
- FCM tokens on test devices
- `deliverSessionNotification` deployed

### Deliverables

- [ ] `meetingLink` visible in `session_detail_screen.dart` + My Sessions
- [ ] Cancel sheet: reason ≥20 chars, policy copy from config
- [ ] Student + teacher cancel via CF with correct actor attribution
- [ ] FCM: booking confirm + T-24h reminder on test devices
- [ ] Reschedule request → teacher confirm E2E (minimum happy path)
- [ ] No-show: teacher mark after grace OR system job on test session
- [ ] Teacher cancel triggers `restoreSessionCredit` ledger record

### Tests

- `CancelSessionUseCase` tests all actors
- CF: cancel, reschedule, markNoShow, deliverNotification
- Widget: cancel sheet, session detail join CTA
- Manual: two phones — book, notify, cancel, reschedule

### Demo checklist

- Book → push received → open session → join link works
- Cancel session → other party notified
- Reschedule: student requests → teacher confirms → new time shown

### Exit criteria

- [ ] meetingLink P0 gap closed
- [ ] FCM confirm + reminder demonstrated on physical device
- [ ] Cancel + compensation path verified in admin/ledger
- [ ] Reschedule happy path E2E on staging

### Risks

| Risk | Mitigation |
|------|------------|
| FCM delivery unreliable | Test on OPPO A98 + Pixel; verify token storage |
| Reminder job timing | Create test session with near-future time + manual job trigger |

---

## Sprint 6 — Reports, disputes, and admin operations

**Goal:** Mobile report/dispute UI, admin queues, session moderation actions, user block.

### Stories

| ID | Title | Priority |
|----|-------|----------|
| US-015 | Report safety concern UI | P0 |
| US-016 | Open dispute UI | P1 |
| US-036 | Block student account | P1 |
| US-037 | Admin sessions list | P0 |
| US-038 | Admin session detail/timeline | P1 |
| US-039 | Admin session actions | P0 |
| US-040 | Reports queue A-10 | P0 |
| US-041 | Disputes queue A-11 | P0 |
| US-042 | manual_pending compensation | P0 |
| US-043 | Booking inspect read-only | P2 |
| US-044 | User moderation list | P1 |

### Dependencies

- Sprint 5 completed sessions on staging
- CF: `reportSessionConcern`, `openSessionDispute`, `resolveSessionDispute`

### Deliverables

- [ ] Mobile: report concern modal from session detail (S-12)
- [ ] Mobile: open dispute from completed session (S-13)
- [ ] Admin: `/quran-sessions/reports` list + resolve
- [ ] Admin: `/quran-sessions/disputes` list + resolve with compensation choice
- [ ] Admin session actions panel: cancel, no-show, force reschedule via CF
- [ ] Dispute resolution creates `manual_pending` ledger (smoke #7, #8)

### Tests

- CF integration: report + dispute callables
- Admin UI manual QA
- Lifecycle guard: dispute only from terminal states

### Demo checklist

- Student reports concern → appears in admin queue → resolved
- Student opens dispute on completed session → admin resolves favor_student → ledger visible

### Exit criteria

- [ ] All P0 admin stories functional on staging
- [ ] Ops runbook draft: dispute SLA 48h, report triage steps
- [ ] No direct Firestore writes from admin for mutations

### Risks

| Risk | Mitigation |
|------|------------|
| Admin UI build/deploy separate from mobile | Allocate time for `tilawa_admin` deploy |
| Dispute edge cases | Reference edge-cases-matrix E01–E56 for triage |

---

## Sprint 7 — QA, staging, backfill, and performance

**Goal:** Full QA pass, staging smoke 10/10, backfill, rollback drill, performance on device matrix.

### Stories

| ID | Title | Priority |
|----|-------|----------|
| US-062 | Widget tests booking + session detail | P1 |
| US-065 | Staging deploy + smoke 10/10 | P0 |
| US-066 | Performance slow network | P1 |
| US-067 | Production backfill prep | P0 |
| US-071 | Sentry/CF alerting | P1 |
| US-072 | Rollback drill | P0 |
| US-017 | Filter bar (if capacity) | P2 |
| US-018 | EN l10n (if capacity) | P2 |

### Dependencies

- Sprints 1–6 complete
- QA device matrix available (see qa-test-plan.md)

### Deliverables

- [ ] Full qa-test-plan.md execution on device matrix
- [ ] Staging smoke 10/10 signed off
- [ ] Rollback drill executed: flag off → bookings blocked → sessions readable → flag on
- [ ] Backfill scripts dry-run on prod-like data; apply on staging
- [ ] Sentry alerts configured for CF errors
- [ ] Zero open P0 bugs

### Tests

- Complete test-matrix P0 rows
- `flutter test` full workspace (sessions focus)
- `npm run test:integration` + `test:rules`
- Manual: OPPO A98, small Android, RTL, dark mode, slow 3G

### Demo checklist

- QA sign-off meeting with defect list (P1/P2 only remaining)
- Rollback drill recording for ops
- Performance notes on low-end device

### Exit criteria

- [ ] Staging smoke 10/10 ✅
- [ ] Rollback drill <15 min ✅
- [ ] QA sign-off on beta-testing-plan entry criteria
- [ ] Production deploy plan approved (release-checklist.md)

### Risks

| Risk | Mitigation |
|------|------------|
| Smoke failure late | Buffer 2–3 days; prioritize P0 fixes only |
| Device-specific bugs | OPPO battery/FCM settings documented |

---

## Sprint 8 — Internal testing and Google Play release

**Goal:** Play internal → closed Beta → staged rollout; Beta cohort metrics.

### Stories

| ID | Title | Priority |
|----|-------|----------|
| US-068 | Play internal track | P0 |
| US-069 | Closed testing cohort | P0 |
| US-070 | Staged rollout | P0 |

### Dependencies

- Sprint 7 exit (smoke + rollback)
- Play Console access, signed release build
- Privacy policy + store listing assets

### Deliverables

- [ ] AAB on internal track — core team validated
- [ ] Closed track: 20+ testers, guardian scenario tested if minors in cohort
- [ ] AR + EN release notes published
- [ ] Remote Config / flags: prod booking flag staged enable plan
- [ ] Staged rollout 5% with monitoring dashboard
- [ ] Beta final report metrics captured (README)

### Tests

- Install/update from Play on matrix devices
- Beta success metrics from beta-testing-plan.md
- Kill switch ready but not triggered unless stop condition

### Demo checklist

- Show Play Console rollout %, crash-free rate, booking count
- Walkthrough: trusted teacher + student live session on prod

### Exit criteria

- [ ] ≥20 internal/trusted users completed book→join→complete
- [ ] Booking success rate >95%
- [ ] <5% booking failure rate (excl. user error)
- [ ] Free Beta Go decision: Conditional Go → Go

### Risks

| Risk | Mitigation |
|------|------------|
| Play review delay | Submit early week 1; internal track parallel |
| Prod incident on rollout | 5% staged + rollback plan ready |

---

## Free Beta scope reminder (all sprints)

**IN:** Free sessions, verified teachers, book/cancel/reschedule, meeting link, FCM, reports/disputes, admin approval + moderation, manual_pending ledger only.

**OUT:** Paid booking, payouts, subscriptions, auto refunds, Agora/WebRTC, guardian flow, public reviews moderation, group sessions.

---

## Cross-sprint dependencies (critical path)

```
S0 sign-off → S1 auth/rules → S2 teachers → S3 availability → S4 booking
→ S5 lifecycle/FCM → S6 admin/disputes → S7 QA/smoke → S8 Play release
```

**Parallelizable:** US-061/064 (S1) with admin panel work; US-062 widget tests (S7); EN l10n US-018 (S7 buffer).
