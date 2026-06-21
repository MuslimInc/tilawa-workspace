# Quran Sessions — Teacher Application Write Model

> **Status:** Deployed (applicant rules) + Cloud Function moderation  
> **Related:** [ADR-003](../adr/003-teacher-application-lifecycle.md) · [ADR-004](../adr/004-teacher-application-intake-vs-marketplace-activation.md) · [firestore.rules](../../firestore.rules)

---

## Collections

| Collection | Client read | Client write | Server write |
|------------|-------------|--------------|--------------|
| `quran_teacher_applications/{id}` | Applicant (own) + admin claim | Applicant draft CRUD → submit pending | Admin CF / scripts |
| `quran_teacher_profiles/{id}` | Authenticated (query filters verified+active) | **Denied** | Admin CF on approve |

---

## Applicant transitions (client-allowed)

```
(none) → create draft
draft → update draft
draft → submit pending (sets submittedAt)
```

**Forbidden on client:**

- `pending` → `approved` / `rejected` / …
- Setting `reviewedBy`, `reviewedAt` on create/update
- Creating `quran_teacher_profiles` directly

---

## Admin transitions (Cloud Function / Admin SDK)

Callable: `reviewTeacherApplication`

| Action | Application status | TeacherProfile |
|--------|-------------------|----------------|
| `approve` | `approved` | Create/update verified + `isActive: true` |
| `reject` | `rejected` | No profile (or leave inactive) |
| `suspend` | `suspended` | `isActive: false` |
| `revoke` | `revoked` | `isActive: false` |

Requires ID token custom claim `{ admin: true }`.

---

## MVO scripts (no in-app admin UI)

From `functions/`:

```sh
npm run admin:list-pending-applications
npm run admin:review-teacher-application -- --applicationId=ID --action=approve
```

---

## Privacy

- `phoneNumber` on applications: applicant + admin only — never on `TeacherProfile` or student screens.
- Applications are not publicly readable.

---

## Checklist before `teacherApplicationEnabled=true`

- [ ] **Deploy Firestore rules** — `firebase deploy --only firestore:rules` (applicant draft create/update must be live)
- [ ] Applicant submit works in staging/production Firebase
- [ ] Applicant status screen reads own application
- [ ] Operator can list pending (`admin:list-pending-applications`)
- [ ] Operator can approve/reject (`admin:review-teacher-application` or CF)
- [ ] Approved profile appears in teacher list query (verified + active)
- [ ] Review owner + SLA documented
- [ ] Kill switch tested (`TILAWA_LAUNCH_TEACHER_APPLICATION_ENABLED=false`)
