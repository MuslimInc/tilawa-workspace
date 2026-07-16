---
name: Edit Profile KISS
overview: Minimal Edit Profile for authenticated Students and Teachers — change/remove display name and avatar, reuse existing code, no architecture redesign.
todos: []
isProject: false
---

# Edit Profile (KISS)

**Goal:** Allow authenticated Students and Teachers to edit their profile.

**Scope:**
- Change display name.
- Change profile picture.
- Remove profile picture.

**Constraints:**
- Follow the KISS principle.
- Reuse existing code whenever possible.
- Do not redesign the architecture.
- Do not introduce unnecessary layers.
- Keep the implementation minimal and production-ready.

---

## 1. Current implementation

- Account already has `displayName` and `photoUrl` ([`UserEntity`](apps/tilawa/lib/features/auth/domain/entities/user_entity.dart)).
- Set at registration / Google sign-in via [`UserRepositoryImpl`](apps/tilawa/lib/features/auth/data/repositories/user_repository_impl.dart).
- Shown in Settings with [`SettingsProfileHeader`](apps/tilawa/lib/features/settings/presentation/widgets/settings_widgets.dart) and [`ProfileAvatar`](apps/tilawa/lib/shared/widgets/profile_avatar.dart).
- Guest header opens login; signed-in header does nothing (`onTap: null`).
- Teachers can edit public marketplace name on [`CompleteTeacherPublicProfileScreen`](packages/quran_sessions/lib/src/presentation/screens/complete_teacher_public_profile_screen.dart); save already accepts `avatarUrl` but UI never sets a photo.
- `image_picker` is already a dependency.

---

## 2. Missing pieces

- Edit Profile UI (name + photo).
- Entry from Settings (signed-in header tap).
- Update Auth + `users/{uid}` name/photo after registration.
- Pick image → store → set URL; or clear URL on remove.
- If teacher public profile exists: set existing `avatarUrl` to the same URL.

---

## 3. Simplest user flow

Settings → Edit Profile → Save.

---

## 4. Required UI changes

- Signed-in [`SettingsProfileHeader`](apps/tilawa/lib/features/settings/presentation/widgets/settings_widgets.dart) opens Edit Profile.
- One small screen/sheet: avatar, name field, Save.
- Avatar actions: change photo / remove photo (`image_picker`).

---

## 5. Required data changes

Only what existing fields already support:

- Update Auth `displayName` / `photoURL`.
- Update `users/{uid}` `displayName` / `photoUrl`.
- Store image; use download URL as `photoUrl` (reuse Storage; no new user fields).
- If teacher profile exists: write same URL to existing `avatarUrl`.

No new collections or backend services.

---

## 6. Existing code to reuse

| Piece | Role |
|-------|------|
| [`ProfileAvatar`](apps/tilawa/lib/shared/widgets/profile_avatar.dart) / [`TilawaProfileAvatar`](packages/ui_kit/lib/src/molecules/tilawa_profile_avatar.dart) | Avatar preview |
| [`SettingsProfileHeader`](apps/tilawa/lib/features/settings/presentation/widgets/settings_widgets.dart) | Entry |
| [`UserEntity`](apps/tilawa/lib/features/auth/domain/entities/user_entity.dart) + Auth state | Current values; refresh after save |
| [`UserRepositoryImpl`](apps/tilawa/lib/features/auth/data/repositories/user_repository_impl.dart) | Same write pattern as sign-in for name/photo |
| `image_picker` | Pick photo |
| [`SaveTeacherPublicProfileUseCase`](packages/quran_sessions/lib/src/domain/usecases/save_teacher_public_profile_usecase.dart) / teacher profile write | Pass `avatarUrl` (already supported) |
|]
