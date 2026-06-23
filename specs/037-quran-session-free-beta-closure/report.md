# Sprint 037 — Free Beta Staging Closure

**Date:** 2026-06-23  
**Sprint goal:** Close Phase 0 Free Beta gates — deploy wallet CF + rules, run smoke, update docs/checklists.  
**Constraints:** Paid sessions OFF; no Phase 2 PSP; fix smoke P0 only.

---

## 1. Deploy status

| Target | Command | Result |
|--------|---------|--------|
| Build | `cd functions && npm run build` | ✅ Pass |
| Wallet CF | `firebase deploy --only functions:getWallet,functions:postWalletCredit` | ✅ **Deployed** — new 2nd-gen functions in `us-central1` |
| Firestore rules | `firebase deploy --only firestore:rules,firestore:indexes` | ✅ **Deployed** — rules released; indexes synced (1 orphan index in project not in file — left as-is) |

**Project:** `quran-playera-app`

**Note:** Full session CF set was already on staging from prior sprints. This sprint deployed **wallet** callables only (+ rules/indexes refresh).

---

## 2. Smoke results

```sh
cd functions && npm run quran-sessions:staging-smoke
```

| Result | Detail |
|--------|--------|
| **12/12 PASS** | All Free Beta backend gates green |

| # | Check | Status |
|---|-------|--------|
| 1 | Student can book free session | ✅ |
| 2 | Duplicate booking replay idempotent | ✅ |
| 3 | Different user cannot book same slot | ✅ |
| 4 | Student can cancel with reason | ✅ |
| 5 | Teacher can cancel with reason | ✅ |
| 6 | No-show classification works | ✅ |
| 7 | Dispute can be opened | ✅ |
| 8 | Dispute resolution creates manual_pending refund ledger | ✅ |
| 9 | Unauthorized actor rejected | ✅ |
| 10 | Reports can be filed and resolved | ✅ |
| 11 | No paid booking exposed (`payment_provider_unavailable`) | ✅ |
| 12 | Duplicate refund safe | ✅ |

---

## 3. Manual E2E checklist (user action required)

**Agent cannot run device/admin UI E2E.** Execute `specs/035-quran-session-staging-validation-sprint/manual-e2e-runbook.md` (16 steps).

| # | Step | Status |
|---|------|--------|
| 1–3 | Admin approve teacher; teacher profile + availability | ⬜ User |
| 4 | Staging flags — no paid checkout | ⬜ User (code default ✅) |
| 5–11 | Student profile → book → join meeting | ⬜ User |
| 12–13 | Report + dispute from mobile | ⬜ User |
| 14–15 | Admin reports + disputes queues | ⬜ User |
| 16 | Paid path blocked/hidden | ⬜ User |

**Recorder:** _______________ **Date:** _______________

---

## 4. Wallet checks W1–W4 (user action required)

| # | Actor | Action | Status |
|---|-------|--------|--------|
| W1 | Admin | `postWalletCredit` for test student uid | ⬜ User — CF deployed, callable ready |
| W2 | Student | Open `/sessions/wallet` | ⬜ User |
| W3 | Admin | `/quran-sessions/wallets/{studentUid}` | ⬜ User |
| W4 | Security | Client Firestore write to `user_wallets` | ⬜ User — rules deployed |

Deploy verification steps: see runbook §Verify wallet deploy.

---

## 5. What was fixed vs deferred

| Item | Action |
|------|--------|
| Wallet CF deploy (`getWallet`, `postWalletCredit`) | ✅ Deployed this sprint |
| Firestore rules + indexes | ✅ Deployed this sprint |
| Smoke 12/12 | ✅ Pass |
| `I18nService` ARB load failure → empty translations, app boots | ✅ Fixed (`apps/tilawa_admin/src/app/core/i18n/i18n.service.ts`) |
| Manual 16-step E2E | ⏸ Deferred — user |
| Wallet W1–W4 | ⏸ Deferred — user |
| Paid sessions / PSP | ❌ Not started (by design) |
| Dispute resolution admin UI | ⏸ Deferred — financial risk |
| Play Internal AAB upload | ⏸ Deferred — user |

---

## 6. Go / No-Go

| Gate | Verdict |
|------|---------|
| Backend automated smoke | **GO** — 12/12 |
| Wallet CF + rules on staging | **GO** — deployed |
| Admin i18n boot resilience | **GO** — ARB failure no longer white-screens |
| Manual 16-step E2E | **NO-GO** — not run |
| Wallet W1–W4 | **NO-GO** — not run |
| **Play Internal upload** | **NO-GO** — complete manual E2E + W1–W4 first |

**Smallest path to Play Internal GO:**
1. `cd functions && npm run seed:staging-teachers:apply` (if teachers not seeded)
2. One full 16-step manual pass (student + teacher devices + admin)
3. Wallet W1–W4 on staging
4. Build signed AAB + version bump

---

## 7. Verification run this sprint

```sh
cd functions && npm run build                              # ✅
firebase deploy --only functions:getWallet,functions:postWalletCredit  # ✅
firebase deploy --only firestore:rules,firestore:indexes   # ✅
cd functions && npm run quran-sessions:staging-smoke       # ✅ 12/12
cd apps/tilawa_admin && npm run build                      # ✅ (after i18n hardening)
```

---

## 8. User action list

1. Run **16-step manual E2E** — `specs/035-quran-session-staging-validation-sprint/manual-e2e-runbook.md`
2. Run **W1–W4 wallet checks** — same runbook §Phase 1 wallet checks
3. Confirm **seeded teachers** — `npm run seed:staging-teachers:apply` if browse step fails
4. **Sign off** runbook tables → re-evaluate Play Internal GO
5. Optional: test `postWalletCredit` via Firebase Console → Functions → `postWalletCredit` (admin auth)

---

## Rollback / feature-disable

Unchanged from sprint 035 — see `specs/035-quran-session-staging-validation-sprint/report.md` §Rollback.

| Action | Command / flag |
|--------|----------------|
| Disable student booking | `--dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=false` |
| Disable paid (already off) | `QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED=false` |
| Revert wallet CF | Firebase Console → delete `getWallet` / `postWalletCredit` or redeploy prior release |
