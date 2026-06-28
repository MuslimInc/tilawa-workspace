# QuranTutor — Two-device manual QA script

**Purpose:** Sign-off for booking (B*) and single-active-device (T*) before Play internal/wide release.  
**Prereqs:** Two physical devices (or device + emulator), **release APK**, staging Firebase, push enabled on both.

**Related:** [individual_booking_qa.md](../qa/individual_booking_qa.md) · [single_active_device_qa.md](../qa/single_active_device_qa.md) · [quran_sessions_free_beta_signoff.md](../qa/quran_sessions_free_beta_signoff.md) · [approval_deploy_qa_checklist.md](./approval_deploy_qa_checklist.md) (Part F deploy prereqs)

---

## Setup (both testers)

### Build

```sh
cd apps/tilawa
flutter build apk --release \
  --dart-define=TILAWA_DISTRIBUTION=staging \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=external,mock
```

Install: `build/app/outputs/flutter-apk/app-release.apk` on **both** devices.

### Accounts

| Role | Account | Requirements |
|------|---------|--------------|
| Student | `test-student@…` | Complete `quranSessionsProfile` (gender, DOB, EG/cairo) |
| Teacher | `test-teacher@…` | Verified profile, `externalMeetingUrl`, weekly availability saved |
| Admin | For T7 only | Can approve teacher application in `tilawa_admin` |

### Firebase (ops)

- [ ] `quran_session_platform_config/global.enabledCallProviders` includes `external` (+ `mock` for B2)
- [ ] Part F only: `quranTutorBookingMode: requiresTutorApproval` + CF/index deploy per [approval_deploy_qa_checklist.md](./approval_deploy_qa_checklist.md)
- [ ] Teachers seeded or approved ([firebase_config_checklist.md](./firebase_config_checklist.md))
- [ ] Staging `google-services.json` in APK

### Automated preflight (eng)

```sh
./scripts/quran_sessions_preflight.sh
```

---

## Device assignment

| Label | Device | Primary role |
|-------|--------|--------------|
| **A** | Phone 1 | Student (also stale-device tests) |
| **B** | Phone 2 | Second login / teacher approval target |

Label devices with tape/sticker for T2–T8.

---

## Part A — Booking scenarios (B1–B5)

### B1 — Student external meeting

| Step | Device A (student) | Expected |
|------|-------------------|----------|
| 1 | Sign in | Home loads |
| 2 | QuranTutor → pick verified teacher | Profile loads |
| 3 | Book → **External meeting** → slot → Confirm | Success toast |
| 4 | My Sessions → open session → **Join** | Confirmation sheet → external browser opens Meet/Zoom URL |

**Pass:** Firestore session `callProvider: external`, `meetingLink` populated.

---

### B2 — Mock voice or video

| Step | Device A | Expected |
|------|----------|----------|
| 1 | New booking → **Voice** or **Video** | Mode visible (mock enabled) |
| 2 | Confirm → Join from detail | In-app mock join; no external browser |

**Pass:** `callProvider: mock`. Skip if staging policy is external-only.

---

### B3 — Teacher sees session

| Step | Device B (teacher) | Expected |
|------|-------------------|----------|
| 1 | Sign in as teacher from B1/B2 | Dashboard loads |
| 2 | View upcoming sessions | Session id, time, student match A's booking |

---

### B4 — Double-tap confirm

| Step | Device A | Expected |
|------|----------|----------|
| 1 | Start new booking → select slot | Confirm enabled |
| 2 | Rapid double-tap **Confirm** | One session only in My Sessions / Firestore |

---

### B5 — Stale device on booking

| Step | Device A | Device B | Expected |
|------|----------|----------|----------|
| 1 | Student signed in; open booking confirm screen | — | Flow open |
| 2 | — | Sign in **same student** account | B active |
| 3 | Tap Confirm on A | — | Rejected or A signed out; **no** new session |

Same as T6 — epoch enforcement.

---

## Part B — Single active device (T2–T8)

Use a dedicated test account (not production user). Enable notifications.

### T2 — Login second device

| Step | A | B | Expected |
|------|---|---|----------|
| 1 | Sign in | — | OK |
| 2 | — | Sign in same account | B active |
| 3 | Observe A | — | "Signed in elsewhere" → login screen ≤30s |

---

### T5 — A offline at B login

| Step | A | B | Expected |
|------|---|---|----------|
| 1 | Sign in → **airplane mode** | — | Offline |
| 2 | — | Sign in same account | B active |
| 3 | Disable airplane, resume app | — | A signs out on foreground |

---

### T6 — A mid-booking

| Step | A | B | Expected |
|------|---|---|----------|
| 1 | Open booking flow (slot picker) | — | Open |
| 2 | — | Sign in same account | B active |
| 3 | Attempt confirm on A | — | Blocked / sign out |

---

### T7 — Teacher approval push

| Step | A | B | Expected |
|------|---|---|----------|
| 1 | Sign in as **pending teacher** applicant | — | Application submitted |
| 2 | — | Sign in same account | B active; A revoked |
| 3 | Admin approves application | — | Push on **B only** |

---

### T8 — Re-login after B logout

| Step | A | B | Expected |
|------|---|---|----------|
| 1 | (revoked from prior test) | Signed in | B active |
| 2 | — | Sign out | B cleared |
| 3 | Sign in on A | — | A works |
| 4 | — | Sign in again | B wins; A revoked |

---

## Part C — Session lifecycle (single device OK)

Run on Device A after B1 booking exists.

| # | Action | Expected |
|---|--------|----------|
| 1 | Session detail shows locked-at-booking provider footnote | Visible |
| 2 | Request reschedule → teacher accepts on B | Requester pull-to-refresh shows new time |
| 3 | Cancel inside policy window (see Part C2 MN1) | Status cancelled; join disabled |
| 4 | Report concern (≥20 chars) | Success |
| 5 | External join within join window | Sheet → browser |

---

## Part C2 — Min-notice student cancellation (My Sessions)

**Policy source:** `session_cancel_eligibility_policy.dart` + `ConfigurableCancellationPolicy` (staging teachers typically `minNoticeMinutes: 120` — see [staging_teacher_seed_example.md](./staging_teacher_seed_example.md)).

**Intentional UX (do not file as defect):**

| Actor | Surface | Rule |
|-------|---------|------|
| **Student** | My Sessions list card + session detail | Cancel available only while lifecycle is `scheduled`, `confirmed`, or `rescheduled` **and** session start is still **outside** the min-notice window |
| **Student** | Same surfaces | After min-notice cutoff (`cancellation_blocked_within_notice`), cancel is **hidden/disabled** on My Sessions — matches session detail |
| **Student** | Pending tutor approval | Cancel always allowed (no min-notice guard) — Part F6 |
| **Tutor** | Dashboard upcoming card / session detail | Separate teacher rules (`canTeacherCancelSession`): `scheduled` / `confirmed` only — **not** gated by student min-notice — Part F4b |

**QA must verify both paths** on the same booked session (prefer start time far enough ahead to wait, or seed near-future slot + admin clock adjust only if ops policy allows). For one session: confirm cancel **visible** at MN1 without tapping Confirm if you need the same booking for MN2 after the window elapses.

| ID | Scenario | How to trigger | Expected |
|----|----------|----------------|----------|
| MN1 | **Before min-notice cutoff** | Book session with `startsAt` well beyond `minNoticeMinutes`; open **My Sessions** while still outside window | Cancel visible on list card **and** session detail; confirm sheet → `cancelled_by_student`; join disabled |
| MN2 | **After min-notice cutoff** | Same session once inside min-notice window (elapsed time or permitted clock adjust) | Cancel **hidden/disabled** on My Sessions **and** session detail; no student cancel CF from UI |
| MN3 | **Tutor cancel (separate rule)** | After F2 accept, tutor cancels from dashboard (F4b) | Tutor cancel still available per teacher policy even when student min-notice would block student cancel |

**Pass:** MN1 and MN2 both exercised on one session; student surfaces stay in sync; tutor path verified separately (MN3 or F4b).

---

## Part D — Booking / provider gates (single device)

Build variants for negative paths. Use separate APK installs or rebuild between rows.

### D1 — Booking disabled

| Step | Setup | Expected |
|------|-------|----------|
| 1 | Build with `--dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=false` (staging distribution OK) | App launches |
| 2 | Open teacher profile from browse | No book CTA / booking route redirects |
| 3 | Deep-link to booking route (if applicable) | Redirect home or sessions list |

**Pass:** No new bookings created; browse may still work if `QURAN_SESSIONS_ENABLED=true`.

---

### D2 — Provider disabled (voice/video)

| Step | Setup | Expected |
|------|-------|----------|
| 1 | Firestore `enabledCallProviders: ["external"]` only (remove `mock`) | Config saved |
| 2 | Rebuild APK with `TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=external` | Install |
| 3 | Attempt **voice** or **video** booking | CF error / UI blocks confirm (`unsupported_call_provider`) |
| 4 | **External** booking still works | B1 path OK |

**Pass:** Server rejects voice/video when provider not in Firestore array. Restore `mock` for B2 after test.

---

### D3 — Slot already booked

| Step | Device A | Expected |
|------|----------|----------|
| 1 | Book a specific slot (note start time) | Success |
| 2 | Sign in as **second student** (or same after cancel denied) | Browse OK |
| 3 | Open same teacher → same slot time | Slot greyed / unavailable / CF rejects on confirm |

**Pass:** No double booking for same teacher slot window.

---

## Part E — Session join UI states (Device A)

Source: `session_join_ui_state.dart` + session detail screen. Use a booked session from B1/B2; adjust device clock **only** if policy allows (prefer waiting or seed session with near-future `startsAt` via admin CF).

| ID | Scenario | How to trigger | Expected UI |
|----|----------|----------------|-------------|
| J1 | **Not started** | Open detail well before join window (`prefetchLeadTime` before start) | Join disabled; "not started" / countdown messaging |
| J2 | **Join available** | Open detail within join window before start | Join CTA enabled |
| J3 | **Joining** | Tap Join → observe in-flight | Loading / joining state; no double-tap |
| J4 | **Join failure** | Agora path without secrets, or airplane mode at token fetch | Error message; retry available |
| J5 | **Joined / opened** | Complete external join (B1) or mock join (B2) | Join shows opened / in progress |
| J6 | **Cancel** | Scheduled session, outside min-notice window → Cancel (Part C2 MN1) | Confirm sheet → status cancelled; join disabled |
| J6b | **Cancel blocked** | Same session inside min-notice window (Part C2 MN2) | Cancel hidden/disabled on detail (and My Sessions) |
| J7 | **Ended** | Session past join window + grace | Join disabled; ended messaging |
| J8 | **Cancelled** | After J6 or teacher cancel | Cancelled badge; join disabled |

**Voice/video book+join (explicit):**

| ID | Mode | Pass |
|----|------|------|
| V1 | Book **voice** → Join | `callProvider: mock` (or `agora` if Agora extension enabled) |
| V2 | Book **video** → Join | Same as V1 with video segment selected |
| E1 | Book **external** → Join | Browser opens `meetingLink` / teacher URL (B1) |

Student cancel policy: Part C2 (`session_cancel_eligibility_policy.dart`). Tutor cancel: F4b (teacher lifecycle rules, not student min-notice).

---

## Part F — Teacher approval (`requiresTutorApproval`)

**Prereqs:** Deploy `respondToBookingRequest`, `createSessionBooking`, `expirePendingReservations` + P1 indexes; set Firestore `quran_session_platform_config/global.quranTutorBookingMode` to `requiresTutorApproval` ([approval_deploy_qa_checklist.md](./approval_deploy_qa_checklist.md)). Same staging APK as Setup — mode is server-side, not dart-define on release builds.

Revert to `autoConfirm` after F9 smoke (Parts A–E regression).

### F1 — Student request (pending, Arabic copy, no join)

| Step | Device A (student) | Expected |
|------|-------------------|----------|
| 1 | Book verified teacher → slot → **External** or **Voice** → Confirm | Toast/title **تم إرسال طلب الحجز**; subtitle **في انتظار موافقة المحفظ** (not `تم تأكيد الحجز`) |
| 2 | My Sessions → open request | Status pending; **Join disabled** |
| 3 | Session detail | No join CTA; pending banner |

**Pass:** Firestore `lifecycleStatus: pending_tutor_approval`; slot locked.

### F2 — Tutor accept (voice)

| Step | Device A | Device B (teacher) | Expected |
|------|----------|-------------------|----------|
| 1 | Submit **voice** booking request | — | Pending on A |
| 2 | — | Dashboard → **طلبات قيد الانتظار** → **Accept** | Request leaves pending list |
| 3 | Pull-to-refresh My Sessions | — | **تم قبول الحصة**; join available in window |
| 4 | Join (mock) when window open | Join from upcoming card | In-app mock join |

**Pass:** `lifecycleStatus: scheduled`; `callProvider: mock` (if mock enabled).

### F3 — Tutor accept (video)

Same as F2 with **video** call type selected at book time.

### F4 — Tutor reject (with / without reason)

| Step | Device A | Device B | Expected |
|------|----------|----------|----------|
| 1 | New booking request | — | Pending on A |
| 2 | — | Dashboard → **رفض الحصة** → sheet **رفض طلب الحجز؟** → **رفض الطلب** (no reason) | Request removed from pending |
| 3 | Refresh My Sessions on A | — | **اعتذر المحفظ عن قبول الحصة** + **يمكنك اختيار موعد آخر**; join disabled; slot available again |
| 4 | Repeat with new request | Reject with reason **الموعد غير مناسب** | Same as step 3 + reason visible on session detail |

**Pass:** `lifecycleStatus: rejected_by_tutor`; optional `rejectionReason` when provided; lock released.

### F4b — Tutor cancel from upcoming card

| Step | Device B | Expected |
|------|----------|----------|
| 1 | After F2 accept, open **⋮** on upcoming session card → **إلغاء الحصة** | Same confirm dialog as session detail |
| 2 | Confirm cancel | Card removed from upcoming; dashboard refreshes |
| 3 | Device A refresh | **اعتذر المحفظ عن إلغاء الحصة**; join disabled |

**Pass:** `lifecycleStatus: cancelled_by_teacher`; same cancel flow as detail (no duplicate logic).

### F5 — Double book (approval mode)

| Step | Device A | Device B / second student | Expected |
|------|----------|---------------------------|----------|
| 1 | Student 1 requests slot (pending, not yet accepted) | — | Pending + lock |
| 2 | Student 2 same teacher + same slot | Attempt book | Slot unavailable / CF `already-exists` |

Same invariant as D3 while pending holds hard lock.

### F6 — Student cancel pending

| Step | Device A | Expected |
|------|----------|----------|
| 1 | Submit request; stay pending | Pending visible |
| 2 | Session detail → **Cancel** | Confirm → `cancelled_by_student`; slot released |
| 3 | Teacher dashboard refresh | Request gone |

### F7 — Provider disabled (voice/video)

With `enabledCallProviders: ["external"]` only (D2 setup), attempt **voice** or **video** request while `requiresTutorApproval` — CF/UI blocks (`unsupported_call_provider`). **External** request still works.

### F8 — Pending expiry (optional)

If slot start passes with no tutor action: within ~5 min after `startsAt`, booking → `expired`, slot released. Prefer seeded near-future slot + wait, or skip if timeboxed.

### F9 — `autoConfirm` smoke (regression)

Set Firestore `quranTutorBookingMode: autoConfirm`. Repeat B1 book → immediate **تم تأكيد الحجز** / `scheduled` without tutor accept step.

---

## Sign-off table

| ID | Tester | Date | Pass | Notes |
|----|--------|------|------|-------|
| B1 | | | ⬜ | |
| B2 | | | ⬜ | |
| B3 | | | ⬜ | |
| B4 | | | ⬜ | |
| B5 | | | ⬜ | |
| D1 | | | ⬜ | Booking disabled |
| D2 | | | ⬜ | Provider disabled |
| D3 | | | ⬜ | Slot booked |
| J1–J8, J6b | | | ⬜ | Join lifecycle + min-notice cancel block |
| MN1–MN3 | | | ⬜ | Min-notice cancel (Part C2) |
| V1 | | | ⬜ | Voice book+join |
| V2 | | | ⬜ | Video book+join |
| E1 | | | ⬜ | External book+join (= B1) |
| T2 | | | ⬜ | |
| T5 | | | ⬜ | |
| T6 | | | ⬜ | |
| T7 | | | ⬜ | |
| T8 | | | ⬜ | |

| F1 | | | ⬜ | Student pending request |
| F2 | | | ⬜ | Tutor accept voice |
| F3 | | | ⬜ | Tutor accept video |
| F4 | | | ⬜ | Tutor reject (with/without reason) |
| F4b | | | ⬜ | Card cancel from dashboard |
| F5 | | | ⬜ | Double book (approval) |
| F6 | | | ⬜ | Student cancel pending |
| F7 | | | ⬜ | Provider disabled |
| F8 | | | ⬜ | Pending expiry (optional) |
| F9 | | | ⬜ | autoConfirm smoke |

**Recorder:** _______________  
**Build:** version `_____` (`_____`) · Firebase project `_______________`  
**Verdict:** ⬜ Go &nbsp;|&nbsp; ⬜ No-Go

File defects with scenario ID, build number, account role, repro steps.

---

## Agora extension (optional — not stable v1 default)

When staging Agora path is enabled ([provider_config_checklist.md](./provider_config_checklist.md)):

1. Rebuild APK with `external,mock,agora` + App ID
2. Set Firestore `enabledCallProviders` to include `agora`
3. **New** voice/video booking (not legacy mock session)
4. Both devices join within window — audio/video connects via Agora

Record separately from B2 mock pass.
