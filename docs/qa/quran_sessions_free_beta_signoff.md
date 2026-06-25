# Quran Sessions Free Beta — Master QA Sign-off

**Milestone:** `037-quran-session-free-beta-closure`  
**Scope:** Individual 1:1 booking (external + mock voice/video), single-active-device.  
No wallet, paid booking, group sessions, or in-app Agora/WebRTC.

**Engineering verdict:** Conditional Go — see [experimental production readiness report](../../specs/037-quran-session-free-beta-closure/experimental-production-readiness-report.md).

---

## Runbooks

| Area | Runbook |
|------|---------|
| **Production manual QA (10 sections)** | [quran_sessions_production_manual_qa.md](./quran_sessions_production_manual_qa.md) |
| Individual booking (B1–B5) | [individual_booking_qa.md](./individual_booking_qa.md) |
| Single active device (T2/T5/T6/T7/T8) | [single_active_device_qa.md](./single_active_device_qa.md) |
| Play internal upload | [quran_sessions_play_internal.md](../release/quran_sessions_play_internal.md) |
| Gate status (engineering) | [production_readiness_status.md](../quran_sessions/production_readiness_status.md) |

---

## Combined sign-off table

Complete **both** runbooks on **staging Firebase** (`quran-playera-app` or team staging project) with a build that has booking enabled (see tester instructions below).

| ID | Scenario | Runbook | Tester | Date | Pass |
|----|----------|---------|--------|------|------|
| B1 | Student external booking + join link | [B1](./individual_booking_qa.md#b1--student-external-meeting-booking) | | | ⬜ |
| B2 | Student mock voice/video join | [B2](./individual_booking_qa.md#b2--student-mock-voicevideo-when-enabled) | | | ⬜ |
| B3 | Teacher sees upcoming session | [B3](./individual_booking_qa.md#b3--teacher-upcoming-session) | | | ⬜ |
| B4 | Idempotency / double-tap confirm | [B4](./individual_booking_qa.md#b4--idempotency--double-tap-confirm) | | | ⬜ |
| B5 | Stale device blocked on booking | [B5](./individual_booking_qa.md#b5--stale-device-blocked-on-booking) | | | ⬜ |
| T2 | Login second device revokes first | [T2](./single_active_device_qa.md#t2--login-second-device) | | | ⬜ |
| T5 | Offline A signs out on resume after B login | [T5](./single_active_device_qa.md#t5--a-offline-at-b-login) | | | ⬜ |
| T6 | Stale device cannot complete booking | [T6](./single_active_device_qa.md#t6--a-mid-session-booking) | | | ⬜ |
| T7 | Teacher approval push to active device only | [T7](./single_active_device_qa.md#t7--teacher-approval-push) | | | ⬜ |
| T8 | Re-login same device after B logout | [T8](./single_active_device_qa.md#t8--re-login-same-device-after-b-logout) | | | ⬜ |

**Recorder:** _______________

**Notes / defects:** _______________

---

## Go / No-Go — Play internal upload

| Gate | Required | Status |
|------|----------|--------|
| B1–B5 pass on staging | Yes | ⬜ |
| T2/T5/T6/T7/T8 pass (two devices) | Yes | ⬜ |
| `scripts/quran_sessions_preflight.sh` green (or CI equivalent) | Yes | ⬜ — CI job `quran-sessions-preflight` wired; requires GitHub billing fix to run |
| External + mock only — no Agora/WebRTC SDK in binary | Yes | ⬜ |
| No wallet / paid / group regressions observed | Yes | ⬜ |
| Privacy policy covers third-party meeting links | Legal verify | ⬜ |
| Rollback owner assigned | Yes | ⬜ |

**Verdict:** ⬜ **Go** for Play **internal** upload &nbsp;|&nbsp; ⬜ **No-Go**

Signed: _______________ &nbsp; Date: _______________

---

## Tester cohort instructions

### Build requirements

1. Install build from Play **internal** or **closed** track (or Firebase App Distribution pre-Play smoke).
2. Build must target **staging Firebase** (`google-services.json` for staging project — confirm with release owner).
3. Booking must be **on** for testers:
   - Play tracks `internal` / `alpha` / `beta`: `TILAWA_DISTRIBUTION=play_<track>` defaults booking **on** (`distribution != play_production`).
   - Play **production** track or explicit kill-switch: pass  
     `--dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true` at build time.
4. Do **not** enable `TILAWA_LAUNCH_QURAN_SESSIONS_PAID_BOOKING_SANDBOX_ENABLED` for Free Beta.

### Accounts & data

- Use **staging** test student + verified teacher accounts (complete profiles, meeting link on teacher).
- Enable push notifications on both devices for T2/T7.
- Confirm `quran_session_platform_config/global` has `enabledCallProviders` including `external` (and `mock` if testing B2).

### What testers exercise

- B1–B5: book, join, teacher view, double-tap, stale device on booking.
- T2/T5/T6/T7/T8: two-device session revocation (see [single_active_device_qa.md](./single_active_device_qa.md)).

### Report defects

- File with repro steps, build number, account role (student/teacher), and scenario ID (B* / T*).

---

## Rollback checklist

Execute in order if critical defect found post-upload.

| Step | Action | Owner |
|------|--------|-------|
| 1 | **Kill booking UI** — ship or hotfix build with `--dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=false` OR use `play_production` distribution stamp | Release |
| 2 | **Firestore** — set `quran_session_platform_config/global.enabledCallProviders` to `["external"]` only (removes mock server-side) | Ops |
| 3 | **Play Console** — halt closed/open rollout; keep internal track for fix verification only | Release |
| 4 | **Notify cohort** — booking paused; existing sessions handled per support runbook | Ops |
| 5 | **Postmortem** within 48h — root cause, whether to re-enable flag | Eng + product |

Full flag table: [readiness report §19](../../specs/037-quran-session-free-beta-closure/experimental-production-readiness-report.md#19-free-beta-gono-go).

---

## Automated preflight (before manual QA)

```sh
./scripts/quran_sessions_preflight.sh
```

Or run the individual commands listed in [individual_booking_qa.md § Automated coverage](./individual_booking_qa.md#automated-coverage-ci--local) and [single_active_device_qa.md § Automated coverage](./single_active_device_qa.md#automated-coverage-ci--local).
