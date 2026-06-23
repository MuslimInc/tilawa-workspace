# Approved Teacher Activation Audit

**Date:** 2026-06-23  
**Symptom:** Admin-approved teacher sees **عرض حالة الطلب** in Settings, not **أكمل ملف المعلم** / **لوحة تحكم المحفظ**, while `/sessions/teacher/status` shows approved.  
**Scope:** Code audit only — no UI fix applied.

---

## Current backend behavior

### Admin approve path (production)

Admin panel → `ReviewTeacherApplicationUseCase` → `ModerationGateway.reviewTeacherApplication` → Cloud Function `reviewTeacherApplication` (`functions/src/reviewTeacherApplication.ts`).

On `action === "approve"`:

1. **`quran_teacher_applications/{applicationId}`** merged:
   - `status: "approved"`
   - `reviewedAt`, `reviewedBy`, `updatedAt`
   - `rejectionReason` cleared/null

2. **`quran_teacher_profiles/{applicationId}`** created/merged via `buildApprovedTeacherProfile()` (`functions/src/quranSessions/teacherProfileApproval.ts`):
   - `userId` ← application
   - `displayName` ← `publicDisplayName` / `teacherDisplayName` / legacy `displayName`, else `users/{userId}.displayName` only if application has no display-name field; never bio; never placeholders (`Quran Teacher`, `محفظ قرآن`)
   - `publicBio` ← `app.bio` (trimmed)
   - `teachingLanguages`, `specializations` ← application arrays
   - `verificationStatus: "verified"`
   - `teacherStatus: "approved"`
   - `isActive: true`
   - `profileCompleteness`: `"complete"` | `"incomplete"` (needs valid displayName, non-empty bio, languages, specializations)
   - `isPubliclyVisible`: true only when complete + verified + active
   - `averageRating: 0`, `reviewCount: 0`, `totalSessionsCompleted: 0`

On `suspend` / `revoke`: application status updated; profile `isActive: false`, `isPubliclyVisible: false`.

### Profile completion after approve

- Client **cannot** create profiles (`allow create: if false`).
- Verified owner may **update** public fields only (`displayName`, `publicBio`, `teachingLanguages`, `specializations`, `avatarUrl`) — trust fields frozen in rules.
- `syncTeacherProfileVisibility` Firestore trigger recomputes `profileCompleteness` + `isPubliclyVisible` on every profile write.

### Client-side approve path (NOT production)

`ApproveTeacherApplicationUseCase` (Dart) writes application + creates profile via client repos. **Blocked by Firestore rules** (client cannot set `approved`, cannot create profile). Only usable in MVP/fake mode or tests.

### Fields NOT set on teacher profile at approve

- `accountStatus` — lives on `users/{id}.quranSessionsProfile.accountStatus`, unrelated to teacher capability resolver
- `avatarUrl`, `allowedStudentGender`, `canTeachChildren` — not copied from application at approve

---

## Current admin approval behavior

- Admin **does not** write Firestore directly for moderation.
- Approve is a single CF call with `applicationId` + `action: "approve"` — no extra profile payload from admin UI.
- Admin reads application as stored (including `bio`, `publicDisplayName`, `teachingLanguages`, `specializations`).
- Admin approval is **sufficient** to create an **active marketplace-ready** profile **if** the submitted application already has complete public fields per CF rules.

**Product intent (from code):** Approval creates profile shell from application data. Incomplete application data → `profileCompleteness: incomplete`, `isPubliclyVisible: false` → teacher must complete profile in app. Admin approval does **not** force incomplete apps to active marketplace visibility.

---

## Current Firestore data after approval

### Expected documents

| Collection | Doc ID | Key fields |
|------------|--------|------------|
| `quran_teacher_applications` | `{applicationId}` | `status: approved`, `userId`, `bio`, `publicDisplayName`, … |
| `quran_teacher_profiles` | `{applicationId}` (same as application) | `userId`, `displayName`, `publicBio`, `verificationStatus`, `isActive`, `profileCompleteness`, `isPubliclyVisible` |

Profile lookup in app: `quran_teacher_profiles.where('userId', '==', uid).limit(1)` — no composite index required for single-field equality.

### Staging verification checklist (manual — not run in this audit)

For affected `userId` / `applicationId`:

```
quran_teacher_applications/{id}.status          → "approved"
quran_teacher_profiles/{id}.userId              → matches auth uid
quran_teacher_profiles/{id}.isActive            → true (not missing)
quran_teacher_profiles/{id}.verificationStatus  → "verified"
quran_teacher_profiles/{id}.profileCompleteness → "complete" | "incomplete"
quran_teacher_profiles/{id}.isPubliclyVisible   → mirrors completeness + active
quran_teacher_profiles/{id}.displayName         → non-empty, not placeholder
quran_teacher_profiles/{id}.publicBio           → non-empty if complete
```

### CF vs Dart completeness parity gap

| Rule | Cloud Function | Flutter domain |
|------|----------------|----------------|
| Display name min length | `length > 0` | `length >= 3` OR 2+ words |
| Placeholders | `Quran Teacher`, `محفظ قرآن` | + `teacher`, `test`, `anonymous` |
| Verification for completeness | Not required in `computeProfileCompleteness` | Required (`verified`) in `TeacherProfileCompleteness.evaluate` |

CF can mark `profileCompleteness: complete` while Dart mapper recomputes `incomplete` (rare edge names). That yields **`approvedIncompleteProfile`** (complete-profile CTA), **not** view-status.

Dart mapper **recomputes** `isPubliclyVisible` from fields + `isActive`; does not trust stored flag alone.

**Risk:** `isActive` read defaults to `false` if field missing (`FirestoreTeacherProfileDto.fromDoc`). Legacy/malformed docs → `approvedInactive`.

---

## Current Flutter capability mapping

### Resolution pipeline

`GetCurrentUserTeacherCapabilityUseCase`:

1. Load application by `userId`
2. If `approved` / `suspended` / `revoked` → load profile by `userId` (failure → `profile = null`)
3. `TeacherCapabilityResolver.resolve(application, profile)`

### Approved branch

| Condition | `TeacherCapabilityState` | Settings title (AR) | Nav target |
|-----------|--------------------------|---------------------|------------|
| No profile OR fields incomplete | `approvedIncompleteProfile` | أكمل ملف المعلم | `/sessions/teacher/profile/complete` |
| Fields complete + publicly visible | `approvedActive` | لوحة تحكم المحفظ | `/sessions/dashboard` |
| Fields complete + NOT visible | `approvedInactive` | عرض حالة الطلب | `/sessions/teacher/status` |
| Application `pending` | `pending` | عرض حالة الطلب | status |
| `suspended` / `revoked` | same | عرض حالة الطلب | status |

**`approvedInactive`** = Flutter-only derived state. Not stored in Firestore. Means: domain `profileCompleteness == complete` but `isPubliclyVisible == false` → practically **`isActive == false`** after mapper (verification incomplete would land in `approvedIncompleteProfile` first).

### Settings load behavior

`SettingsTeacherCapabilityScope` loads capability **once** in `initState`. No refresh on resume, no Firestore listener, no invalidation after admin approval.

Status screen (`TeacherApplicationBloc`) reloads application on each visit.

### Symptom decode

**عرض حالة الطلب** requires capability ∈ `{pending, rejected, approvedInactive, suspended, revoked}`.

Status screen showing **approved** rules out fresh `pending/rejected/suspended/revoked` from the same data source.

Most likely explanations:

1. **Stale Settings capability** — Settings opened while `pending`; admin approved; user opened status (fresh) but Settings widget never reloaded → still `pending` → view status.
2. **`approvedInactive`** — profile fields complete in domain but `isActive: false` or missing in Firestore.
3. Less likely: user not on Firebase module (MVP fake) with divergent state.

**Not** explained by correct fresh `approvedIncompleteProfile` (that shows complete-profile CTA, not view status).

---

## Root cause

**Multiple layers — Flutter primary, backend secondary verify.**

| Layer | Verdict |
|-------|---------|
| **Backend CF approve** | Correct design. Creates profile, sets trust fields. Incomplete app data → incomplete profile by design. |
| **Admin panel** | Correct. Delegates to CF; no missing approve step. |
| **Firestore data model** | Correct. Profile doc ID = applicationId; `userId` indexed query works. |
| **Firestore rules** | Correct for intended flow. Client cannot self-approve or create profile; owner can edit public fields; CF trigger syncs visibility. |
| **Flutter state mapping** | Resolver logic mostly correct. **`approvedInactive` routes to status screen** — product gap / dead-end when active flag wrong. |
| **Flutter routing / Settings** | **P0 bug: capability loaded once, never refreshed after approval.** Explains approved status screen + view-status Settings row. |

**Do not assume backend wrong** — verify Firestore for one affected user first. If profile is complete + `isActive: true` + `isPubliclyVisible: true`, backend is fine and bug is **Settings stale cache** (and missing post-approval navigation from status screen).

---

## Recommended fix

**Choose: 3 — Backend + Flutter fix** (backend = verify + optional hardening; Flutter = required)

Priority order:

1. **Verify staging Firestore** for reported user (checklist above).
2. **Flutter (required):**
   - Refresh `SettingsTeacherCapabilityScope` on app resume / when returning from sessions routes.
   - After approval on status screen, invalidate capability + navigate per `navigateForTeacherCapability` (already partially fixed for transition; Settings parent still stale).
   - Remap **`approvedInactive`** for approved applications → `completeTeacherProfile` or dashboard per KISS rules (inactive approved is edge case; should not dead-end on status).
3. **Backend (conditional):**
   - If profiles missing `isActive` or profile doc missing after CF approve → CF bug or failed deploy; fix + backfill.
   - Align CF `isValidDisplayName` with Dart `ValidateTeacherPublicName` if parity gaps found in staging data.

**Not recommended yet:** Flutter-only routing patch without capability refresh — masks stale-cache bug.

**Not needed unless data bad:** Rules change, admin UI change.

---

## Exact implementation plan

### Phase A — Verify (before code)

1. Firebase Console → affected `applicationId` + profile doc.
2. Log `GetCurrentUserTeacherCapabilityUseCase` result in debug for that `userId`.
3. Kill app → reopen Settings → if row fixes, confirms stale cache.

### Phase B — Flutter (after A confirms)

1. `SettingsTeacherCapabilityScope`: add `refresh()` + call from `RouteAware` / `WidgetsBindingObserver.didChangeAppLifecycleState(resumed)` / parent `SettingsScreen` visibility.
2. `TeacherApplicationStatusScreen`: on approved view, show CTA → complete profile or dashboard based on capability (not only auto-nav on transition).
3. `TeacherCapabilityNavigation`: map `approvedInactive` + `application.status == approved` → `completeTeacherProfile` if fields incomplete, else surface inactive reason (or admin re-activate path).
4. Optional: expose `TeacherCapabilityScope` at app shell level shared by Settings + sessions.

### Phase C — Backend (if Firestore bad)

1. Confirm `reviewTeacherApplication` + `syncTeacherProfileVisibility` deployed on staging project.
2. Backfill script: for `approved` applications without profile doc → run `buildApprovedTeacherProfile` merge.
3. Backfill `isActive: true` where missing on approved profiles.
4. Align name validation in `teacherProfileApproval.ts` with Dart if needed.

**No UI fix in this audit PR** — Phase B is next task after Phase A sign-off.

---

## Tests required

| Area | Test |
|------|------|
| Capability resolver | `approvedInactive` + approved app routing intent (new) |
| Settings scope | reload updates capability after mock approve |
| Integration | admin approve (CF emulator) → fresh capability → correct Settings title |
| CF | `buildApprovedTeacherProfile` with incomplete/complete application fixtures |
| CF trigger | `syncTeacherProfileVisibility` updates trust fields after client public-field edit |
| Rules | client cannot approve application; owner can update public fields |

---

## Free Beta blocker?

**Yes — P0 for teacher onboarding E2E** if reproducible on staging without app restart.

Manual runbook step “admin approves → teacher opens dashboard” fails when Settings shows view-status loop. Workaround: force-quit app (unacceptable for beta).

Blocker class:

- **Staging E2E** — blocked until capability refresh + correct post-approve CTA.
- **Play Internal** — same gate as manual E2E in `specs/037-quran-session-free-beta-closure/report.md`.

Not a wallet/payment blocker. Not a Firestore rules blocker unless profile doc missing entirely (then CF deploy/data issue).

---

## Answers to audit questions

1. **What happens on admin approve?** CF sets application `approved`, creates/merges teacher profile with computed completeness/visibility.
2. **Creates TeacherProfile?** Yes — `quran_teacher_profiles/{applicationId}`.
3. **Field checklist:**
   - `application.status` → `approved` ✓
   - `teacherProfile.status` → N/A; uses `teacherStatus: "approved"` on profile
   - `isPubliclyVisible` → computed ✓
   - `profileCompleteness` → computed ✓
   - `accountStatus` → user doc only, not set at approve
   - `displayName`, `publicBio`, `teachingLanguages`, `specializations` → copied from application ✓
4. **Complete profile after approval?** Expected when application data incomplete at submit. Complete application → active profile at approve.
5. **Source of truth:**
   - Pending application → `quran_teacher_applications.status == pending`
   - Approved application → `status == approved`
   - Incomplete teacher profile → profile `profileCompleteness == incomplete` (CF + trigger)
   - Active teacher profile → `isPubliclyVisible == true` (complete + verified + active)
   - Suspended teacher → `application.status == suspended` (profile `isActive: false`)
6. **`approvedInactive`?** Flutter-derived only. Complete fields, not publicly visible.
7. **Admin saving enough?** Yes — if application form captured required fields. Admin does not add profile fields at approve.
8. **Stale cached data?** **Yes — Settings loads once.** Strongest match for symptom.
9. **Firestore structure?** Correct.
10. **Rules for profile completion?** Owner can write public fields; trust fields via CF trigger. Rules OK.

---

## Phase A execution log

**Executed:** 2026-06-23  
**Agent:** Phase A tooling + staging Firestore read (ADC, project `quran-playera-app`).

### Script

- **Path:** `functions/scripts/verifyTeacherActivation.ts`
- **npm script:** `npm run quran-sessions:verify-teacher-activation`
- **Args:** `--userId=UID`, `--applicationId=ID`, `--list-recent=N` (default 10 when no ids)
- **Behavior:** Reads `quran_teacher_applications` + `quran_teacher_profiles`, runs CF + Dart-parity completeness checks, derives `TeacherCapabilityState`, exits `1` on critical data mismatch.

### Commands run

```sh
cd functions
FIREBASE_PROJECT_ID=quran-playera-app npm run quran-sessions:verify-teacher-activation -- --list-recent=10
```

Credentials: Application Default Credentials (gcloud); no `GOOGLE_APPLICATION_CREDENTIALS` file. Project from `.firebaserc` default `quran-playera-app`.

**Targeted re-run (when user reports bug):**

```sh
FIREBASE_PROJECT_ID=quran-playera-app npm run quran-sessions:verify-teacher-activation -- --userId=WV0m6tenTJPDLZE4EdWXBzjADF12
# or
FIREBASE_PROJECT_ID=quran-playera-app npm run quran-sessions:verify-teacher-activation -- --applicationId=a1sYAAaBHg5aq1uwya0o
```

### Firestore findings (per user/doc)

Only **1** approved application in staging (at time of run):

| Field | `quran_teacher_applications/a1sYAAaBHg5aq1uwya0o` | `quran_teacher_profiles/a1sYAAaBHg5aq1uwya0o` |
|-------|------------------------------------------------------|-----------------------------------------------|
| `userId` | `WV0m6tenTJPDLZE4EdWXBzjADF12` | `WV0m6tenTJPDLZE4EdWXBzjADF12` ✓ |
| `status` / trust | `approved` (reviewed 2026-06-21) | `verificationStatus: verified` ✓ |
| `isActive` | — | **`false`** ✗ (CF approve sets `true`) |
| `profileCompleteness` | — | `complete` (stored; CF + Dart agree) |
| `isPubliclyVisible` | — | `false` (consistent with `isActive: false`) |
| `displayName` | — | `Mohamed turo` ✓ |
| `publicBio` | bio len 13 on app | len 13 ✓ |
| `teachingLanguages` / `specializations` | `ar` / `tajweed` | same ✓ |

**Critical failure:** approved application has profile with **`isActive: false`**. Profile doc exists; userId matches. Not a missing-profile case.

**Likely cause (data):** profile deactivated after approve (`moderateTeacherProfile` deactivate), pre-fix approve without `isActive: true`, or failed merge — **not** explainable by Settings cache alone.

### Derived capability state

For `WV0m6tenTJPDLZE4EdWXBzjADF12`:

| Derived | Value |
|---------|--------|
| `TeacherCapabilityState` | **`approvedInactive`** |
| Settings title (AR) | **عرض حالة الطلب** |
| Nav target | `/sessions/teacher/status` |
| CF completeness | `complete` |
| Dart completeness | `complete` |
| `isPubliclyVisible` (Dart) | `false` |

Matches reported symptom **without** stale cache.

### Stale cache confirmed? (yes/no/untested)

**Untested on device** (no manual kill-app loop this session).

**Code review:** `SettingsTeacherCapabilityScope` loads capability **once** in `initState` (`apps/tilawa/lib/features/settings/presentation/widgets/settings_teacher_capability_scope.dart`) — no `refresh()`, no `RouteAware`, no lifecycle observer. Stale-cache path remains **plausible** for pending→approved transition but **not required** to explain current staging user.

**Manual confirmation (no code change):**

1. Reproduce with affected account while application still `pending` → open Settings (note row).
2. Admin approve.
3. Open `/sessions/teacher/status` (fresh load) vs Settings **without** killing app.
4. Force-quit → reopen Settings. If row changes only after step 4, stale cache confirmed.

### Phase A verdict: **FAIL**

Backend/data **not** 100% correct for the only staging approved teacher: `isActive: false` on an approved, complete profile.

### Phase B authorized: **no**

Do **not** ship Flutter-only capability refresh / routing fix until data fixed. Symptom is **`approvedInactive`** from Firestore, not proven stale-cache-only.

### Recommended next step (Phase C — backend/data)

1. **Fix affected doc:** `moderateTeacherProfile` action `activate` for `teacherId=a1sYAAaBHg5aq1uwya0o`, or merge `{ isActive: true }` via admin script after verifying application still `approved`.
2. **Re-run verification:** expect `approvedActive`, Settings title **لوحة تحكم المحفظ**.
3. **Audit:** scan all `quran_teacher_applications` where `status == approved` and profile `isActive != true`; backfill (`functions/scripts/backfillApprovedTeacherActivation.ts`).
4. **Then** re-run Phase A → if PASS with only stale-cache risk remaining, authorize Phase B (capability refresh + `approvedInactive` routing).

---

## Phase A re-run (2026-06-23)

### Data fix applied

```sh
cd functions
FIREBASE_PROJECT_ID=quran-playera-app npm run quran-sessions:backfill-approved-activation -- --apply
FIREBASE_PROJECT_ID=quran-playera-app npm run quran-sessions:verify-teacher-activation -- --applicationId=a1sYAAaBHg5aq1uwya0o
```

**Result:** `isActive: false` → `true`, `isPubliclyVisible: true`, derived `approvedActive`, Settings **لوحة تحكم المحفظ**.

### Phase A verdict (re-run): **PASS**

### Phase B authorized: **yes**

Implemented:

- `SettingsTeacherCapabilityScope` — refresh on app resume + when settings route becomes current again; `refreshOf(context)`
- `TeacherApplicationStatusScreen` — **متابعة** CTA on approved state
- `navigateAfterTeacherApproval()` — shared post-approval navigation helper
- `functions/scripts/backfillApprovedTeacherActivation.ts` — backfill approved profiles with `isActive != true`
