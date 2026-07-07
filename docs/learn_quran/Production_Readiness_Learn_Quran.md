# Production Readiness — Learn Quran (Quran Sessions)

**Scope:** Free 1:1 **video-only** beta, admin-controlled. Paid/wallet, group
sessions, and in-app Agora/WebRTC are out of scope by design.

**Date:** 2026-07-08
**Overall (evidence-based): ~82%**

## Verdict

- **Engineering / code: READY WITH NON-BLOCKING FOLLOW-UP** — verified
  (analyze clean; all targeted + package + backend + admin suites green).
- **Production go-live (flip on for real users): NOT READY today** — gated on
  ops / QA / legal actions that are outside the codebase and **not verified here**.

Per instruction, nothing is marked complete without code/test evidence. The
manual gates below are explicitly **unverified** (I cannot execute them).

---

## Completion by area

| Area | Completion | Verdict |
|------|-----------|---------|
| Student App | ~92% | READY (+follow-ups) |
| Tutor App | ~85% | READY (+follow-ups) |
| Admin Panel | ~90% | READY (+follow-ups) |
| Backend / CF | ~90% | READY (+follow-ups) |
| **Overall production readiness** | **~82%** | **Blocked on ops/QA/legal** |

---

## Automated verification (evidence, this pass)

| Suite | Result |
|-------|--------|
| `packages/quran_sessions` full suite | **1205 passed / 2 skipped** |
| `packages/quran_sessions` analyze | **No issues** |
| App changed tests (home/visibility/cubits) | **32 passed** |
| App touched-file analyze | **No issues** |
| `functions` unit suite | **388 passed / 0 failed** (+3 new) |
| Admin Vitest | **164 passed / 35 files** |
| Admin production build (`ng build`) | **Clean** |

---

## Launch blockers (ops / QA / legal — unverified)

- [ ] **Deploy** Quran Sessions callables to the target Firebase project,
      including the updated `updatePlatformConfig` (tutor-entry writes),
      `createSessionBooking`, `registerActiveDevice`.
- [ ] **Seed** ≥1 verified teacher with schedule + external meeting link.
- [ ] **App Check** enforcement flip on the target project (runbook).
- [ ] **Manual QA sign-off:** B1–B5 (booking) + T2/T5/T6/T7/T8 (two-device)
      per `docs/qa/quran_sessions_free_beta_signoff.md`.
- [ ] **Privacy policy** covering third-party (external) meeting links (legal).
- [ ] **CI billing** fix so `pr-checks` / `quran-sessions-preflight` actually run
      (jobs currently fail in ~3s on billing, not YAML).

## Non-blocking follow-ups

- Batch `getBookingPricingQuotes(teacherIds[])` to remove the teacher-list N+1
  before large-market rollout.
- FCM booking-confirmation + 24h/1h reminder notifications.
- Pull-to-refresh (My Sessions), teacher avatar upload, review-history.
- Inline live-bookability chip in the admin teacher-pricing panel (inspector is
  already authoritative).

## Rollout configuration (all admin-driven — no dart-defines)

To turn the beta on for users, set in Admin → Global Settings:
`quranSessionsEnabled=true`, `studentEntryEnabled=true`, `bookingEnabled=true`,
`sessionMode=videoOnly`; tutor entry via the new tutor-entry toggles as desired.
Payment provider stays off → paid teachers are automatically hidden as
non-bookable; only free teachers are shown/bookable.

## Kill switches

- Admin `quranSessionsEnabled=false` → app hides entry / redirects `/sessions/*`.
- Admin `bookingEnabled=false` → booking CTAs off, route redirect.
- Config fails **closed** (`safeFallback`) when no admin config is present.
