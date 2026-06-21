# ADR-002: Quran Sessions — Backend-Agnostic Architecture

**Status:** Accepted  
**Date:** 2026-06-21  
**Deciders:** Engineering team

---

## Context

The Quran Sessions feature requires a backend for teacher profiles, bookings,
availability, market configuration, and user profiles. Firebase (Firestore +
Auth) is the current implementation target for the MVP. However, the long-term
backend is undecided — candidates include NestJS, Laravel, ASP.NET, Supabase,
custom REST APIs, and GraphQL APIs.

Coupling the domain layer to Firebase would make any future migration expensive
and risky. This ADR defines the boundary rules that keep Firebase as a swappable
implementation detail.

---

## Decision

Firebase is **an implementation detail**, not an architectural dependency.
It lives exclusively in the **data layer** (datasources, DTOs, repository
implementations). All layers above that boundary depend only on abstractions.

### Layer permissions

| Layer | May depend on Firebase? | Notes |
|---|---|---|
| `domain/entities/` | No | Pure Dart value objects; no SDK types |
| `domain/repositories/` | No | Abstract interfaces only |
| `domain/usecases/` | No | Depend on repository interfaces via constructor injection |
| `presentation/blocs/` | No | Depend on use cases only |
| `data/dtos/` | Yes | May mirror backend document shapes in comments |
| `data/datasources/` | Yes | Abstract interfaces defined here; Firebase implementations live in the host app or a `firebase_impl` package |
| `data/repositories/*_impl.dart` | Yes | Concrete implementations; wired by DI |
| `di/` (host app) | Yes | Controls which implementation is injected |

### Specific rules

1. **No Firebase SDK imports above `data/`.**  
   Forbidden in entities, use cases, blocs, and domain repositories:
   `firebase_auth`, `cloud_firestore`, `firebase_core`.

2. **Firebase UID is never passed raw through use cases.**  
   Current user identity is accessed through `UserProfileRepository` or a
   dedicated `CurrentUserProvider` abstraction. Use cases receive a `userId`
   string — they do not call `FirebaseAuth.instance.currentUser`.

3. **Firestore document models are separate from domain entities.**  
   DTOs (e.g., `QuranTeacherDto`, `QuranBookingDto`) are mapped to domain
   entities (e.g., `QuranTeacher`, `QuranBooking`) in `data/mappers/`.
   The domain layer never sees DTO types.

4. **DI controls backend selection.**  
   `QuranSessionsModule.register(...)` accepts datasource implementations as
   parameters. Swapping the backend means providing different datasource
   implementations at registration time — no other code changes.

5. **Domain comments must not reference Firebase paths.**  
   Doc comments in `domain/` describe the concept, not the storage topology.
   Firestore collection paths belong in DTO or datasource comments only.

---

## Consequences

### Positive

- The domain and presentation layers are fully portable. A backend migration
  is scoped to: new datasource implementations + updated DI registration.
- Unit tests for use cases and blocs use fake repositories — they have no
  Firebase dependency and need no emulator.
- The package (`packages/quran_sessions`) has zero Firebase dependencies in
  its `pubspec.yaml`; Firebase packages are only in the host app.

### Negative / Trade-offs

- Firebase-specific features (real-time streams, offline persistence) cannot
  be used transparently — they must be exposed through repository abstractions
  (e.g., `Stream<QuranTeacher>` return types) if needed.
- More boilerplate: every backend change requires a new DTO ↔ entity mapper.

---

## How to replace the backend in the future

1. Implement the datasource interfaces from `packages/quran_sessions/lib/src/data/datasources/`:
   - `TeacherRemoteDataSource`
   - `SessionRemoteDataSource`
   - `BookingRemoteDataSource`
   - (and any new interfaces added since this ADR)

2. Implement any repository interfaces not yet covered
   (`MarketConfigRepository`, `SessionPolicyRepository`,
   `UserProfileRepository`) in the new backend package.

3. Update `QuranSessionsModule.register(...)` in the host app DI to inject
   the new implementations.

4. Delete the Firebase implementation files. No other files change.

---

## Related

- [ADR-001: Quran Player Root Overlay Route](001-quran-player-root-overlay-route.md)
- [ADR-003: Teacher Application Lifecycle](003-teacher-application-lifecycle.md) — teacher is a verified profile, not a role; `TeacherApplication` vs `TeacherProfile` separation; phone privacy; re-application policy
- [`packages/quran_sessions/lib/src/di/quran_sessions_module.dart`](../../packages/quran_sessions/lib/src/di/quran_sessions_module.dart)
- [`docs/architecture/navigation.md`](../architecture/navigation.md)
