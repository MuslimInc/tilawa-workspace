# Quran Sessions — Migration: Fake Repositories → Firebase

## Current state

| Mode | DI entry | Auth UID |
|------|----------|----------|
| `fake` | `QuranSessionsMvpModule` | `FakeAuthSessionProvider('student_mvp')` |
| `firebase` (default when Firebase init enabled) | `QuranSessionsFirebaseModule` | `FirebaseAuthSessionProvider` |

Select via dart-define:

```sh
flutter run --dart-define=TILAWA_QURAN_SESSIONS_BACKEND=fake
flutter run --dart-define=TILAWA_QURAN_SESSIONS_BACKEND=firebase
```

## Layer map

| Layer | Firebase allowed? | Location |
|-------|-------------------|----------|
| Domain entities / use cases / BLoCs | **No** | `packages/quran_sessions/lib/src/domain`, `presentation` |
| Repository interfaces | **No** | `packages/quran_sessions/lib/src/domain/repositories` |
| Repository implementations | **No** (use datasources) | `packages/quran_sessions/lib/src/data/repositories` |
| Datasource interfaces + DTOs | **No** | `packages/quran_sessions/lib/src/data` |
| Firestore implementations | **Yes** | `apps/tilawa/lib/features/quran_sessions/data/firebase/` |
| DI wiring | **Yes** | `apps/tilawa/lib/features/quran_sessions/di/` |

## Replacing Firebase later

1. Implement the exported datasource interfaces (`UserProfileRemoteDataSource`, etc.) for the new backend.
2. Register via `QuranSessionsModule.register(...)` with new datasource instances.
3. Provide a new `AuthSessionProvider` (e.g. `RestAuthSessionProvider`).
4. Delete `apps/tilawa/lib/features/quran_sessions/data/firebase/` — **no** changes to domain, BLoCs, or UI.

## Seed data for Firebase dev

1. **Market configs (EG, SA, AE + cities):** from `apps/tilawa`:
   ```sh
   dart run lib/scripts/seed_market_configs.dart
   ```
   See [quran_sessions_market_config_sources.md](quran_sessions_market_config_sources.md).
   **Note:** the client seed script cannot write to production Firestore (rules
   deny client writes). Use the emulator, Firebase Console import, or Admin SDK.
2. Create `quran_session_platform_config/global` with age thresholds.
3. Seed verified `quran_teacher_profiles` + `availability` slots for booking tests.
4. Sign in with Google — profile shell auto-created on first Quran Sessions entry.

## Emulator backlog

- [ ] Firestore emulator integration test suite for booking transaction
- [ ] Auth emulator + rules unit tests with `@firebase/rules-unit-testing`
