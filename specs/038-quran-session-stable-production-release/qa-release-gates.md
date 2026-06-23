# QA Release Gates — Stable Production v1

## Automated gates (must pass)

Run from repo root:

```sh
./scripts/quran_sessions_preflight.sh
```

Includes:
- `dart analyze` on `packages/quran_sessions` + affected `apps/tilawa` paths
- Targeted Flutter tests (quran_sessions, auth, notifications, session guard)
- `functions` unit tests for quranSessions
- Optional: integration + rules tests (JDK 21)

### CI reference

- `pr-checks.yml` → `functions-emulator-tests` (unit + integration + rules)
- `melos run test` includes `packages/quran_sessions`

## Manual gates (must pass for Go)

Master sign-off: [docs/qa/quran_sessions_free_beta_signoff.md](../../docs/qa/quran_sessions_free_beta_signoff.md)

| ID | Scenario | Required |
|----|----------|----------|
| B1 | Student external booking + join | Yes |
| B2 | Mock voice/video join | Yes (if mock enabled) |
| B3 | Teacher sees upcoming session | Yes |
| B4 | Idempotency / double-tap | Yes |
| B5 | Stale device blocked on booking | Yes |
| T2 | Second device revokes first | Yes |
| T5 | Offline A signs out on B login | Yes |
| T6 | Stale device mid-booking | Yes |
| T7 | Teacher approval push active device | Yes |
| T8 | Re-login same device after B logout | Yes |

### Teacher onboarding E2E (add to stable sign-off)

| Step | Pass criteria |
|------|---------------|
| Admin approve pending teacher | Application `approved`, profile created |
| Teacher taps **متابعة** | Routes to dashboard or complete-profile |
| Settings row updates without kill-app | Dashboard title (not view-status loop) |
| Teacher cancel session | CF success; student notified |

## Regression gates

| Area | Check |
|------|-------|
| Paid path blocked | Attempt paid booking → rejected |
| Group path blocked | CF rejects group |
| Feature kill switch | `quranSessionsEnabled=false` → home redirect, footer hidden |
| Booking kill switch | `quranSessionsBookingEnabled=false` → book redirect |

## Release decision matrix

| Automated preflight | Manual B+T | Verdict |
|--------------------|------------|---------|
| ✅ | ✅ | **Stable Production Go** |
| ✅ | ❌ | **Conditional Go** (staging/closed only) |
| ❌ | — | **No-Go** |

## Staging smoke status (2026-06-24)

**Manual QA not executed in this milestone.** Engineering artifacts + P0 code fixes complete. Assign tester + record dates in sign-off table.

## Test coverage snapshot (honest)

| Layer | Approx. tests | Confidence |
|-------|---------------|------------|
| Package domain/presentation | ~85 files | High for booking/join/lifecycle |
| App quran_sessions | 10 files | Medium (repos, flags, launcher) |
| CF unit | 21 files | High |
| CF integration | ~35 cases | High for booking/auth/reports |
| Rules emulator | 20+ cases | Medium (expanded 038 for eligibility) |
| Maestro E2E | 0 quran sessions | None |

**lcov:** Run `flutter test --coverage` in `packages/quran_sessions` for join/booking paths if needed; widget suite may be flaky combined — use targeted runs per preflight script.
