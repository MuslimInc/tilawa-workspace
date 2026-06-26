# QuranTutor — Teacher approval deploy & QA checklist

**Purpose:** Ops sign-off for P1 teacher-approval slice (`requiresTutorApproval`). No P2 implementation in this doc.  
**Related:** [teacher_approval_spec.md](./teacher_approval_spec.md) · [two_device_qa_script.md](./two_device_qa_script.md) (Part F) · [firebase_config_checklist.md](./firebase_config_checklist.md) · [release_readiness_report.md](./release_readiness_report.md)

---

## 1. Cloud Functions deploy

### Approval-slice callables (deploy before staging Part F)

These functions are **not** in `scripts/deploy_quran_session_callables.sh` stable list today — deploy explicitly:

```sh
# From repo root; substitute project id
firebase deploy --only \
  functions:respondToBookingRequest,\
functions:createSessionBooking,\
functions:expirePendingReservations \
  --project quran-playera-app
```

| Function | Role in approval slice |
|----------|------------------------|
| `respondToBookingRequest` | Tutor **accept** / **reject** (`response: accept\|reject`, optional `reason`) |
| `createSessionBooking` | Branches on `quranTutorBookingMode` → `pending_tutor_approval` vs `scheduled` |
| `expirePendingReservations` | Scheduled (every 5 min); expires `pending_tutor_approval` past `approvalExpiresAt` |

Region: **`us-central1`** (client uses `FirebaseFunctions.instanceFor(region: 'us-central1')`).

### Full session callable set (existing script)

```sh
./scripts/deploy_quran_session_callables.sh quran-playera-app
```

Deploys 13 stable callables + `sessionReminders` scheduler. **Does not** include `respondToBookingRequest`, `expirePendingReservations`, wallet, or admin callables — run the explicit `--only` block above after (or instead of partial deploy).

### Deploy all functions (package script)

```sh
cd functions
npm ci
npm run build
npm run deploy   # firebase deploy --only functions
```

Use when ops wants every exported function from `functions/src/index.ts` without maintaining `--only` lists.

### Pre-deploy build

`firebase.json` runs `tsc` via `predeploy` on deploy. Manual build:

```sh
cd functions && npm run build
```

### Verify

```sh
cd functions && npm test
cd functions && npm run test:rules
```

---

## 2. Firestore indexes deploy

### P1 indexes added (teacher approval)

| Collection | Fields | Use |
|------------|--------|-----|
| `quran_bookings` | `teacherId` ASC, `lifecycleStatus` ASC, `startsAt` ASC | Tutor pending-requests query |
| `quran_bookings` | `lifecycleStatus` ASC, `approvalExpiresAt` ASC | `expirePendingReservations` tutor-approval scan |

### Deploy command

```sh
firebase deploy --only firestore:indexes --project quran-playera-app
```

Combined with rules (from [release_readiness_report.md](./release_readiness_report.md)):

```sh
firebase deploy --only firestore:rules,firestore:indexes --project quran-playera-app
```

Wait for index builds to finish in Firebase Console before Part F QA (tutor dashboard pending list will fail without the `teacherId` + `lifecycleStatus` composite).

---

## 3. Config: `quranTutorBookingMode`

### Firestore path (authoritative)

**Document:** `quran_session_platform_config/global`  
**Field:** `quranTutorBookingMode` — `autoConfirm` | `requiresTutorApproval`

Server reads at booking time (`functions/src/quranSessions/quranTutorBookingMode.ts`). Client policy cache: `FirestoreSessionPolicyRepository` → `session_policy_dto.dart`.

**Merge** into existing `global` doc (do not wipe `enabledCallProviders`, age gates, etc.).

### Staging — approval QA (`requiresTutorApproval`)

```json
{
  "quranTutorBookingMode": "requiresTutorApproval",
  "enabledCallProviders": ["external", "mock"],
  "childAgeThreshold": 14,
  "globalAllowMaleTeacherFemaleStudent": true,
  "globalAllowFemaleTeacherMaleStudent": true
}
```

### Staging — auto-confirm smoke (`autoConfirm`)

Keep for Parts A–E regression without tutor gate:

```json
{
  "quranTutorBookingMode": "autoConfirm",
  "enabledCallProviders": ["external", "mock"]
}
```

If field omitted on non-production distribution, client + server default to **`autoConfirm`** (`distributionDefaultQuranTutorBookingMode`).

### Production GA (recommended)

```json
{
  "quranTutorBookingMode": "requiresTutorApproval",
  "enabledCallProviders": ["external"]
}
```

Remove `mock` from production `enabledCallProviders` before wide Play release ([release_readiness_report.md](./release_readiness_report.md)).

### Dart-define (client hint only — not authoritative)

| Define | Values | Notes |
|--------|--------|-------|
| `TILAWA_LAUNCH_QURAN_TUTOR_BOOKING_MODE` | `autoConfirm` \| `requiresTutorApproval` | **Debug builds only** (`kDebugMode` + `TILAWA_DISTRIBUTION != play_production`). Ignored on release APK. |

Examples in `apps/tilawa/lib/core/bootstrap/app_launch_config.dart`.

**Release staging APK for Part F:** set Firestore `requiresTutorApproval` — do not rely on dart-define.

### Staging APK build (from [two_device_qa_script.md](./two_device_qa_script.md))

```sh
cd apps/tilawa
flutter build apk --release \
  --dart-define=TILAWA_DISTRIBUTION=staging \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=external,mock
```

Install: `build/app/outputs/flutter-apk/app-release.apk` on both devices.

For Part F only, add Firestore `quranTutorBookingMode: requiresTutorApproval` **before** booking tests (or rebuild after config change; no APK rebuild required for mode flip).

---

## 4. Staging QA — `requiresTutorApproval`

Execute **[two_device_qa_script.md](./two_device_qa_script.md) Part F** after CF + indexes + Firestore config above.

Prereq checklist:

- [ ] `respondToBookingRequest`, `createSessionBooking`, `expirePendingReservations` deployed
- [ ] P1 composite indexes **Built** in Console
- [ ] `quran_session_platform_config/global.quranTutorBookingMode` = `requiresTutorApproval`
- [ ] Seeded teachers + student profile complete ([firebase_config_checklist.md](./firebase_config_checklist.md))
- [ ] `./scripts/quran_sessions_preflight.sh` green

---

## 5. Production flag recommendation

| Setting | Recommendation |
|---------|----------------|
| `quranTutorBookingMode` | **`requiresTutorApproval`** before public booking GA |
| `TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED` | `true` only after Part F sign-off |
| `enabledCallProviders` | `external` (+ `agora` when RTC ready); **no `mock`** |
| Deploy order | Indexes → CF approval slice → Firestore config → production APK |

Do **not** set `requiresTutorApproval` in production Firestore until CF + mobile build with Part F UI are live.

---

## 6. Remaining risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| `deploy_quran_session_callables.sh` omits `respondToBookingRequest` | High | Use §1 explicit `--only` deploy every release touching approval |
| Index build lag | Medium | Wait Console “Enabled” before Part F |
| Pending expires at slot start | Low | `expirePendingReservations` every 5 min; manual F6 optional |
| Push notifications for accept/reject | Low | v1 is in-app + pull-to-refresh; outbox kinds may enqueue without FCM delivery |
| Legacy `status: rejected` vs tutor reject | Low | UI uses `lifecycleStatus` |
| Client/server mode mismatch | Medium | Server wins; verify Firestore field on staging before QA |

---

## 7. GA blockers vs P2 deferrals

| Item | Status | GA blocker? | Notes |
|------|--------|-------------|-------|
| Tutor accept/reject in dashboard | ✅ Wired | **Yes** — must pass Part F | `TeacherBookingRequestAccepted` / `Rejected` |
| Student pending UI + no join | ✅ Wired | **Yes** | Arabic: `تم إرسال طلب الحجز` / `في انتظار موافقة المحفظ` |
| **Reject reason sheet** | ❌ Not wired | **No** (P2) | CF + bloc accept optional `reason`; UI calls reject **without** reason sheet (~dialog + TextField) |
| **Teacher cancel after accept** | ❌ Not wired | **Production risk** (P2) | `TeacherSessionCancelled` bloc handler + `cancelSessionBooking` CF exist; **no** cancel on teacher dashboard `SessionCard` or teacher session detail (`canCancel` = student-only policy) |
| Teacher join on upcoming card | ✅ Partial | No | Join routes to session detail via `onJoin` |

### P2 slice proposals (document only)

**Reject reason:** Before `TeacherBookingRequestRejected`, show bottom sheet; pass `reason` to bloc (CF already supports `reason?`).

**Teacher cancel:** Add cancel action on teacher upcoming `SessionCard` or session detail when `ActorRole.teacher` + `scheduled`/`confirmed`/`rescheduled`; dispatch `TeacherSessionCancelled(bookingId, reason)` or reuse `SessionDetailCancelSubmitted` with teacher actor resolution.

---

## Quick copy-paste (staging approval deploy)

```sh
# 1. Indexes
firebase deploy --only firestore:indexes --project quran-playera-app

# 2. Approval CFs
firebase deploy --only \
  functions:respondToBookingRequest,\
functions:createSessionBooking,\
functions:expirePendingReservations \
  --project quran-playera-app

# 3. Firestore: merge quran_session_platform_config/global
#    quranTutorBookingMode: "requiresTutorApproval"

# 4. QA
cd apps/tilawa && flutter build apk --release \
  --dart-define=TILAWA_DISTRIBUTION=staging \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=external,mock
# → two_device_qa_script.md Part F
```
