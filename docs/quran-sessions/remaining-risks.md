# Quran Sessions — Remaining Risks

**Requires product / ops approval before production Go**  
**Last updated:** 2026-07-03

---

## R1 — Unresolved booking confirmation mode (P0)

**Risk:** Staging uses auto-confirm; production hint uses tutor approval — untested E2E on production defaults.  
**Impact:** Wrong student expectations, slot locks without teacher capacity, support volume.  
**Mitigation:** Answer Q-BK-01, Q-BK-02; Maestro two-device sign-off (T2–T8).  
**Owner:** Product

---

## R2 — Video-only not enforced (P0)

**Risk:** Voice and external meeting still in booking UI and launch policy; contradicts production intent.  
**Impact:** Privacy (external links), inconsistent call quality, Play policy review.  
**Mitigation:** Answer Q-VC-01; wire `SessionModePolicy.videoOnly`; **teacher profile external URL hidden when `videoOnly` (2026-07-03)**; booking UI still needs launch-policy alignment.  
**Owner:** Product + Engineering

---

## R3 — Dual status field drift (P0)

**Risk:** Legacy `status` without `lifecycleStatus` mis-classifies sessions in lists and join eligibility.  
**Impact:** Cancelled sessions in Upcoming; wrong no-show type (`noShow` → `bothNoShow`).  
**Mitigation:** Backfill script (`lifecycle-backfill-checklist.md`); dual-write period; **allowed actions recomputed on every lifecycle transition (2026-07-03)**.  
**Owner:** Engineering

---

## R4 — Fees hardcoded or client-only (P0)

**Risk:** Egypt manual payment pilot bypasses engine; client may show prices not confirmed by server.  
**Impact:** Payment disputes, regulatory exposure, teacher payout errors.  
**Mitigation:** Answer Q-FE-01, Q-AD-03; admin panel price config; server quote on booking.  
**Owner:** Product + Finance

---

## R5 — Admin policy editor missing (P1)

**Risk:** Business rules documented but changed only via Firestore console — human error, no audit.  
**Impact:** Wrong refund/cancel behavior in production without code deploy.  
**Mitigation:** Versioned policy docs + admin UI or GitOps (Q-AD-01).  
**Owner:** Ops + Engineering

---

## R6 — Manual QA unsigned (P0 ops)

**Risk:** Engineering gates green; user flows unverified on staging devices.  
**Impact:** Production incidents on first real users.  
**Mitigation:** Complete B1–B5, T2–T8 in `docs/qa/quran_sessions_free_beta_signoff.md`.  
**Owner:** QA

---

## R7 — App Check off by default (P1)

**Risk:** Callable abuse without App Check attestation.  
**Impact:** Booking spam, cost, data integrity.  
**Mitigation:** Staging flip + monitor; enable before wide rollout (Q-SR-01).  
**Owner:** Ops

---

## R8 — Fake MVP accidental wiring (P1)

**Risk:** Release build with `TILAWA_QURAN_SESSIONS_BACKEND=fake` shows fake data.  
**Impact:** App Store rejection, user trust loss.  
**Mitigation:** Assert firebase mode in release CI; document non-production banner on MVP module.  
**Owner:** Engineering

---

## R9 — Disputes / reports ops blind spot (P1)

**Risk:** CF supports dispute/report; admin UI queues missing.  
**Impact:** Safety issues unresolved, legal exposure.  
**Mitigation:** Admin queue MVP or manual Firestore ops runbook until UI ships.  
**Owner:** Ops + Product

---

## R10 — RTC provider not in production binary (P1)

**Risk:** Prod ships `external,mock` — no real in-app video despite product direction.  
**Impact:** Feature gap at launch or forced external links.  
**Mitigation:** Answer Q-VC-02; certify LiveKit/Agora path; update `configure_rtc_deps.dart`.  
**Owner:** Engineering

---

## Sign-off gate

| Risk IDs | Required for unrestricted production |
|----------|--------------------------------------|
| R1, R2, R3, R4, R6 | **Yes** |
| R5, R7, R8, R9, R10 | Staging / closed beta acceptable with runbooks |

**Current recommendation:** **No-Go** for paid + video-only production until R1–R4 and R6 closed. Conditional Go for closed beta with external/mock calls if product explicitly accepts Free Beta continuation.

---

## Post-launch scope boundary (free / video-only gate — 2026-07-03)

**Explicitly OUT OF SCOPE** for the limited rollout gated by this checklist:

| Area | Notes |
|------|-------|
| Paid booking / wallet | CF tests block paid-as-free; no checkout launch |
| Admin Panel UI | Seeds via `functions/scripts/seedPlatformConfig.ts` + `seedMarketConfigs.ts` |
| Reschedule `hasPendingReschedule` denorm | Not on booking aggregate |
| Voice in booking UI | Server `videoOnly` rejects non-`videoCall`; client policy may still expose hints |
| External meeting URL in UI | Profile hides URL when `videoOnly`; full booking UI alignment pending (R2) |

