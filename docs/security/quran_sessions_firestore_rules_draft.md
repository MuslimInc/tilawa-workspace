# Quran Sessions — Firestore security rules draft (NOT DEPLOYED)

Status: **draft for review**. Do not deploy as-is. Step 1 (read-only config:
`quran_session_market_configs`, its `cities` subcollection, and
`quran_session_platform_config/{configId}`) is already deployed separately.

This document covers the remaining write-bearing collections added in commit
`985e0ee6`. The strong recommendation is that **every high-integrity write moves
to a Cloud Function** (Admin SDK bypasses rules), and the deployed client rules
deny those writes. The "client-side rule" variants below are provided only as a
fallback if a given operation is consciously accepted as client-trusted.

Helper functions assumed (already in `firestore.rules`): `isSignedIn()`,
`isOwner(userId)`. Additional helpers proposed:

```
function isAdmin() {
  // Requires custom claim set by an admin tool / Cloud Function.
  return isSignedIn() && request.auth.token.admin == true;
}
function incomingUnchanged(field) {
  return request.resource.data[field] == resource.data[field];
}
```

Field reference (from the data sources):

- `quran_teacher_applications/{id}`: `userId`, `status` ∈
  {pending, approved, rejected, suspended, revoked}, `reviewedBy`, `reviewedAt`,
  `rejectionReason`, profile fields.
- `quran_teacher_profiles/{teacherId}`: `userId`, `verificationStatus`
  (e.g. `verified`), `isActive`, profile/pricing metadata.
  - `.../availability/{slotId}`: `teacherId`, `startsAt`, `endsAt`, `isBooked`,
    `status` ∈ {open, booked}.
  - `.../pricing/{marketId}`: price/commission data.
- `quran_bookings/{bookingId}`: `studentId`, `teacherId`, `slotId`, `status`
  ∈ {confirmed, cancelled}, `pricingType`, `paymentReference`.
- `quran_sessions/{sessionId}`: `bookingId`, `studentId`, `teacherId`,
  `status` ∈ {scheduled, cancelled, ...}, `meetingLink`.

---

## 1. `quran_teacher_applications/{applicationId}`

1. **Client read:** applicant reads their own application(s); admins read all.
   Queries filter `where('userId', ==, uid)`.
2. **Client write:** applicant may create and edit their *own* draft while
   `status == 'pending'`. Status transitions to approved/rejected/suspended/
   revoked must NOT be client-writable.
3. **Ownership:** `request.resource.data.userId == request.auth.uid` on create;
   `resource.data.userId == request.auth.uid` on update.
4. **Status checks:** create must be `status == 'pending'`; applicant updates
   must keep `status` unchanged (or remain `pending`) and must not set
   `reviewedBy`/`reviewedAt`.
5. **Client writes safe?** Create/edit of own pending application: yes.
   Moderation transitions (approve/reject/suspend/revoke): **no**.
6. **Move to Cloud Functions?** Yes — `approve/reject/suspend/revoke` + setting
   `reviewedBy` must be a callable Cloud Function gated on an admin claim. The
   client repository methods that perform these writes must be re-pointed at the
   function, not direct Firestore.
7. **Proposed rule:**

```
match /quran_teacher_applications/{applicationId} {
  allow read: if isAdmin()
    || (isSignedIn() && resource.data.userId == request.auth.uid);

  // Applicant creates their own pending application.
  allow create: if isSignedIn()
    && request.resource.data.userId == request.auth.uid
    && request.resource.data.status == 'pending'
    && !('reviewedBy' in request.resource.data)
    && !('reviewedAt' in request.resource.data);

  // Applicant edits own application only while pending; cannot self-review.
  allow update: if isSignedIn()
    && resource.data.userId == request.auth.uid
    && resource.data.status == 'pending'
    && incomingUnchanged('userId')
    && request.resource.data.status == 'pending'
    && incomingUnchanged('reviewedBy');

  allow delete: if false; // never client-deletable

  // Moderation transitions are performed by Cloud Functions (Admin SDK),
  // which bypass these rules. No client status-change path exists.
}
```

8. **Security risks:** if `update` allowed arbitrary `status`, any user could
   self-approve into a teacher. Cooldown logic (rejected-then-reapply) is
   enforced in app code today — that is bypassable client-side and should also
   move server-side.
9. **Recommendation:** Ship the rule above (own pending CRUD only). Build a
   `reviewTeacherApplication` Cloud Function for all moderation transitions.

---

## 2. `quran_teacher_profiles/{teacherId}`

1. **Client read:** public/authenticated read — students browse verified,
   active teachers (`where('verificationStatus','==','verified')`,
   `where('isActive','==', true)`).
2. **Client write:** a teacher may edit descriptive fields of their *own*
   profile. `verificationStatus` and `isActive` must NOT be client-writable.
3. **Ownership:** `resource.data.userId == request.auth.uid` (profile doc id is
   a teacher id, owner identified by `userId`).
4. **Status checks:** updates must keep `verificationStatus` and `isActive`
   unchanged.
5. **Client writes safe?** Self-edit of bio/languages/specializations: yes,
   with the verification fields frozen. Verification changes: **no**.
6. **Move to Cloud Functions?** Yes for `verificationStatus`/`isActive` — these
   define trust and visibility; admin-only via function. Profile creation is
   ideally also a function triggered on application approval.
7. **Proposed rule:**

```
match /quran_teacher_profiles/{teacherId} {
  allow read: if isSignedIn();

  // Profile creation tied to approval — prefer Cloud Function. If client
  // create is allowed, it must be the owner and unverified by default.
  allow create: if isAdmin()
    || (isSignedIn()
        && request.resource.data.userId == request.auth.uid
        && request.resource.data.verificationStatus != 'verified'
        && request.resource.data.isActive == false);

  // Owner edits descriptive fields only; trust fields frozen.
  allow update: if isAdmin()
    || (isSignedIn()
        && resource.data.userId == request.auth.uid
        && incomingUnchanged('userId')
        && incomingUnchanged('verificationStatus')
        && incomingUnchanged('isActive'));

  allow delete: if false;

  // --- subcollections below ---
}
```

8. **Security risks:** client-writable `verificationStatus`/`isActive` lets any
   user mark themselves a verified, active teacher and appear in search.
9. **Recommendation:** Ship read + owner self-edit with frozen trust fields.
   Set `verificationStatus`/`isActive` exclusively from a Cloud Function on
   approval.

---

## 2a. `quran_teacher_profiles/{teacherId}/availability/{slotId}`

1. **Client read:** authenticated read (students view open slots; also read via
   `collectionGroup('availability')`).
2. **Client write:** the owning teacher manages their own slots. Marking a slot
   `isBooked` happens during a student booking — that must be server-side.
3. **Ownership:** owner = teacher whose `userId` owns the parent profile.
   Rules cannot cheaply read the parent doc on every write; prefer to store the
   owner uid on the slot, or gate slot writes behind a function.
4. **Status checks:** teacher self-writes should not flip `isBooked` true
   (booking does that); cancellation reopening also server-side.
5. **Client writes safe?** Teacher creating/removing their own *open* slots:
   borderline-safe only if owner uid is verifiable on the slot. Flipping
   `isBooked`: **no**.
6. **Move to Cloud Functions?** Yes for any `isBooked`/`status` transition
   (it is part of the booking transaction). Slot authoring by the teacher can
   stay client-side if an owner field is present.
7. **Proposed rule** (assumes slot stores `ownerUid` == teacher's auth uid):

```
match /quran_teacher_profiles/{teacherId}/availability/{slotId} {
  allow read: if isSignedIn();

  allow create, update: if isAdmin()
    || (isSignedIn()
        && request.resource.data.ownerUid == request.auth.uid
        // teacher may not self-mark a slot as booked
        && request.resource.data.isBooked == false);

  allow delete: if isAdmin()
    || (isSignedIn() && resource.data.ownerUid == request.auth.uid
        && resource.data.isBooked == false);

  // Booking/cancellation toggles isBooked via Cloud Function (Admin SDK).
}
```

   Note: today's slots are written without an `ownerUid`; add it, or deny all
   client writes here and route slot management through a function too.
8. **Security risks:** without an owner field, any signed-in user could edit any
   teacher's availability. Client-side `isBooked` toggling enables double-booking
   and slot griefing.
9. **Recommendation:** Add `ownerUid` to slots and ship the rule above, OR deny
   client writes entirely and manage slots via function. Booking-time
   `isBooked` flips must be server-side regardless.

---

## 2b. `quran_teacher_profiles/{teacherId}/pricing/{marketId}`

1. **Client read:** authenticated read (students see a teacher's price for a
   market).
2. **Client write:** none from clients.
3. **Ownership:** n/a (writes are admin/server).
4. **Status checks:** n/a.
5. **Client writes safe?** **No** — pricing/commission affects money.
6. **Move to Cloud Functions?** Yes — pricing/payout config is admin/server.
7. **Proposed rule:**

```
match /quran_teacher_profiles/{teacherId}/pricing/{marketId} {
  allow read: if isSignedIn();
  allow write: if false; // admin/server (Admin SDK) only
}
```

8. **Security risks:** client-writable pricing lets a user alter what they (or
   others) are charged or paid.
9. **Recommendation:** Read-only for clients; write via admin tools/functions.

---

## 3. `quran_bookings/{bookingId}`

1. **Client read:** the booking's student and teacher read it (queries filter
   `where('studentId','==',uid)`); admins read all.
2. **Client write:** today the client transaction creates the booking, sets
   `status: confirmed`/`pricingType`, AND mutates the teacher's slot + creates a
   session. This is the central integrity operation.
3. **Ownership:** student = `studentId`; teacher = `teacherId`.
4. **Status checks:** `status` transitions (confirmed → cancelled) must be
   controlled; clients must not invent `confirmed` with arbitrary pricing.
5. **Client writes safe?** **No.** A client write here also writes *another
   user's* availability slot and a session doc, and self-asserts pricing/status.
6. **Move to Cloud Functions?** **Yes — strongly.** A `createBooking` callable
   should: validate the slot is open, set pricing from market/teacher config
   (not client input), create booking + session, and mark the slot booked,
   atomically with the Admin SDK. Cancellation likewise via `cancelBooking`.
7. **Proposed rule:**

```
match /quran_bookings/{bookingId} {
  allow read: if isAdmin()
    || (isSignedIn() && (resource.data.studentId == request.auth.uid
                      || resource.data.teacherId == request.auth.uid));

  // Creation/cancellation handled by Cloud Functions (Admin SDK).
  allow write: if false;
}
```

8. **Security risks:** client create allows forged pricing (`pricingType:free`
   / arbitrary `paymentReference`), double-booking, writing sessions for others,
   and toggling another teacher's slots. Cross-document integrity cannot be
   guaranteed by rules alone.
9. **Recommendation:** Deny client writes; implement `createBooking` /
   `cancelBooking` Cloud Functions. Keep the owner-scoped read rule.

---

## 4. `quran_sessions/{sessionId}`

1. **Client read:** the session's student and teacher read it; admins read all.
2. **Client write:** none from clients (created/updated by the booking flow).
3. **Ownership:** student = `studentId`; teacher = `teacherId`.
4. **Status checks:** lifecycle (`scheduled` → completed/cancelled) is
   server-driven; `meetingLink` must not be client-settable.
5. **Client writes safe?** **No** — sessions are derived from bookings and carry
   the meeting link.
6. **Move to Cloud Functions?** Yes — sessions are created/updated by the same
   functions that own bookings.
7. **Proposed rule:**

```
match /quran_sessions/{sessionId} {
  allow read: if isAdmin()
    || (isSignedIn() && (resource.data.studentId == request.auth.uid
                      || resource.data.teacherId == request.auth.uid));

  allow write: if false; // created/updated by Cloud Functions (Admin SDK)
}
```

8. **Security risks:** client-writable sessions allow forging meeting links,
   fabricating sessions without a booking, or altering another user's session.
9. **Recommendation:** Deny client writes; manage via the booking functions.
   Keep owner-scoped read.

---

## Summary of recommendations

| Collection | Client read | Client write | Server (CF) |
|---|---|---|---|
| `quran_teacher_applications` | own + admin | own pending CRUD | approve/reject/suspend/revoke |
| `quran_teacher_profiles` | authed | own descriptive edits | create, verification/active |
| `.../availability` | authed | own open slots* | isBooked/cancellation toggles |
| `.../pricing` | authed | none | all writes |
| `quran_bookings` | student/teacher | none | create/cancel |
| `quran_sessions` | student/teacher | none | create/update |

\* only if an `ownerUid` field is added to slots; otherwise deny and route
through a function.

**Required before opening any writes:**

1. An `isAdmin()` claim mechanism (custom claims via an admin tool/function).
2. Cloud Functions for: teacher review, booking create/cancel, session
   lifecycle, slot `isBooked` toggles, pricing/payout writes.
3. Re-point the affected client repositories from direct Firestore writes to the
   callable functions.
4. Add `ownerUid` to availability slots if teacher self-management stays
   client-side.

Until the functions exist, the safest deployable posture for these six
collections is: **owner-scoped reads + `allow write: if false`**, so the feature
can read data while no integrity-sensitive client write path is exposed.
