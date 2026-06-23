# QA Test Plan — Quran Sessions Free Beta

**Stories:** [user-stories.md](./user-stories.md)  
**Test matrix:** [test-matrix.md](../031-quran-session-blueprint/test-matrix.md)  
**Edge cases:** [edge-cases-matrix.md](../031-quran-session-blueprint/edge-cases-matrix.md)

---

## Objectives

1. Verify Free Beta scope end-to-end on real devices before Play rollout
2. Achieve ≥95% coverage on lifecycle guard + configurable policies (P0)
3. Pass staging smoke 10/10 before Sprint 8
4. Sign off device matrix below with zero open P0 defects

---

## Test layers

| Layer | Scope | Tool | Owner | Sprint |
|-------|-------|------|-------|--------|
| Unit | Lifecycle guard, policies, use cases | `flutter test packages/quran_sessions` | Eng | S1, S5 |
| CF unit | Helpers, guards, mappers | `npm test` in functions | Backend | S1 |
| CF integration | Callables + emulator | `npm run test:integration` | Backend | S1, S4–S6 |
| Firestore rules | Security rules | `npm run test:rules` | Backend | S1 |
| BLoC | Booking, MySessions, Teacher*, Application | package tests | Eng | Continuous |
| Widget | Booking, session detail, profile completion | `flutter test` app | Eng | S7 |
| Manual device | Full flows per matrix below | Physical devices | QA | S7 |
| Admin manual | Applications, sessions, reports, disputes | Browser | QA | S6–S7 |
| Staging smoke | 10 checks | Script + test accounts | QA | S7 |
| Beta cohort | 20+ real users | Play closed track | Product | S8 |

---

## Device matrix (required)

| Profile | Device / env | OS | Locale | Theme | Network | Priority |
|---------|--------------|-----|--------|-------|---------|----------|
| Primary Android | OPPO A98 (or equivalent mid-range) | Android 15 | ar | light | WiFi | P0 |
| Small screen | 5" class Android (720p) | Android 12+ | ar | light | WiFi | P0 |
| Low-end | 2–3GB RAM Android | Android 10+ | ar | light | WiFi | P1 |
| RTL | Any above | Android | ar | light | WiFi | P0 |
| Dark mode | OPPO or Pixel | Android | ar | **dark** | WiFi | P1 |
| English locale | Pixel or emulator | Android | **en** | light | WiFi | P2 (Production) |
| Slow network | OPPO A98 | Android 15 | ar | light | **3G throttled** | P0 |
| Offline | Any | Android | ar | light | **airplane** after load | P1 |
| Admin | Desktop Chrome | — | en | light | WiFi | P0 |

### Per-profile test script (minimum)

1. Sign in with Google
2. Complete profile if gated
3. Browse teachers → open profile → book free slot (staging)
4. Receive FCM confirm (if enabled on device)
5. Open My Sessions → session detail → **join meeting link**
6. Cancel upcoming session with reason (separate test account/session)
7. Teacher path: dashboard loads with correct UID
8. Admin path: session visible in admin list

---

## Functional test suites

### TS-01 Student booking (P0)

| Case | Steps | Expected |
|------|-------|----------|
| TS-01-01 Happy book | Eligible student books free slot | scheduled + My Sessions |
| TS-01-02 Profile gate | Incomplete profile taps book | ProfileCompletionScreen |
| TS-01-03 Gender block | M/F mismatch teacher | Inline eligibility error |
| TS-01-04 Slot race | Two users same slot | One succeeds, one fails |
| TS-01-05 Flag off | Booking disabled | Clear message, no write |
| TS-01-06 Idempotency | Double-tap book | One booking |

### TS-02 Session lifecycle (P0)

| Case | Steps | Expected |
|------|-------|----------|
| TS-02-01 Join link | Open detail on confirmed session | Link opens browser |
| TS-02-02 Student cancel early | >24h, reason 20+ chars | cancelledByStudent |
| TS-02-03 Teacher cancel | Teacher cancels with reason | cancelledByTeacher + compensation record |
| TS-02-04 Reschedule | Request + confirm | New time shown |
| TS-02-05 No-show | After grace, teacher marks | studentNoShow |
| TS-02-06 Reminder | Session in 24h | Push received once |

### TS-03 Teacher onboarding (P0)

| Case | Steps | Expected |
|------|-------|----------|
| TS-03-01 Apply | Submit valid application | pending status |
| TS-03-02 Invalid phone | Bad KW number | Validation error |
| TS-03-03 Admin approve | Admin approves | Teacher profile created |
| TS-03-04 Availability | Set weekly schedule | Student sees slots |

### TS-04 Admin ops (P0)

| Case | Steps | Expected |
|------|-------|----------|
| TS-04-01 Reports queue | Student reports concern | Visible in admin |
| TS-04-02 Dispute resolve | Open + resolve dispute | manual_pending ledger |
| TS-04-03 Block user | Admin blocks student | Booking fails account_blocked |
| TS-04-04 Session cancel | Admin cancels session | Correct actor + audit |

### TS-05 Security (P0)

Align with smoke checklist — run automated where possible.

| # | Automated | Manual |
|---|-----------|--------|
| 1 Unauthorized cancel | integration test | — |
| 2 Blocked self-unblock | rules test | — |
| 3 Blocked booking | integration test | — |
| 4–10 | integration tests | staging verify |

---

## Regression scope (each sprint)

- `flutter test packages/quran_sessions` — full package
- Existing BLoC tests: Booking, MySessions, TeacherList, TeacherProfile, TeacherDashboard, TeacherApplication
- `dart analyze` apps/tilawa + packages/quran_sessions
- Functions: full `npm test` on any CF touch

---

## Entry / exit criteria

### QA entry (Sprint 7)

- [ ] All P0 stories marked dev-complete on staging
- [ ] CF deployed to staging
- [ ] ≥5 teachers with schedules
- [ ] Test accounts provisioned (2 students, 2 teachers, 1 admin)
- [ ] Device matrix hardware available

### QA exit (Sprint 7 → Sprint 8)

- [ ] Device matrix P0 rows passed
- [ ] Staging smoke 10/10
- [ ] Zero P0 defects open
- [ ] P1 defects documented with workarounds
- [ ] Rollback drill witnessed by QA
- [ ] QA sign-off document linked in release checklist

---

## Defect severity

| Severity | Definition | Beta blocker |
|----------|------------|--------------|
| P0 | Cannot book/join; data leak; wrong user data; crash on core path | Yes |
| P1 | Cancel/reschedule/notify broken; admin cannot resolve dispute | No if workaround |
| P2 | UI polish, filter bar, EN strings | No |
| P3 | Cosmetic | No |

---

## Test data requirements

| Data | Staging setup |
|------|---------------|
| EG market enabled | `quran_session_market_configs/EG` |
| 5+ verified free teachers | Seed + admin approval |
| Teacher meeting URLs | Profile field or platform default |
| Test student profiles | Complete + incomplete variants |
| Blocked user account | For smoke #2–3 |
| Session in each lifecycle state | Seed or script for admin QA |

---

## Reporting

- Daily defect log during Sprint 7 (spreadsheet or issue tracker)
- Trace defects to story ID (US-xxx)
- Final QA report: pass/fail per device matrix row + smoke 10/10 screenshot/log

---

## Out of scope (Beta QA)

- Payment flows
- Subscription
- Agora/WebRTC calls
- Guardian linking
- iOS (unless explicitly added — Android-first per Play plan)
- Load testing beyond sanity (10 concurrent bookings manual)
