# Teacher Review Workflow

1. Applicant submits application (`pending`) from Tilawa app.
2. Admin opens **Quran Sessions → Teacher Applications**.
3. Admin opens detail view (PII: phone, rejection history).
4. Admin action invokes **`reviewTeacherApplication`** callable (not Firestore write).
5. On approve: Cloud Function creates `quran_teacher_profiles/{id}`.
6. Teacher appears in student catalog when `verificationStatus=verified` and `isActive=true`.

Ops fallback (MVO): `npm run admin:list-pending-applications` and `admin:review-teacher-application`.
