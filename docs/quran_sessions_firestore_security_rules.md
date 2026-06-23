# Quran Sessions — Firestore Security Rules Checklist

> Rules are not deployed from this repo yet. Use this checklist when authoring
> `firestore.rules`.

## Users

- [ ] Authenticated user can read/write **only** their own `users/{uid}` document
- [ ] Authenticated user can read/write **only** their own `quranSessionsProfile` nested map
- [ ] No client write to `role: admin|moderator` without custom claims

## Market config

- [ ] All authenticated users: read `quran_session_market_configs` and `cities`
- [ ] Writes: admin/moderator only (Cloud Console or admin SDK)

## Teacher applications

- [ ] Applicant can read/write **only** applications where `userId == request.auth.uid`
- [ ] `phoneNumber` readable only by applicant and admin/moderator roles
- [ ] Students and public: **deny all** access

## Teacher profiles

- [ ] Public read: `verificationStatus == verified` AND `isActive == true`
- [ ] Teacher owner (`userId == auth.uid`): read/write own profile fields except verification status
- [ ] Admin/moderator: full read/write including approval fields
- [ ] Phone numbers: **never** stored on this document

## Availability

- [ ] Teacher owner can CRUD slots on their own profile subcollection
- [ ] Students: read non-booked slots on verified active teachers only
- [ ] Booking transaction (Cloud Function or rules + transaction): atomically set `isBooked`

## Bookings & sessions

- [ ] Student can create booking only with `studentId == auth.uid`
- [ ] Student can read/cancel own bookings and sessions
- [ ] Teacher can read sessions where `teacherId` matches their profile id
- [ ] No client-side payment fields without server validation (deferred)

## Admin approval

- [ ] Teacher profile must not appear in public queries until application approved
- [ ] Approval/rejection: admin/moderator only
