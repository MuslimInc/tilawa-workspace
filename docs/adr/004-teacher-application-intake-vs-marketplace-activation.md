# ADR-004: Teacher Application Intake vs Marketplace Activation

**Status:** Accepted  
**Date:** 2026-06-21  
**Deciders:** Product, Engineering  
**Related:** [ADR-003](003-teacher-application-lifecycle.md)

---

## Context

Quran Sessions is a two-sided marketplace inside MeMuslim. Students discover teachers and book sessions; teachers apply, are reviewed, and only then become visible supply.

Early discussions conflated two different activations:

1. **Teacher application intake** — collecting and moderating teacher candidates.
2. **Marketplace activation** — approved teachers visible to students and booking enabled.

Blocking application intake until full marketplace maturity slows supply generation without improving student safety.

---

## Decision

**Decouple intake from marketplace activation.**

| Capability | Gate |
|------------|------|
| Learn Quran (student shell) | `quranSessionsEnabled` |
| Teacher apply + status | `teacherApplicationEnabled` + MVO ops ready |
| Teacher discoverability (Profile + empty-state CTA) | `teacherApplicationDiscoverability` |
| Student booking | `quranSessionsBookingEnabled` + approved supply |

### Product rules

1. Learn Quran remains **student-first** (Option D hybrid).
2. **Profile / Settings** is the canonical teacher onboarding entry.
3. Learn Quran **empty state** may show a calm secondary CTA: *"هل ترغب في تدريس القرآن؟"*
4. Never show unapproved teachers in browse lists.
5. **Pending** applicants see **application status only** — not Teacher Dashboard.
6. **Approved + active** teachers access Teacher Dashboard.

### Feature flags (host layer)

- `TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED` (default: true)
- `TILAWA_LAUNCH_TEACHER_APPLICATION_ENABLED` (default: false until MVO ops verified)
- `TILAWA_LAUNCH_TEACHER_APPLICATION_DISCOVERABILITY` (`none` | `profileOnly` | `profileAndEmptyState`)
- `TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED` (default: false until supply ready)

---

## Consequences

### Positive

- Supply pipeline can fill before student marketing scales.
- Student journey stays clear; teacher path is moderated and secondary at empty shelf.
- Booking and payments can lag without blocking teacher applications.

### Negative

- Ops must honor review SLA or applicant trust erodes.
- Two flags + discoverability enum require host wiring discipline.

---

## Security

- Applicant client writes: own `draft` → `pending` only (`firestore.rules`).
- Approve/reject/suspend/revoke: **Cloud Function** `reviewTeacherApplication` (admin claim) or Admin SDK scripts.
- `TeacherProfile` creation on approve is server-side only.

See [quran_sessions_teacher_application_write_model.md](../security/quran_sessions_teacher_application_write_model.md).
