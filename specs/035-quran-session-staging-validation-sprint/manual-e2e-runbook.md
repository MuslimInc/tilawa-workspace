# Manual E2E Runbook — Free Beta (16 steps)

**Sprint:** 035 / Phase 0  
**Project:** `quran-playera-app` (staging)  
**Paid sessions:** OFF — `QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED` must stay `false`

Use this runbook before Phase 2 PSP work. Record pass/fail per step in your QA sheet.

---

## Prerequisites

| Item | How to verify |
|------|----------------|
| Admin account | Firebase Auth user with `admin: true` custom claim |
| Student test account | Signed-in on physical device or emulator (staging build) |
| Teacher test account | Separate device or profile; approved + verified |
| Seeded teachers | `staging_teacher_01`–`05` in Firestore (see §Seed below) |
| Admin web | `cd apps/tilawa_admin && npm start` → local admin |
| Mobile app | Staging flavor (`TILAWA_DISTRIBUTION != play_production`) |

### Seed staging teachers

```sh
cd functions
npm run seed:staging-teachers          # dry-run
npm run seed:staging-teachers:apply    # writes to Firestore
```

**Blocker (if apply fails):** Missing `GOOGLE_APPLICATION_CREDENTIALS` or Firebase Admin access. Fix ADC (`gcloud auth application-default login`) or service account JSON, then re-run apply.

**Phase 1 note (2026-06-23):** `seed:staging-teachers:apply` succeeded — 5 teachers written.

### Deploy (when CF/rules changed)

```sh
cd functions && npm run build
firebase deploy --only functions:getWallet,functions:postWalletCredit,functions:createSessionBooking,functions:cancelSessionBooking,functions:requestSessionReschedule,functions:confirmSessionReschedule,functions:markSessionNoShow,functions:completeSession,functions:issueSessionCompensation,functions:approveSessionRefund,functions:openSessionDispute,functions:resolveSessionDispute,functions:reportSessionConcern,functions:resolveSessionReport,functions:expirePendingReservations
firebase deploy --only firestore:rules,firestore:indexes
```

### Verify wallet deploy (after CF deploy)

| Check | How | Expected |
|-------|-----|----------|
| Functions exist | `firebase functions:list` → filter `getWallet`, `postWalletCredit` | Both in `us-central1`, status Active |
| getWallet | Firebase Console → Functions → `getWallet` → Test (student auth uid) | `{ balanceUsd, transactions[] }` or empty wallet |
| postWalletCredit | Console test with **admin** custom claim | Wallet doc + `wallet_transactions` entry |
| Rules deny client write | Firestore rules simulator: student write `user_wallets/{uid}` | **Denied** |

**Phase 1 note (2026-06-23):** `getWallet` + `postWalletCredit` deployed to `quran-playera-app`; smoke 12/12; rules/indexes deployed.

---

## Admin URLs (local default `http://localhost:4200`)

| Screen | URL |
|--------|-----|
| Login | `/login` |
| Teacher applications | `/quran-sessions/teacher-applications` |
| Teachers | `/quran-sessions/teachers` |
| Sessions | `/quran-sessions/sessions` |
| Session detail | `/quran-sessions/sessions/{bookingId}` |
| Reports | `/quran-sessions/reports` |
| Report detail | `/quran-sessions/reports/{reportId}` |
| Disputes | `/quran-sessions/disputes` |
| Dispute detail | `/quran-sessions/disputes/{disputeId}` |
| User wallet (read-only) | `/quran-sessions/wallets` or `/quran-sessions/wallets/{userId}` |

---

## Mobile routes (Quran Sessions)

| Screen | Path |
|--------|------|
| Home | `/sessions` |
| Teacher list | `/sessions/teachers` |
| Book | `/sessions/teachers/{teacherId}/book` |
| My sessions | `/sessions/my` |
| Wallet (read-only) | `/sessions/wallet` |
| Session detail | `/sessions/detail/{bookingId}` |

---

## 16-step manual loop

| # | Actor | Action | Expected outcome |
|---|-------|--------|------------------|
| 1 | Admin | Open teacher applications → approve one pending application | Application status `approved`; teacher profile created/visible |
| 2 | Teacher | Sign in → complete public profile (bio, photo, meeting URL) | Profile `verified` + publicly visible fields saved |
| 3 | Teacher | Open weekly availability → save at least one bookable slot | Availability config saved; generated slots appear in editor |
| 4 | QA | Confirm staging flags | Booking + teacher apply enabled; **no paid checkout UI** |
| 5 | Student | Complete Quran Sessions profile (country, city, gender, DOB) | `profileCompleted` true; can browse teachers |
| 6 | Student | Browse teacher list | ≥5 verified teachers visible (`staging_teacher_01`–`05` if seeded) |
| 7 | Student | Book **free** session on available slot | Booking succeeds; lifecycle `scheduled` (or equivalent) |
| 8 | Student | Open My Sessions | New booking listed with correct time/teacher |
| 9 | Teacher | Open teacher dashboard | Same session listed for teacher |
| 10 | Student | Open session detail | Join CTA visible; meeting link shown |
| 11 | Student | Tap Join | External meeting URL opens (browser/app) |
| 12 | Student | Report concern from session detail | Report created; success toast |
| 13 | Student | Open dispute sheet → submit | Dispute doc created with `open` status |
| 14 | Admin | Reports queue → open report | Report visible; status/filter works |
| 15 | Admin | Disputes queue → open dispute | Dispute detail read-only; link to booking works |
| 16 | QA | Attempt paid booking path | **Must fail or be hidden** — `payment_provider_unavailable`; no card UI |

---

## Phase 1 wallet checks (optional add-on)

| # | Actor | Action | Expected |
|---|-------|--------|----------|
| W1 | Admin | `postWalletCredit` callable (Firebase console / script) with test student uid | Wallet doc + transaction created |
| W2 | Student | Open `/sessions/wallet` | Balance + transaction list (read-only) |
| W3 | Admin | `/quran-sessions/wallets/{studentUid}` | Same data as mobile |
| W4 | Security | Client Firestore write to `user_wallets` | **Denied** |

---

## Sign-off

| Gate | Required for Phase 1 GO |
|------|-------------------------|
| Steps 1–16 all Pass | Free Beta manual E2E |
| Smoke 12/12 | `cd functions && npm run quran-sessions:staging-smoke` |
| Paid still OFF | Env + mobile flags |
| Wallet W1–W4 (staging) | After CF deploy |

**Recorder:** _______________ **Date:** _______________
