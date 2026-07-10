# Staging QA join-window bypass

Maestro staging accounts can join Quran sessions **outside the normal join window** (15 minutes before `startsAt` through `endsAt`). This is a QA-only override — not production behavior.

## Scope

| Gate | Requirement |
|------|-------------|
| Environment | `TILAWA_DISTRIBUTION=staging` or `local`, or Firebase project `quran-playera-app` |
| Blocked | `production`, `play_production` |
| Accounts | Hardcoded uids in `STAGING_QA_JOIN_WINDOW_BYPASS_UIDS` (Maestro teacher + student) |
| Skipped | Join-window timing only |
| Enforced | Lifecycle (cancelled, completed, …), participant role, session epoch, RTC provider |

## Implementation

- **Functions:** `stagingQaJoinWindowBypass.ts`, `isWithinJoinWindowOrQaBypass()` in `sessionJoinWindowPolicy.ts`
- **Flutter:** `staging_qa_join_window_bypass.dart`, mirrored in `SessionJoinWindowPolicy` / `SessionJoinPolicy` / `resolveSessionJoinUiState`

## Logging

Cloud Functions emit `[QA] join-window bypass applied for uid=…` when the override applies. Flutter logs the same prefix via `dart:developer` under `quran_sessions.qa_join_window`.

## Maestro

See [`.maestro/quran_sessions/README.md`](../../.maestro/quran_sessions/README.md).
