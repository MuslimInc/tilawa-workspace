# Production Gap Analysis — Quran Sessions Stable v1

**Audit date:** 2026-06-24  
**Method:** Code read + existing spec 037 reports + automated test inventory (tests not re-run in audit pass)

Format per area: **Current Status** | **Production Risk** | **Blocker?** | **Required Fix** | **Tests Required** | **Can Ship Without It?**

---

## 1. Product Flow Readiness

| Flow | Classification | Current Status | Production Risk | Blocker? | Required Fix | Tests Required | Ship Without? |
|------|----------------|----------------|-----------------|----------|--------------|----------------|---------------|
| Student discovery (home, teacher list) | Acceptable with limitation | `GetTeachersUseCase`, `isPubliclyVisible` query; empty state when no supply | Low supply → empty UX | No | Ops: seed verified teachers | Teacher list widget tests exist | Yes (with empty state) |
| Teacher browse / profile | Production ready | `TeacherProfileScreen`, availability window, book CTA gated | Low | No | — | Profile bloc tests | Yes |
| Profile completion gate | Production ready | `openHomeQuranSessions()` redirects incomplete profiles | Low | No | — | Eligibility UC tests | Yes |
| Free booking | Acceptable with limitation | CF `createSessionBooking`; flag `quranSessionsBookingEnabled` default **false** on `play_production` | Medium if flag mis-set | No (if flag off) | Manual B1–B5 sign-off | 22 integration + booking bloc/screen | No for wide rollout |
| Session detail | Production ready | Join/report/dispute footer; external meeting sheet | Low | No | — | Screen + join sheet tests | Yes |
| Join (external/mock) | Acceptable with limitation | `JoinSessionUseCase` + `RoutingSessionCallProvider`; no RTC SDK | External link dependency | No | Legal privacy verify | Join UC + call provider tests | Yes |
| Cancel | Production ready | Student + teacher cancel via CF; lifecycle guards | Low | No | — | Cancel UC + sheet tests | Yes |
| Reschedule | Acceptable with limitation | Mobile **request only**; admin confirms via request ID | Ops must use admin | No | Document ops path | UC only; no RescheduleBloc tests | Yes (admin confirm) |
| No-show (teacher mobile) | Postpone | `MarkNoShowUseCase` registered; **no** mobile UI | Admin marks no-show | No | Admin panel only | UC (2 tests) | Yes |
| Report concern | Production ready | CF + mobile sheet; admin queue read-only | Low | No | — | CF integration (5) + sheet validation | Yes |
| Open dispute | Production ready | CF + mobile; admin read-only triage | Low | No | Ops via session detail actions | CF integration (3) | Yes |
| Teacher application | Acceptable with limitation | Flag-gated; default off on production | Supply control | No | Enable when ops ready | Application flow tests | Yes (flag off) |
| Teacher approval → dashboard | Production ready (after 037 Phase B) | CF creates profile; capability refresh on resume/FCM; **متابعة** CTA | `isActive: false` after deactivate edge | No | Backfill + re-activate path documented | Capability + settings tests | Yes |
| Teacher dashboard / availability | Production ready | Gated by `_TeacherDashboardGate` + capability | Low | No | — | Dashboard bloc tests | Yes |
| Admin approve teachers | Production ready | Angular → `reviewTeacherApplication` CF | Low | No | — | CF unit tests | Yes |
| Admin sessions moderation | Production ready | Cancel, no-show, complete, compensation, refund, reschedule confirm | Low | No | — | Integration tests | Yes |
| Admin reports/disputes | Acceptable with limitation | List + detail **read-only**; resolve via session detail CF | Ops training | No | Document triage → session detail | Admin UI untested | Yes |
| Wallet (read-only) | Acceptable with limitation | Route exists; no checkout in prod (`DisabledPaymentProvider`) | User confusion | No | Optional: hide wallet CTA on production | Sandbox tests only | Yes |
| Paid / group paths | Must hide/remove | CF rejects group + paid when disabled; no group UI | High if exposed | No (blocked) | Keep flags off | Integration rejection tests | N/A |
| Home entry when feature off | **Fixed (038)** | Was: footer always showed Learn Quran | Rollback broken | Was P0 | Wire `quranSessionsEnabled` | Route guard tests | No |

---

## 2. Session Mode / Provider Change

| Item | Status | Risk | Blocker? | Fix | Tests | Ship Without? |
|------|--------|------|----------|-----|-------|---------------|
| Lock at booking (Option A) | Production ready | Predictable join | No | Document in session detail copy | Integration: provider fields CF-only | Yes |
| Admin override CF | Acceptable with limitation | Support needs manual CF/admin session actions | No | Document ops; optional `adminOverrideSessionCallSettings` post-v1 | Rules deny client patch | Yes |
| Bilateral change (Option C) | Postpone | Complexity | No | Post-beta per [037 policy](../037-quran-session-free-beta-closure/session-mode-provider-change-policy.md) | — | Yes |

**Recommendation:** **Option A (lock only)** for stable production v1. Option B (admin override) acceptable via existing admin session detail actions without new mobile UI.

---

## 3. Admin Operations

| Capability | Status | Risk | Blocker? | Fix | Tests | Ship Without? |
|------------|--------|------|----------|-----|-------|---------------|
| Approve/reject/suspend teachers | Production ready | Low | No | — | CF + admin gateway specs | Yes |
| View bookings/sessions | Production ready | Low | No | — | — | Yes |
| Reports queue | Production ready (read-only) | Triage only | No | Ops runbook | CF integration | Yes |
| Disputes queue | Production ready (read-only) | Triage only | No | Resolve via session detail | CF integration | Yes |
| Audit timeline | Production ready | Low | No | — | — | Yes |
| Suspend QS users | Production ready | Low | No | — | Rules moderation tests | Yes |
| Wallet admin credit | Acceptable with limitation | Out of free scope | No | Manual W1–W4 | Wallet integration | Yes (if wallet hidden) |
| Inspect mode/provider | Production ready | Session doc in admin detail | No | — | — | Yes |

---

## 4. Backend / Security

| Item | Status | Risk | Blocker? | Fix | Tests | Ship Without? |
|------|--------|------|----------|-----|-------|---------------|
| CF-facade writes (bookings, sessions) | Production ready | Low | No | — | Integration + rules | Yes |
| Lifecycle guards | Production ready | Low | No | — | `sessionLifecycleGuard.test.ts` | Yes |
| Idempotency | Production ready | Low | No | — | Integration tests | Yes |
| Participant reads (Firestore) | Production ready | Low | No | — | `quranSessions.rules.test.ts` | Yes |
| Teacher CF auth (profile id ≠ uid) | **Fixed (038)** | Teachers blocked from cancel/reschedule/dispute | Was P0 | Pass `teacherUserId` to `resolveActorRole` | `sessionAuthHelpers.test.ts` | No |
| Eligibility field client write | **Fixed (038)** | Gender/age spoof before booking | Was P0 | Rules freeze eligibility fields | `usersModeration.rules.test.ts` | No |
| App Check on session CFs | Needs fix | Callable spam / abuse | **P1 prod** | Staged `enforceAppCheck: true` | Staging smoke | Yes for closed beta |
| Single-device epoch | Acceptable with limitation | Epoch client-readable; ~1h ID token window | No | Document limitation | `activeDevice.integration.test.ts` | Yes |
| Slot/time server validation | Acceptable with limitation | Wrong slot times possible | No | Post-v1 hardening | — | Yes |
| Join info privacy | Production ready | Participant-only rules on sessions | No | — | Rules tests | Yes |
| Provider metadata mutation | Production ready | `quran_sessions` write denied client-side | No | — | Verify rules | Yes |

---

## 5. Notifications

| Item | Status | Risk | Blocker? | Fix | Tests | Ship Without? |
|------|--------|------|----------|-----|-------|---------------|
| Booking / cancel / reschedule | Production ready | Low | No | — | Outbox + reminder tests | Yes |
| Single-device FCM targeting | Production ready | `activeFcmToken` server-only | No | — | FCM service tests | Yes |
| Token invalidation | Production ready | Admin SDK clears bad tokens | No | — | Unit tests | Yes |
| Outbox retry | Production ready | CF-managed | No | — | `notificationOutboxService.test.ts` | Yes |
| Teacher approval push | Production ready | FCM on `reviewTeacherApplication` | No | — | Manual T7 | No for teacher E2E |

---

## 6. Audio/Video Provider

| Item | Status | Risk | Blocker? | Fix | Tests | Ship Without? |
|------|--------|------|----------|-----|-------|---------------|
| `SessionCallProvider` abstraction | Production ready | Low | No | — | Routing + join tests | Yes |
| external + mock only in DI | Production ready | No SDK bloat | No | — | Grep + DI module | Yes |
| Agora/WebRTC not registered | Production ready | Stubs throw | No | — | Routing rejects agora/webrtc | Yes |
| Join info privacy | Production ready | Metadata from server session doc | No | — | Join UC tests | Yes |
| External URL launch (Android 11+) | Production ready | Manifest `<queries>` for https/http | No | — | `external_meeting_url_launcher_test.dart` | Yes |

---

## 7. QA / Test Coverage

| Area | Status | Gap | Blocker? | Tests Required | Ship Without? |
|------|--------|-----|----------|----------------|---------------|
| Booking domain + CF | Strong | Manual E2E unsigned | No | B1–B5 manual | No for wide rollout |
| Join / cancel | Good | — | No | SessionDetailBloc join/report/dispute tests (038) | Yes |
| Reschedule UI | Partial | No RescheduleBloc tests | No | P1 widget tests | Yes |
| Report/dispute mobile | Thin UI | Sheet validation only | No | P1 E2E | Yes |
| Admin Angular | Minimal | No report/dispute UI specs | No | P1 | Yes |
| Single-device | Strong backend | No Maestro two-device | No | T2–T8 manual | No for device QA |
| Rules emulator | Good | — | No | Write-denial on bookings/sessions/events (038) | Yes |
| Dark mode / error UI | Weak | No dark theme widget tests | No | P2 | Yes |
| CI preflight | Exists | Not wired to all PR paths | No | Wire `quran_sessions_preflight.sh` | Yes |

**Inventory:** ~85 package tests, ~10 app quran_sessions tests, 21 CF unit + 6 integration files, 20 rules tests (quran + activeDevice + moderation).

---

## 8. UX Production Quality

| Item | Status | Risk | Blocker? | Fix | Ship Without? |
|------|--------|------|----------|-----|---------------|
| AR l10n | Production ready | ~530 AR / ~537 EN ARB entries | No | — | Yes |
| RTL | Acceptable with limitation | Some goldens; dashboard RTL manual | No | Manual QA | Yes |
| Dark mode | Acceptable with limitation | No automated dark tests | No | P2 smoke | Yes |
| Error states | Acceptable with limitation | Callable mappers tested; failure_ui thin | No | P1 | Yes |
| MeMuslim branding | Production ready | Settings uses MeMuslim tile naming | No | — | Yes |
| Home sessions entry | Production ready | Footer link only (`HomeDashboardFooter`); dead `HomeSessionsEntryCard` removed | No | — | Yes |

---

## 9. Monitoring / Rollback

| Item | Status | Risk | Blocker? | Fix | Ship Without? |
|------|--------|------|----------|-----|---------------|
| `quranSessionsBookingEnabled` | Production ready | Route redirect + profile CTA | No | — | Yes |
| `quranSessionsEnabled` | **Fixed (038)** | Was not enforced | Was P0 | Router + home footer | Yes |
| Firestore `enabledCallProviders` | Production ready | Server-side mock kill | No | — | Yes |
| Crashlytics/Sentry (feature-scoped) | Needs fix | Generic app telemetry only | No | P1 breadcrumbs | Yes |
| Backend metrics | Production ready | `metricsAggregationService` | No | — | Yes |
| Manual sign-off table | Not done | All cells ⬜ | **Release** | Execute QA runbooks | No |

---

## Summary matrix

| Area | Overall |
|------|---------|
| Product flows | Conditional Go |
| Mode/provider | Go (Option A) |
| Admin ops | Go (read-only triage acceptable) |
| Backend/security | Go after 038 P0 fixes; App Check P1 |
| Notifications | Go |
| A/V provider | Go (external + mock) |
| QA coverage | Conditional Go (manual pending) |
| UX | Go with minor gaps |
| Monitoring/rollback | Go after kill switch wired |
