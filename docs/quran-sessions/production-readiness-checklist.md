# Quran Sessions — Production Readiness Checklist

**Last updated:** 2026-07-10 (Spec 039 — App Check release gate added to § 3)

**Scope:** Free / video-only limited rollout — **not** paid booking or reschedule product work.

---

## Sign-off (launch gate — 2026-07-03)

| Field | Value |
|-------|-------|
| **Recommendation** | **READY FOR LIMITED ROLLOUT** (code + tests); **BLOCKED** on manual ops (Firestore seed apply to target env, App Check staging soak, Maestro/manual QA) |
| **Executor** | Automated launch gate (CI-local) |
| **Firebase project (scripts default)** | `quran-playera-app` (`functions/src/github.ts`) |
| **Pilot market** | **EG** (Egypt) — primary rollout per `docs/seed/quran_session_market_configs.json`; seeds also define SA, AE |

**Completion:** ~72% verified locally (backend tests + dry-run seeds + live Firestore backfill counts). Remaining items require staging soak, explicit `--apply` seeds per environment, and device QA.

---

## 1. Admin config seed

| Item | Status | Evidence |
|------|--------|----------|
| Platform seed script dry-run | ✅ | `cd functions && npm run seed:platform-config` — writes `quran_session_platform_config/global` (see § Seed summary) |
| Market seed script dry-run | ✅ | `npm run seed:market-configs` — EG+10 cities, SA+5, AE+4 |
| `validatePlatformConfig` | ✅ | `functions/test/quranSessions/sessionPolicyResolver.test.ts` (unit) |
| `validateMarketConfigForBooking` | ✅ | same |
| `assertBookingPolicyConfigured` / `policy_not_configured` | ✅ | unit test `assertBookingPolicyConfigured fails closed when market doc missing` |
| **Apply seeds to staging** | ✅ | Platform + market apply verified on `quran-playera-app` (second pass 2026-07-03); production apply still ops-owned |

---

## 2. Lifecycle backfill

| Item | Status | Evidence |
|------|--------|----------|
| CF dual-write `lifecycleStatus` + legacy `status` | ✅ | `backend-enforcement-summary.md`; `legacyStatusForLifecycle` tests pass |
| Flutter reads prefer `lifecycleStatus` | ✅ | `resolveLifecycleStatusRawFromFirestore` in `packages/quran_sessions/lib/src/domain/services/lifecycle_status_parser.dart`; mapper uses it in `session_firestore_mapper.dart` |
| Backfill lifecycle (live project scan) | ✅ | `npm run quran-sessions:backfill-lifecycle` → `bookings=0, sessions=0` (nothing missing `lifecycleStatus` on `quran-playera-app`) |
| Backfill booking/session consistency dry-run | ✅ | `npm run quran-sessions:backfill-booking-session-consistency` → `0 session(s) would be updated` |
| Firestore export backup before prod apply | ⬜ | **Blocker:** manual ops |
| Sample 20 bookings post-apply | ⬜ | **Blocker:** N/A while counts are 0 |
| **Note:** `backfillLifecycleStatus.ts` has **no `--dry-run`**; it only writes when docs lack `lifecycleStatus`. This run updated 0 docs. | | |

---

## 3. App Check staging soak

| Item | Status | Evidence |
|------|--------|----------|
| Callable opt-in via `QURAN_SESSIONS_ENFORCE_APP_CHECK` | ✅ | `sessionCallableOptions.ts`; tests `isSessionAppCheckEnforced defaults to false` |
| Prod enforcement **not** forced | ✅ | Default `enforceAppCheck: false` |
| Staging phases 0–3 executed | ⬜ | **Blocker:** requires Firebase staging deploy + 16+ day soak per `app-check-staging-plan.md` |
| Error rate < 0.1% for 7 days | ⬜ | **Blocker:** ops monitoring |

**Local readiness:** set `QURAN_SESSIONS_ENFORCE_APP_CHECK=true` on staging functions deploy only after Phase 0 monitor window.

### 3a. Learn Quran App Check release gate (Spec 039 / US4)

**Owner:** ⬜ *unassigned — a named owner must be recorded here before any
staging enforcement begins.*

**Current enforcement state:** `QURAN_SESSIONS_ENFORCE_APP_CHECK` unset →
`enforceAppCheck: false` in every environment (verified by
`functions/test/quranSessions/sessionCallableOptions.test.ts`). It is a
deployment-time environment value, **not** an admin setting.

**Evidence table** — every row needs a dated PASS from attested clients in
staging (phases per `app-check-staging-plan.md`) before a production
enforcement request:

| # | Critical flow (attested client) | Callable(s) | Evidence date | Result |
|---|---|---|---|---|
| E1 | Pricing quote on booking screen | `getBookingPricingQuote` / `getBookingPricingQuotes` | ⬜ | ⬜ |
| E2 | Create + cancel booking | `createSessionBooking`, `cancelSessionBooking` | ⬜ | ⬜ |
| E3 | Join session (RTC token) | `issueSessionRtcToken` | ⬜ | ⬜ |
| E4 | File a session report | `reportSessionConcern` | ⬜ | ⬜ |
| E5 | Open a dispute | `openSessionDispute` | ⬜ | ⬜ |
| E6 | Admin report + dispute resolution | `resolveSessionReport`, `resolveSessionDispute` | ⬜ | ⬜ |
| E7 | Non-attested request is rejected | any session callable | ⬜ | ⬜ |

For E7, record the observable rejection (callable error surfaced to the
client and the corresponding Functions log entry) **without** logging request
payloads or report/dispute text.

**Success criteria (all required to promote):**

1. E1–E6 pass from attested clients in staging with the flag on.
2. E7 shows non-attested traffic rejected with an observable error.
3. Staging callable error rate < 0.1% for 7 consecutive days (per
   `app-check-staging-plan.md`).
4. Rollback rehearsed once in staging and its result recorded below.

**Rollback decision (no data mutation):** redeploy functions with
`QURAN_SESSIONS_ENFORCE_APP_CHECK` removed/`false` — enforcement is read at
deploy time, so this is config-only; booking/session data is never touched.
If any critical flow fails during the soak, roll back first, then diagnose.

| Rollback rehearsal | Date | Result |
|---|---|---|
| Staging: disable flag, redeploy, verify unattested booking succeeds | ⬜ | ⬜ |

---

## 4. Backend enforcement & tests

| Item | Status | Evidence |
|------|--------|----------|
| CF unit tests | ✅ | `cd functions && npm test` — **201/201 pass** (2026-07-03) |
| CF integration tests (emulator) | ✅ | `npm run test:integration` — **70/70 pass** |
| Free booking scheduled | ✅ | integration `free booking with a verified teacher is scheduled` |
| Child age gate | ✅ | integration `child booking succeeds when teacher accepts children` + `canTeachChildren` unit tests |
| Teacher whitelist | ✅ | integration `teacher not on whitelist is rejected` |
| Fee snapshot | ✅ | integration `fee snapshot persists and ignores later market price changes` |
| Video-only server reject non-video | ✅ | `createSessionBooking.ts` lines 206–211; platform seed `sessionMode: videoOnly` |
| Paid booking blocked while payments disabled | ✅ | integration `paid teacher cannot be booked free while payments are disabled` |
| Allowed actions on transitions | ✅ | `allowedActionsTransition.test.ts` + production flow integration |
| App launch policy / fake backend blocked in prod | ✅ | `apps/tilawa` — 13 tests pass (`quran_sessions_launch_policy_test`, `quran_sessions_backend_config_test`) |
| `packages/quran_sessions` widget/domain tests | ⚠️ | **Blocked locally:** Flutter SDK compile errors loading tests (environment); not a gate failure for CF |

---

## 5. Pre-launch verification commands

```sh
cd functions && npm test
cd functions && npm run test:integration
cd functions && npm run seed:platform-config
cd functions && npm run seed:market-configs
cd functions && npm run quran-sessions:backfill-booking-session-consistency
# Staging/prod only (ops):
cd functions && npm run seed:platform-config:apply
cd functions && npm run seed:market-configs:apply
cd apps/tilawa && flutter test test/features/quran_sessions/
```

---

## 6. OUT OF SCOPE for this launch (explicit)

Do **not** ship or depend on these in the free/video-only gate:

- **Paid booking / wallet / checkout** — payment provider not production-ready; CF blocks paid free-booking abuse in tests.
- **Admin Panel UI** — policy edits via `seedPlatformConfig` / `seedMarketConfigs` / console only (`admin-config-seed.md`).
- **Reschedule denorm** — `hasPendingReschedule` not stored on booking; reschedule repo still queries legacy `status` on reschedule requests.
- **Voice call exposure in UI** — server enforces `videoOnly`; some client launch-policy paths may still hint voice (see `remaining-risks.md` R2).
- **External meeting links in UI** — hidden on teacher profile when `videoOnly`; booking UI alignment incomplete.

---

## 7. Remaining risks (unchanged priorities)

1. **Paid booking** — not in this launch.
2. **Admin Panel UI** — manual seeds until UI ships.
3. **Lifecycle backfill** — live scan shows 0 gaps on `quran-playera-app`; re-run before dropping legacy `status`.
4. **App Check** — prod enforcement after staging soak.
5. **Reschedule `hasPendingReschedule` denorm** — not stored.
6. **Legacy projects** — booking fails closed until platform + market seeds applied (`policy_not_configured`).

---

## 8. Launch sequence (ops)

1. Staging: `seed:platform-config:apply` + `seed:market-configs:apply` (pilot **EG**; enable whitelist teachers if soft launch).
2. Verify booking succeeds; omit required field → `policy_not_configured`.
3. Re-run backfill scripts; confirm 0 pending updates or apply if counts > 0.
4. Deploy Cloud Functions + mobile to staging.
5. App Check staging soak (`app-check-staging-plan.md`) → prod enforce when metrics green.
6. Production: repeat seeds; monitor booking errors and `policy_not_configured`.

---

## Seed summary (dry-run values)

### Platform — `quran_session_platform_config/global`

| Field | Value |
|-------|-------|
| `quranTutorBookingMode` | `requiresTutorApproval` |
| `sessionMode` | `videoOnly` |
| `enabledCallProviders` | `["mock", "agora"]` |
| `childAgeThreshold` | `14` |
| `genderMatchingEnabled` | `true` |
| `globalAllowMaleTeacherFemaleStudent` | `true` |
| `globalAllowFemaleTeacherMaleStudent` | `true` |

### Market — `quran_session_market_configs/EG` (from seed JSON)

| Field | Value |
|-------|-------|
| `isEnabled` | `true` |
| `minSessionPrice` | `100` |
| `currencyCode` | `EGP` |
| `defaultCityId` | `cairo` |
| Cities enabled | cairo, alexandria, giza, mansoura, tanta, minya, assiut, sohag, aswan, luxor |


---

## 9. Post-apply verification (staging — 2026-07-03)

Full report: [`staging-post-apply-verification.md`](staging-post-apply-verification.md) (second pass after platform seed apply).

| Check | Status |
|-------|--------|
| CF unit + integration tests | ✅ 201 + 70 pass (second pass) |
| Live Firestore market configs (EG, SA, AE) | ✅ Present; EG/SA/AE validate for booking |
| Live Firestore platform config vs seed | ✅ **Aligned** — `videoOnly`, `requiresTutorApproval`, `mock`+`agora`, threshold 14 |
| Backfill booking/session consistency | ✅ 0 updates dry-run |
| Launch policy + fake backend + nav tests | ✅ 18/18 |
| Device QA checklist | ⬜ **READY** — manual D1–D8; see verification doc |
| **Staging sign-off** | **STAGING VERIFIED** (automated + live config); device QA pending |

