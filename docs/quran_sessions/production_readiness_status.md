# Quran Sessions — Production Readiness Gate Status

**Last updated:** 2026-06-25 (engineering gates)  
**Milestone:** `038-quran-session-stable-production-release`  
**Overall verdict:** **Conditional Go** — engineering gates closed; manual + ops gates remain.

---

## Automated gates

| Gate | Status | Evidence |
|------|--------|----------|
| `scripts/quran_sessions_preflight.sh` | ✅ Wired | CI job `quran-sessions-preflight` in `.github/workflows/pr-checks.yml` (hard gate, JDK 21) |
| `functions-emulator-tests` | ✅ Wired | Unit + integration + rules (JDK 21) |
| Provider scope default `external,mock` | ✅ | `AppLaunchConfig.enabledCallProvidersCsv`; test in `quran_sessions_launch_policy_test.dart` |
| Paid/group CF rejection | ✅ | Existing integration tests (`createSessionBooking.integration.test.ts`) |
| Wallet UI hidden (production scope) | ✅ | `QuranSessionsFeatureConfig.walletEnabled` ← `quranSessionsPaidBookingSandboxEnabled` (default false) |
| Kill switches (`quranSessionsEnabled`, booking) | ✅ | Router guards + tests in `quran_sessions_session_guard_test.dart` |
| Admin wallet nav hidden (prod) | ✅ | `environment.quranSessionsWalletEnabled: false` |

---

## CI note (P0 investigation)

PR Checks jobs failing in ~3s with **empty steps** are caused by **GitHub account billing / spending limit**, not workflow YAML:

> *The job was not started because recent account payments have failed or your spending limit needs to be increased.*

**Action (repo owner):** GitHub → Settings → Billing & plans → resolve payment or raise spending limit.  
Workflow improvements still landed: dedicated preflight job, JDK 21 for emulator paths, checkout/setup-java pinned to stable v4.

---

## Documentation gates

| Gate | Status | Doc |
|------|--------|-----|
| Manual QA checklist (10 sections) | ✅ | [docs/qa/quran_sessions_production_manual_qa.md](../qa/quran_sessions_production_manual_qa.md) |
| Sign-off table link | ✅ | [docs/qa/quran_sessions_free_beta_signoff.md](../qa/quran_sessions_free_beta_signoff.md) |
| App Check staging runbook | ✅ | [app_check_staging_verification.md](./app_check_staging_verification.md) |
| Kill switch / rollback reference | ✅ | [MORNING-HANDOFF.md](../../specs/038-quran-session-stable-production-release/MORNING-HANDOFF.md) § Feature flags |

---

## Manual-only gates (user / ops)

| Gate | Owner | Status |
|------|-------|--------|
| B1–B5 student booking sign-off | QA | ⬜ |
| T2/T5/T6/T7/T8 two-device sign-off | QA | ⬜ |
| App Check flip on staging Firebase | Ops | ⬜ |
| Deploy remaining CF batch (`deploy_quran_session_callables.sh`) | Ops | ⬜ |
| Privacy policy — external meeting links | Legal | ⬜ |
| Play production wide rollout | Release | ⬜ **No-Go** until above pass |

---

## Kill switch quick reference

| Flag | Layer | Effect |
|------|-------|--------|
| `TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED=false` | App | Router redirect from `/sessions/*`; home entry hidden |
| `TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=false` | App | Booking route redirect; CTAs off |
| `TILAWA_LAUNCH_QURAN_SESSIONS_PAID_BOOKING_SANDBOX_ENABLED` | App | Wallet nav + paid sandbox (default **false**) |
| `TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS` | App + Firestore | Client registration; prod default `external,mock` |
| `QURAN_SESSIONS_ENFORCE_APP_CHECK` | CF env | Callable App Check enforcement (default **off**) |

---

## Go / No-Go matrix

| Automated preflight | Manual B+T | App Check staging | Verdict |
|--------------------|------------|-------------------|---------|
| ✅ | ✅ | ✅ | **Stable Production Go** |
| ✅ | ❌ | — | **Conditional Go** (internal/closed only) |
| ❌ | — | — | **No-Go** |

**Current:** Conditional Go for internal/closed track engineering upload; manual + ops gates open.
