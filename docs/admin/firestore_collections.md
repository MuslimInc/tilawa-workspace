# Quran Sessions Firestore Collections (Admin)

| Collection | Admin list | Admin detail join |
|------------|------------|-------------------|
| `quran_teacher_applications` | Direct query | — |
| `quran_teacher_profiles` | Direct query | — |
| `users` | Scan + filter `quranSessionsProfile` | Email, name, avatar, market fields |

Paths centralized in `apps/tilawa_admin/src/app/core/data/paths/quran-sessions.paths.ts`.

See [quran_sessions_firestore_data_model.md](../quran_sessions_firestore_data_model.md).
