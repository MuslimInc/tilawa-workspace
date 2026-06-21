# Future Backend Migration Strategy (Admin)

Firebase is an infrastructure adapter, not an architectural dependency.

## Swap checklist

1. Implement repository interfaces against REST/GraphQL:
   - `TeacherApplicationRepository.list/getById`
   - `TeacherProfileRepository.list/getById`
   - `QuranSessionsUserRepository.list/getById/getByIds`
2. Implement `ModerationGateway` against admin API endpoints (same action names).
3. Implement `AuthSessionRepository` against new auth (JWT/session).
4. Update `app.config.ts` providers only.

## Unchanged

- Feature components and templates
- Facades and use cases
- Route definitions
- ViewModels

## API shape recommendation

Design future admin APIs to mirror current gateway methods so the Angular `ModerationGateway` interface maps 1:1.
