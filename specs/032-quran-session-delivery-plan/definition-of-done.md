# Definition of Done — Quran Sessions

Applies to all user stories in [user-stories.md](./user-stories.md) unless explicitly waived in Sprint 0.

---

## Product DoD

- [ ] Acceptance criteria in story verified on **staging** (or production for release stories)
- [ ] UX matches [screen-inventory.md](../031-quran-session-blueprint/screen-inventory.md) screen ID
- [ ] User-visible strings in `packages/quran_sessions/l10n/` or app ARB (no new hardcoded Arabic in widgets)
- [ ] Free Beta scope respected — no paid/subscription UI shipped without flag + PSP
- [ ] Feature flag behavior documented if story touches `quran_sessions_feature_flags.dart`
- [ ] Analytics event added if new user-facing action (see `AnalyticsConstants`)
- [ ] Product owner sign-off on demo for P0 stories

---

## Engineering DoD (Flutter / Dart)

- [ ] Code in correct layer: domain in `packages/quran_sessions/`, Firebase in `apps/tilawa/lib/features/quran_sessions/`
- [ ] No `BuildContext` below presentation layer
- [ ] No Firebase imports in `packages/quran_sessions/`
- [ ] Server mutations via `SessionCommandGateway` / CF — no direct Firestore writes to bookings/sessions
- [ ] `Either<QuranSessionsFailure, T>` at repository boundaries — no thrown exceptions across layers
- [ ] Design tokens used — no hardcoded colors/sizes in new UI
- [ ] `dart analyze` clean for touched packages
- [ ] `flutter test` green for touched test files
- [ ] New domain logic has unit tests; P0 stories have tests per story spec
- [ ] DI registered in `QuranSessionsModule` (prod) and/or `QuranSessionsMvpModule` (fake)
- [ ] Routes use typed GoRouter patterns; auth UID from `requireQuranSessionsUserId`
- [ ] PR description links story ID (e.g. US-008)

---

## Backend DoD (Cloud Functions / Firestore)

- [ ] Callable changes in `functions/src/quranSessions/` with auth check via `sessionAuth.ts`
- [ ] Lifecycle transitions pass `sessionLifecycleGuard.ts` — no invalid transitions
- [ ] Idempotency for financial and booking operations (`idempotencyService.ts`)
- [ ] Audit/event written for state-changing operations where schema exists
- [ ] `npm run build` succeeds in `functions/`
- [ ] `npm test` + `npm run test:integration` + `npm run test:rules` green for touched paths
- [ ] Firestore rules updated if new collections/fields — rules tests added
- [ ] Deployed to **staging** before story marked done (prod deploy per release checklist only)
- [ ] No secrets in repo; PSP keys in Secret Manager (Paid phase)

---

## Admin UI DoD (`apps/tilawa_admin`)

- [ ] Mutations invoke CF facade — no direct Firestore writes for session/booking lifecycle
- [ ] Admin claim required; unauthorized returns clear error
- [ ] List screens paginate or limit query cost
- [ ] Session detail links to related booking/report/dispute IDs
- [ ] Manual QA on staging with admin test account
- [ ] Angular build passes for touched components

---

## QA DoD

- [ ] Test cases from story "Tests Required" executed and recorded
- [ ] P0: unit + integration or emulator path covered
- [ ] Regression: existing `packages/quran_sessions` tests still green
- [ ] Manual device check on at least one Android device for UI stories
- [ ] RTL + dark mode spot-check for new screens
- [ ] Defects: no open P0; P1 documented with workaround if shipping
- [ ] QA sign-off comment on story/ticket

---

## Release DoD (Sprint 7–8 only)

- [ ] Staging smoke 10/10 ([production-readiness-p0.md](../030-quran-sessions-domain/production-readiness-p0.md))
- [ ] Backfill dry-run reviewed; apply signed by ops
- [ ] Rollback drill executed ([rollback-plan.md](./rollback-plan.md))
- [ ] Version bumped; changelog updated ([release-checklist.md](./release-checklist.md))
- [ ] Play Console listing complete ([google-play-release-plan.md](./google-play-release-plan.md))
- [ ] Feature flags: prod booking enable plan approved
- [ ] Sentry/monitoring alerts active
- [ ] Free Beta Go/No-Go meeting held — decision recorded in README metrics

---

## Story-type shortcuts

| Story type | Minimum DoD |
|------------|-------------|
| Domain unit test only (US-061) | Tests + analyze |
| CF only | functions tests + staging deploy |
| Mobile UI only | widget test or manual QA + analyze |
| Admin UI only | admin build + manual QA |
| Release (US-068+) | Release DoD full set |

---

## Explicit exclusions (Beta)

These are **not** required for Free Beta Done:

- PaymentProvider implementation
- Automated PSP refunds
- Teacher payout processing
- Guardian linking UI
- Agora/WebRTC in-app calls
- EN l10n 100% (P2 — Production)
- Maestro E2E in CI (nice-to-have)
- Public teacher review list with moderation
