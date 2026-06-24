# Quran Sessions — Production Manual QA Checklist

**Scope:** Stable production v1 — individual 1:1 free booking (external + mock), single-active-device.  
**Out of scope:** paid booking, wallet checkout, group sessions, in-app Agora/WebRTC rollout.

**Prerequisites:** Staging Firebase (`quran-playera-app` or team staging), **release build** (debug skips App Check — invalid for CF enforcement smoke).  
**Sign-off table:** Record pass/fail in [quran_sessions_free_beta_signoff.md](./quran_sessions_free_beta_signoff.md).

---

## 1. Build & environment

- [ ] Install build from Play internal/closed track, Firebase App Distribution, or local release APK
- [ ] Confirm `google-services.json` targets **staging** project (release owner)
- [ ] Booking enabled: `TILAWA_DISTRIBUTION=play_<track>` (non-production) **or** explicit  
      `--dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true`
- [ ] Providers locked to stable scope:  
      `--dart-define=TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=external,mock`
- [ ] Paid/wallet sandbox **off**: do **not** set `TILAWA_LAUNCH_QURAN_SESSIONS_PAID_BOOKING_SANDBOX_ENABLED`
- [ ] `./scripts/quran_sessions_preflight.sh` green locally or CI `quran-sessions-preflight` job green

### Release build command (staging smoke)

```sh
cd apps/tilawa
flutter build apk --release \
  --dart-define=TILAWA_DISTRIBUTION=staging \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=external,mock
```

---

## 2. Student booking (B1–B5)

Reference: [individual_booking_qa.md](./individual_booking_qa.md)

- [ ] **B1** — Book external session; join link opens external browser after confirmation sheet
- [ ] **B2** — Mock voice/video join works when mock enabled in Firestore `enabledCallProviders`
- [ ] **B3** — Teacher sees upcoming session on dashboard
- [ ] **B4** — Double-tap confirm does not create duplicate booking
- [ ] **B5** — Stale device blocked on booking (epoch / single-active-device)

| ID | Tester | Date | Pass |
|----|--------|------|------|
| B1 | | | ⬜ |
| B2 | | | ⬜ |
| B3 | | | ⬜ |
| B4 | | | ⬜ |
| B5 | | | ⬜ |

---

## 3. Single active device (T2/T5/T6/T7/T8)

Reference: [single_active_device_qa.md](./single_active_device_qa.md)

Requires **two physical devices** (or one device + emulator) with push enabled for T7.

- [ ] **T2** — Login on device B revokes device A
- [ ] **T5** — Device A offline at B login; A signs out on resume
- [ ] **T6** — Stale device A cannot complete booking mid-flow
- [ ] **T7** — Teacher approval push delivered to active device only
- [ ] **T8** — Re-login same device after B logout restores access

| ID | Tester | Date | Pass |
|----|--------|------|------|
| T2 | | | ⬜ |
| T5 | | | ⬜ |
| T6 | | | ⬜ |
| T7 | | | ⬜ |
| T8 | | | ⬜ |

---

## 4. Teacher onboarding & dashboard

- [ ] Student applies as teacher → admin approves → teacher reaches dashboard without kill-app
- [ ] Settings teacher row updates after approval (no view-status loop)
- [ ] Teacher sets weekly availability + external meeting URL
- [ ] Teacher sees upcoming session; external join works
- [ ] Suspended teacher blocked from dashboard

---

## 5. Reschedule, cancel, report, dispute

- [ ] Student requests reschedule → counterparty accepts → requester sees updated time (pull-to-refresh or app resume)
- [ ] Cancel inside policy window succeeds
- [ ] Report session concern (20+ chars) succeeds
- [ ] Open dispute; admin can triage in tilawa_admin

---

## 6. Kill switches & scope guards

- [ ] `TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED=false` → sessions routes redirect home; home footer entry hidden
- [ ] `TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=false` → book CTAs hidden / booking route redirects
- [ ] Wallet nav **not visible** on sessions home (stable production default)
- [ ] Paid booking attempt rejected server-side (if accidentally enabled in staging data)

---

## 7. App Check (staging only)

Reference: [app_check_staging_verification.md](../quran_sessions/app_check_staging_verification.md)

- [ ] Release build obtains App Check token (not debug)
- [ ] Before ops flip: session CFs work without enforcement
- [ ] After ops sets `QURAN_SESSIONS_ENFORCE_APP_CHECK=true` + redeploy: release build still completes booking/join
- [ ] Rollback documented if enforcement breaks clients

---

## 8. Admin ops smoke

- [ ] Teacher applications queue — approve/reject
- [ ] Sessions list readable; session detail opens
- [ ] Reports queue — filter/search
- [ ] Disputes queue — open detail; resolve via session detail CF
- [ ] Wallet admin nav **hidden** in production admin build (`quranSessionsWalletEnabled: false`)

---

## 9. Regression — out-of-scope paths blocked

- [ ] Group booking rejected by CF (`group_booking_not_supported`)
- [ ] Paid teacher cannot be booked free while payments disabled
- [ ] No Agora/WebRTC SDK required for stable external+mock path
- [ ] No wallet checkout UI in production-scoped app build

---

## 10. Go / No-Go recording

- [ ] All B1–B5 and T2/T5/T6/T7/T8 marked pass in [sign-off table](./quran_sessions_free_beta_signoff.md)
- [ ] Preflight / CI green
- [ ] Privacy policy covers third-party meeting links (legal)
- [ ] Rollback owner assigned
- [ ] Verdict recorded in [production_readiness_status.md](../quran_sessions/production_readiness_status.md)

**Recorder:** _______________  
**Notes / defects:** _______________
