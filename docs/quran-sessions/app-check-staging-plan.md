# Quran Sessions — App Check Staging Soak Plan

**Last updated:** 2026-07-03

---

## Scope

Enforce App Check on Quran Sessions callables after staging soak:

- `createSessionBooking`, `cancelSessionBooking`, `respondToBookingRequest`
- `issueSessionRtcToken`, `completeSession`, `markSessionNoShow`
- Payment + dispute callables

Config: `functions/src/quranSessions/sessionCallableOptions.ts`

---

## Staging phases

| Phase | Action | Duration |
|-------|--------|----------|
| 0 | Monitor only (log failures, do not block) | 3 days |
| 1 | Enforce token issue in staging | 3 days |
| 2 | Enforce booking + cancel in staging | 5 days |
| 3 | Enforce all session callables in staging | 5 days |
| 4 | Production enforce (one release) | — |

Do **not** enforce in production until staging error rate < 0.1% for 7 days.

---

## Rollback

1. Disable enforce in `sessionCallableHttpsOptions`; redeploy functions.
2. Confirm bookings succeed without attestation.
3. Use Firebase debug tokens for simulators (staging/dev only).

---

## Success criteria

- [ ] Staging soak with no booking failure spike
- [ ] Support runbook includes App Check debug steps
- [ ] Rollback is config-only (no data migration)

---

## Local gate verification (2026-07-03)

- [x] `isSessionAppCheckEnforced()` false when env unset — unit tests pass.
- [x] Stable session callables use `sessionCallableHttpsOptions` — unit tests pass.
- [x] Wallet/payment callables excluded from shared App Check options — unit test pass.
- [ ] Staging Phase 0–3 soak — **not started** (manual ops + calendar time).
- [ ] Production enforce — **intentionally not enabled** in this gate.

**Staging enable command (ops only):** deploy functions with `QURAN_SESSIONS_ENFORCE_APP_CHECK=true`, monitor callable failure metrics, rollback by redeploying without the flag.
