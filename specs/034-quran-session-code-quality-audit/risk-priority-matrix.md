# Risk Priority Matrix — Quran Sessions Code Quality

**Audit date:** 2026-06-23

**Classification:** Must fix · Should fix · After Beta · Postpone Production · Postpone Paid · Ignore

| ID | Issue | Category | Severity | Probability | User impact | Dev impact | Free Beta blocker | Sprint | Classification |
|----|-------|----------|----------|-------------|-------------|------------|-------------------|--------|----------------|
| R-01 | Join handler empty | Clean code / Arch | P0 | Certain | Cannot join session | Dead code path | **Y** | 5 | **Must fix** |
| R-02 | No `meeting_link` in CF create | Backend / LSP | P0 | Certain | Join URL missing | Fake/prod divergence | **Y** | 5 | **Must fix** |
| R-03 | `CallProvider` not in DI | DIP / YAGNI | P0 | Certain | Join unwired | Provider exists unused | **Y** | 5 | **Must fix** |
| R-04 | Session detail no join UI | UI Kit / Atomic | P0 | Certain | No join from detail | Incomplete screen | **Y** | 5 | **Must fix** |
| R-05 | Fake repo sets link; CF does not | Testability | P0 | High | False test confidence | Prod surprise | **Y** | 5 | **Must fix** |
| R-06 | Eligibility use case 0 unit tests | Testability | P1 | Medium | Wrong gate ships | Regression risk | **Y** | 5 | **Must fix** |
| R-07 | No join bloc/widget test | Testability | P1 | High | Join regressions | No safety net | **Y** | 5 | **Should fix** |
| R-08 | Review failure swallowed | Clean code | P1 | Medium | Silent data loss UX | Hard to debug | N | 6 | **Should fix** |
| R-09 | `TeacherDashboardBloc` 822 LOC | SRP / KISS | P1 | Medium | Slot delete bugs | Slow changes | N | 6 | **Should fix** |
| R-10 | Teacher dashboard screen 1011 LOC | Atomic | P1 | Low | UI bugs | Review cost | N | 6 | **After Beta** |
| R-11 | Timeline raw enum names | UI Kit / l10n | P1 | Certain | Poor AR UX | Easy fix | N | 6 | **Should fix** |
| R-12 | Hardcoded `SessionPricingType.free` cancel | Clean code | P1 | Low (Beta) | Wrong policy later | Paid prep debt | N | Paid | **Postpone Paid** |
| R-13 | Debug amber panel in status screen | UI Kit | P1 | Low | Confusing prod UI | Unprofessional | N | 6 | **Should fix** |
| R-14 | `parseLifecycleStatus` → scheduled fallback | OCP / Arch | P1 | Low | Wrong status display | Data corruption hide | N | 6 | **Should fix** |
| R-15 | Agora/WebRTC throw on use | LSP | P1 | Low if gated | Crash if miswired | DI mistake fatal | N | — | **Ignore** (not registered) |
| R-16 | Dual fake + firebase backends | KISS / DRY | P1 | Medium | Parity bugs | 2x maintenance | N | 7 | **After Beta** |
| R-17 | Specialization list duplicated | DRY | P1 | Low | Drift in forms | Copy-paste | N | 6 | **After Beta** |
| R-18 | Admin filter UI duplicated | DRY / Atomic | P2 | Medium | Admin inconsistency | 2x HTML | N | 7 | **After Beta** |
| R-19 | Raw Material buttons in sessions UI | UI Kit | P2 | Certain | Visual inconsistency | Style drift | N | 7 | **After Beta** |
| R-20 | Hardcoded EdgeInsets in sessions | UI Kit | P2 | Certain | Spacing drift | Token migration | N | 7 | **After Beta** |
| R-21 | `session_card` uses `Card` not TilawaCard | UI Kit | P2 | Low | Minor visual | — | N | 7 | **After Beta** |
| R-22 | Financial ledger CF (no UI) | YAGNI | P2 | Low | None in Beta | Dead code surface | N | Paid | **Postpone Paid** |
| R-23 | Report/dispute CF no mobile UI | YAGNI / Product | P1 | Medium | Safety gap | CF unused | N* | 6 | **Should fix** (*product) |
| R-24 | `enforceAppCheck: false` on CF | Security | P2 | Low Beta | Abuse on staging | — | N | Prod | **Postpone Production** |
| R-25 | Legacy + lifecycle dual-write | KISS | P2 | Low | None if mappers OK | Field sprawl | N | 8 | **Postpone Production** |
| R-26 | Dart/TS lifecycle matrix duplicate | DRY | P2 | Medium | Illegal transition if drift | 2x updates | N | 8 | **Postpone Production** |
| R-27 | `MySessionsBloc` no injectable `now` | Testability | P2 | Low | Flaky midnight tests | Annoyance | N | 7 | **After Beta** |
| R-28 | Router `getIt` coupling | Arch | P2 | Low | — | Heavy route tests | N | 7 | **After Beta** |
| R-29 | `quran_sessions_failure` monolith | KISS | P2 | Low | — | Nav noise | N | 8 | **After Beta** |
| R-30 | Metrics aggregation unused | YAGNI | P2 | Low | None | — | N | — | **Ignore** |

---

## Matrix summary

| Classification | Count |
|----------------|-------|
| **Must fix** | 6 |
| **Should fix** | 8 |
| **After Beta** | 11 |
| **Postpone Production** | 3 |
| **Postpone Paid** | 2 |
| **Ignore** | 2 |

| Severity | Count |
|----------|-------|
| P0 | 5 |
| P1 | 12 |
| P2 | 13 |

| Free Beta blocker (code quality lens) | **6** (R-01–R-07) |

---

## Risk heat map (Severity × Probability)

```
          Low prob    Med prob    High/Certain
P0        —           R-05        R-01,R-02,R-03,R-04
P1        R-15        R-06,R-09   R-11,R-23
P2        R-30        R-16,R-26   R-19,R-20
```
