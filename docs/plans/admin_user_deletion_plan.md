# Admin-Initiated User Deletion — Implementation Plan

Status: **planned** (no code yet)
Scope: Firebase Auth + Firestore only (this project uses no Realtime Database
and no Cloud Storage — verified against `apps/`, `packages/`, and
`functions/src`).
Initiator: **tilawa-admin panel only**, gated on the `admin` custom claim
(same gate as `moderateQuranSessionsUser` and `firestore.rules` `isAdmin()`).

Model: **two-stage deletion** — immediate soft delete (lockout + grace
period), scheduled hard purge with explicit per-collection handling.
**No UID-discovery deletion**: every collection is handled by name from the
manifest below; anything not listed is untouched by design.

---

## 1. Firestore data inventory

Every collection in `firestore.rules`, classified by relationship to a user
account. `uid` = Firebase Auth uid; `teacherProfileId` = doc id in
`quran_teacher_profiles` (its `userId` field points back to the uid).

### User-owned (keyed by or scoped to a single uid)

| Path | Keyed by | Notes |
|---|---|---|
| `users/{uid}` | uid | Profile root: email, `quranSessionsProfile` (gender, DOB, country, city, guardianId, role, accountStatus, restrictionReason), session/notification prefs, active-device fields (written by `registerActiveDevice`) |
| `users/{uid}/fcm_tokens/{tokenId}` | uid | Push tokens |
| `users/{uid}/favorites/{doc}/items/{itemId}` | uid | Personal favorites |
| `users/{uid}/premium/{docId}` | uid | Premium flags |
| `users/{uid}/purchases/{purchaseId}` | uid | Client-created purchase records (Play Billing) |
| `users/{uid}/cancellations/{cancellationId}` | uid | Purchase cancellations |
| `user_wallets/{walletId}` | `userId` field | Wallet balance doc |
| `quran_teacher_applications/{applicationId}` | `userId` field | May contain identity documents / PII |
| `quran_teacher_profiles/{teacherId}` (+ `pricing`, `availability_config`, `availability_overrides`, `availability` subcollections) | `userId` field | Public marketplace profile; referenced by other users' bookings/sessions |
| `quran_teacher_metrics/{teacherId}` / `quran_student_metrics/{studentId}` | doc id | Denormalized per-user metrics |

### Shared (two parties reference the doc)

| Path | User linkage | Notes |
|---|---|---|
| `quran_bookings/{bookingId}` | `studentId`, `teacherId` | Belongs to both parties |
| `quran_sessions/{sessionId}` (+ `callTracking`, `call_events`) | `studentId`, `teacherId`, `actorId` in events | Belongs to both parties |
| `quran_session_events/{eventId}` | `actorId`, `bookingId`, `sessionId` | Audit timeline — evidentiary |
| `quran_reschedule_requests/{requestId}` | `requestedByUserId`, `bookingId` | |
| `quran_session_notifications/{notificationId}` | target user refs | Backend outbox |
| `notifications/{notificationId}` | `targetUserIds[]` | Push campaigns (may target many users) |

### Financial / ledger (legal retention)

| Path | User linkage |
|---|---|
| `wallet_transactions/{transactionId}` | `userId` |
| `quran_payment_intents/{paymentIntentId}` | uid fields |
| `quran_payment_transactions/{paymentTransactionId}` | uid fields |
| `quran_session_refunds/{refundId}` | via `bookingId` |
| `quran_session_compensations/{compensationId}` | via `bookingId` |
| `support_purchases/{tokenHash}` | keyed by token hash, not uid |

### Safety / integrity (must survive deletion)

| Path | Why |
|---|---|
| `quran_session_reports/{reportId}` | Abuse evidence — deletion must not destroy reports about the user |
| `quran_session_disputes/{disputeId}` | Dispute evidence |
| `quran_session_operations/{operationId}` | Idempotency ledger |

### Unrelated to any user (never touched)

`app_config`, `subscription_plans`,
`quran_session_market_configs` (+ `cities`), `quran_session_platform_config`,
`quran_slot_locks` (occupancy markers keyed by teacher+slot — expire on their
own; verify during implementation whether active locks reference the uid and
should be released at soft-delete time).

> Implementation-time verification step: grep the app + functions for any
> collection writes not present in rules (there should be none — Admin SDK
> collections are all listed above) and confirm the concrete PII field names
> on `quran_teacher_profiles` and `quran_bookings` before writing the
> anonymizer (bookings appear to reference parties by id only, which reduces
> the anonymization surface).

---

## 2. Deletion manifest

Explicit, exhaustive, per collection. `DELETE` = hard delete at purge.
`ANONYMIZE` = strip PII in place, keep ids/amounts/timestamps. `RETAIN` =
untouched. `IMMEDIATE` = acted on at soft-delete time, before the grace
period.

| Collection | Action | Detail |
|---|---|---|
| `users/{uid}/fcm_tokens/*` | **DELETE (IMMEDIATE)** | Stop pushes on day one |
| `users/{uid}` + all subcollections | **DELETE** at purge via `recursiveDelete` | Purchases/cancellations subcollections: export a compact financial summary into the audit record before deletion (they are the user's Play Billing trail; support ops may need it post-purge) |
| `user_wallets/{walletId}` | **DELETE** at purge | Precondition: balance must be zero or explicitly written off in the audit record; block deletion request if a payout/refund is pending |
| `quran_teacher_applications` (by `userId`) | **DELETE** at purge | Contains identity PII; no shared linkage |
| `quran_teacher_profiles/{teacherId}` + subcollections | **ANONYMIZE + unpublish** | At soft delete: `isActive=false`, `isPubliclyVisible=false` (existing `syncTeacherProfileVisibility` semantics). At purge: blank name/bio/photo fields, delete `availability*` and `pricing` subcollections, keep the doc so other users' bookings/sessions resolve. Never delete the doc id |
| `quran_teacher_metrics` / `quran_student_metrics` | **DELETE** at purge | Purely denormalized, rebuildable |
| `quran_bookings` (as `studentId` or via `teacherId`) | **ANONYMIZE** | Strip any denormalized display fields; keep ids, status, amounts, timestamps |
| `quran_sessions` + `callTracking` + `call_events` | **ANONYMIZE** | Same; `call_events` keep `actorRole`/telemetry, strip free-text if any |
| `quran_session_events` | **RETAIN** | Evidentiary timeline; contains ids only |
| `quran_reschedule_requests` | **ANONYMIZE** | Strip free-text reason if it contains PII; keep ids |
| `quran_session_notifications` | **DELETE** docs targeting the user at purge | Outbox is transient |
| `notifications` (campaigns) | **ANONYMIZE (narrow)** | Remove uid from `targetUserIds[]` only; never delete campaign docs (they target many users) |
| `wallet_transactions` | **RETAIN** | Financial ledger; references uid — acceptable, uid becomes a tombstone after purge |
| `quran_payment_intents` / `quran_payment_transactions` | **RETAIN** | Financial ledger |
| `quran_session_refunds` / `quran_session_compensations` | **RETAIN** | Financial ledger |
| `support_purchases` | **RETAIN** | Keyed by token hash; fraud/audit trail |
| `quran_session_reports` | **RETAIN** | Abuse evidence — explicitly protected |
| `quran_session_disputes` | **RETAIN** | Dispute evidence |
| `quran_session_operations` | **RETAIN** | Idempotency ledger |
| `quran_slot_locks` | **DELETE (IMMEDIATE, conditional)** | Release the user's active locks at soft delete if they reference the uid |
| Everything under "Unrelated" | **RETAIN** | Never enumerated by the purge |
| Firebase Auth user | Disable + revoke **(IMMEDIATE)**; **DELETE last** at purge | |

External systems (documented follow-ups, not in the purge function):
Firebase Analytics User Deletion API, Sentry user context/feedback scrub,
Crashlytics (keyed by install, clears with app deletion).

---

## 3. Cloud Functions API

All v2 `onCall`, TypeScript, in `functions/src/userDeletion/`, exported from
`index.ts`, following the `moderateQuranSessionsUser` +
`moderateQuranSessionsUserLogic` pattern (thin callable + pure logic module
for unit testing).

### `requestUserDeletion` (callable)

Request:

```jsonc
{
  "targetUserId": "string",       // required
  "reason": "string",             // required, 10–500 chars
  "confirmEmail": "string"        // required — must equal target's Auth email (second factor against wrong-row clicks)
}
```

Guards (in order, each a distinct `HttpsError`):
1. `request.auth?.token.admin === true` → else `permission-denied`
2. `targetUserId !== request.auth.uid` → else `failed-precondition` ("self-deletion not allowed")
3. Target's Auth custom claims must not include `admin` → else `failed-precondition`
4. `reason` present and within bounds → else `invalid-argument`
5. `confirmEmail` matches target Auth email (case-insensitive) → else `failed-precondition`
6. Target exists in Auth → else `not-found`
7. Not already `pending_deletion` → else `failed-precondition` (idempotent no-op response acceptable alternative)
8. Wallet balance zero / no pending payout → else `failed-precondition` with actionable message

Effects (this order):
1. Auth: `updateUser(uid, { disabled: true })`
2. Auth: `revokeRefreshTokens(uid)`
3. Firestore batch: mark `users/{uid}` (fields in §4), delete all
   `users/{uid}/fcm_tokens` docs, release the user's `quran_slot_locks`,
   set teacher profile `isActive=false` / `isPubliclyVisible=false` if one
   exists
4. Append audit doc to `user_deletion_audit` (schema in §4)

Response: `{ status: "pending_deletion", purgeAfter: <ISO date>, auditId }`

### `cancelUserDeletion` (callable)

Request: `{ "targetUserId": "string", "reason": "string" }`

Guards: admin claim; target currently `pending_deletion`; purge not yet
started (`purgeState` absent/`none`).
Effects: re-enable Auth user; restore `users/{uid}` status to prior value
(stored at request time); restore teacher profile visibility flags to their
stored prior values; append `deletion_cancelled` audit event. FCM tokens are
NOT restorable — the app re-registers on next sign-in (`registerActiveDevice`).

### `purgeDeletedUsers` (scheduled, `onSchedule` — daily, e.g. 03:00 UTC)

Query: `users` where `accountStatus == "pending_deletion"` and
`purgeAfter <= now`, limit small batch (e.g. 10/run).
Per user, execute the manifest as ordered idempotent steps (§ idempotency
below), Auth `deleteUser(uid)` strictly last, then finalize the audit record.
Timeout 540s; if the batch doesn't finish, the next run resumes — no state
is lost because every step is re-runnable.

Optional (recommended for testability and ops): `forcePurgeUser` admin
callable that runs the same purge pipeline for one uid immediately —
emulator tests and support escalations use it; guarded by the same admin
checks + `pending_deletion` status (it does NOT skip the grace period unless
an explicit `overrideGracePeriod: true` flag and a second reason are given).

### Idempotency & retry safety

- Reuse the `quran_session_operations` idempotency pattern
  (`idempotencyService.ts`): purge writes a per-user marker doc
  (`user_deletion_audit/{auditId}` doubles as the state machine) with
  `purgeState`: `none → purging → purged`, plus a `completedSteps: string[]`
  checklist (`fcm`, `owned_tree`, `wallet`, `teacher_profile`, `bookings`,
  `sessions`, `notifications`, `metrics`, `auth_deleted`).
- Every step is naturally idempotent (deleting missing docs, re-anonymizing
  anonymized fields, `deleteUser` on missing user → treat `user-not-found`
  as success).
- Anonymization queries page by cursor; a crash mid-page re-runs safely.
- Grace period: constant `PURGE_GRACE_DAYS = 30` in one config module.

---

## 4. Firestore fields to add or update

`users/{uid}` — extend the existing moderation surface
(`quranSessionsProfile.accountStatus` already supports
`active | suspended`; add `pending_deletion`), plus a top-level deletion
envelope (top-level so the purge query needs no map-field index tricks):

```jsonc
{
  "accountStatus": "pending_deletion",       // top-level mirror used by purge query
  "deletion": {
    "requestedAt": "<serverTimestamp>",
    "requestedBy": "<admin uid>",
    "reason": "<string>",
    "purgeAfter": "<timestamp>",
    "priorAccountStatus": "active|suspended", // for cancel
    "priorTeacherVisibility": { "isActive": true, "isPubliclyVisible": true } // if teacher
  },
  "quranSessionsProfile.accountStatus": "pending_deletion",
  "quranSessionsProfile.restrictionReason": "account_deletion"
}
```

New collection `user_deletion_audit/{auditId}` (append-only, CF-write-only):

```jsonc
{
  "targetUserId": "...",
  "targetEmailHash": "sha256(email)",   // hash, not plaintext — audit survives purge
  "action": "requested | cancelled | purged",
  "reason": "...",
  "actorUid": "<admin uid>",
  "createdAt": "<serverTimestamp>",
  "purgeState": "none | purging | purged",
  "completedSteps": ["fcm", "owned_tree", ...],
  "financialSummary": { /* compact purchases/wallet snapshot exported before owned-tree delete */ },
  "counts": { "docsDeleted": 0, "docsAnonymized": 0 }
}
```

Composite index: `users` on (`accountStatus`, `deletion.purgeAfter`) —
add to `firestore.indexes.json` and deploy with the existing
`scripts/deploy_firestore_indexes.sh`.

---

## 5. Admin panel UX flow (Angular, `features/users`)

1. **Entry point**: user detail/row action menu in the existing users
   feature → "Delete account…" (destructive styling, separated from
   suspend/reactivate).
2. **Confirmation dialog** (new component alongside
   `notification-modal`): shows uid, email, display name, teacher badge if
   applicable, wallet balance, and the consequence text ("disabled
   immediately; permanently purged after 30 days; financial and safety
   records are retained"). Requires (a) typed email match and (b) a reason
   (min 10 chars). Submit disabled until both valid; double-submit guarded.
3. On success: row shows a `pending_deletion` badge with purge date and a
   "Cancel deletion" action (which requires its own reason).
4. **Blocked states** surfaced from callable errors verbatim: admin target,
   self target, nonzero wallet, already pending.
5. **Audit view** (can ship later): read-only `user_deletion_audit` list,
   filterable by target uid — admins have rules read access (§6).
6. i18n: all strings in both `app_en.arb`/`app_ar.arb` (panel is bilingual).

---

## 6. Security rules changes (`firestore.rules`)

Per the project's own gotcha — new collections need matching rules before
the panel reads them:

```text
match /user_deletion_audit/{auditId} {
  allow read: if isAdmin();
  allow write: if false;          // CF (Admin SDK) writes only → append-only from clients' view
}
```

Also:
- `users/{userId}`: today `allow update: if isAdmin() || …` lets any admin
  write the deletion envelope directly from a client. Tighten so the
  deletion fields are CF-only: extend the owner-side guard style
  (`incomingUnchanged('deletion')`, `accountStatus` transition to/from
  `pending_deletion` denied for client writes, including admin clients) —
  the callable is the only path that may set them.
- Client apps must treat `accountStatus == "pending_deletion"` as
  signed-out; the Auth user is disabled anyway, so this is defense in
  depth, not a new client feature.
- No change needed for anonymize/retain collections — they are already
  client-write-denied.

---

## 7. Emulator / integration test plan

Location: `functions/test` (unit, pure logic) + `functions/test-integration`
(emulator) + `functions/test-rules` (rules), matching existing suites.

**Unit (logic module, no emulator):**
- Guard matrix: non-admin, self, admin target, missing/short reason,
  email mismatch, unknown uid, already pending, nonzero wallet → each maps
  to the right `HttpsError` code.
- Manifest completeness check: a test that asserts every collection named
  in `firestore.rules` appears in exactly one manifest bucket
  (delete/anonymize/retain/unrelated) — this is the guard against future
  collections silently escaping the flow.

**Integration (Auth + Firestore emulators):**
1. *Happy path request*: seed admin + target with fcm_tokens, favorites,
   wallet(0), teacher profile → call `requestUserDeletion` → assert Auth
   disabled, tokens revoked (`tokensValidAfterTime` bumped), fcm_tokens
   gone, status fields set, teacher profile unpublished, audit doc written.
2. *Cancel path*: request → cancel → assert Auth re-enabled, prior status
   and teacher visibility restored, audit has both events.
3. *Full purge*: seed a rich fixture — owned tree (all subcollections), a
   booking + session shared with a second user, wallet transactions, a
   report *about* the target, a dispute, campaign notification targeting
   the target + others → fast-forward `purgeAfter` → run purge → assert:
   owned tree gone; booking/session docs exist with ids intact and PII
   fields blanked; report and dispute untouched; wallet_transactions
   untouched; campaign doc exists with uid removed from `targetUserIds`;
   teacher profile doc exists, anonymized, availability subcollections
   gone; Auth user deleted; audit `purgeState == "purged"` with counts.
4. *Idempotency*: run purge twice for the same user; second run is a no-op
   with no errors. Simulate a crash by pre-marking half of
   `completedSteps` and assert only remaining steps execute.
5. *Ordering*: assert Auth `deleteUser` did not happen if any earlier step
   throws (inject a failure; Auth user still exists, `purgeState` stays
   `purging`, next run completes).
6. *Grace period*: user with `purgeAfter` in the future is not purged.

**Rules tests (`test-rules`):**
- Admin can read `user_deletion_audit`; non-admin cannot; nobody can write.
- Client (owner and admin SDK-as-client) cannot set `accountStatus:
  pending_deletion` or touch the `deletion` map on `users/{uid}`.

Runner: existing emulator config in `firebase.json` (auth 9099,
firestore 8080, functions 5001).

---

## 8. Production safety checklist

Before first deploy:
- [ ] Audit who holds the `admin` custom claim (script it; record the list
      in the audit collection or ops doc).
- [ ] Deploy rules + indexes **before** functions (audit collection
      readable, purge query indexed).
- [ ] `PURGE_GRACE_DAYS = 30` confirmed with product/legal; financial
      retention list (§2 RETAIN rows) confirmed with whoever owns
      compliance.
- [ ] App Check enforcement on the new callables if enabled on existing
      ones (match `moderateQuranSessionsUser`'s setting).
- [ ] Verify teacher-profile PII field names against production data shape
      before finalizing the anonymizer.

Rollout:
- [ ] Ship `requestUserDeletion` + `cancelUserDeletion` + UI first;
      **hold the scheduled purge disabled** (deploy with schedule commented
      or feature-flagged) for one full grace period — every "deleted" user
      is recoverable while the flow soaks.
- [ ] First real deletion: run on a designated internal test account
      end-to-end in production; verify audit record, lockout, and (after
      enabling purge or via `forcePurgeUser`) the purge result.
- [ ] Enable the scheduler; alert on function errors (Crashlytics/Sentry →
      existing `crashlyticsToGithubIssue` pipeline or Cloud Monitoring
      alert on `purgeDeletedUsers` failures).

Ongoing:
- [ ] PR checklist rule: any new user-linked collection must be added to
      the deletion manifest + the manifest-completeness test (the test in
      §7 makes this fail loudly).
- [ ] Quarterly: review audit log; verify no `purging`-stuck records.
- [ ] Document the external-systems follow-up (Analytics deletion API,
      Sentry scrub) as a tracked TODO if GDPR/Play data-deletion claims
      are made in the store listing.

---

## Implementation order (when code starts)

1. `functions/src/userDeletion/` logic modules + unit tests (guards,
   manifest, purge steps as pure functions over injected db).
2. Callables + scheduled function wiring, `index.ts` exports.
3. `firestore.rules` + `firestore.indexes.json` changes + rules tests.
4. Emulator integration suite.
5. Admin panel dialog + service + badge states + i18n.
6. Staged rollout per checklist.

