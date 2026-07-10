# Quran Sessions — Production Readiness Gate Status

**Last updated:** 2026-07-09 (manual off-app payment / Egypt-only)  
**Milestone:** Paid manual payment (Egypt) — no wallet/PSP  
**Overall verdict:** **Conditional Go** — engineering for manual payment landed; manual QA + ops + legal remain.

---

## Product scope (locked)

| Item | Status |
|------|--------|
| Egypt-only (`countryCode === EG`) | ✅ CF `assertBookingEligible` |
| Paid only when `manualPaymentEnabled` | ✅ free blocked when manual on |
| No wallet / PSP / checkout | ✅ keep `QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED` unset/false |
| `paymentProvider: manual_off_app` | ✅ create booking path |
| `pending_payment` until admin confirms | ✅ confirm/reject callables + admin UI |
| Unique `paymentReference` (`QS-…`) | ✅ student + admin |
| WhatsApp `+201060099009` + prefill | ✅ mobile pilot config + booking/pending UI |
| Admin market pricing SoT | ✅ save payload fixed + `manualPaymentEnabled` |

---

## Automated gates

| Gate | Status | Evidence |
|------|--------|----------|
| CF unit tests | ✅ | `functions` `npm test` — 408/408 |
| Mobile booking/status/list tests | ✅ | focused `packages/quran_sessions` flutter tests |
| Admin build + unit tests | ✅ | `tilawa_admin` build + 164 tests (confirm/reject path) |
| Wallet/PSP sandbox default off | ✅ | env gate + admin wallet flag false |
| Kill switches | ✅ | router + booking flags |

---

## Manual-only gates (still open)

| Gate | Owner | Status |
|------|-------|--------|
| Manual payment E2E (price → WhatsApp → admin confirm) | QA | ⬜ |
| Non-Egypt student blocked on booking | QA | ⬜ |
| B1–B5 / T2–T8 (adapt for paid pending) | QA | ⬜ |
| App Check flip on staging | Ops | ⬜ |
| Deploy CFs (`deploy_quran_session_callables.sh`) | Ops | ⬜ — includes confirm/reject + pricing callables |
| Legal/privacy — off-app payment + WhatsApp handoff | Legal | ⬜ |
| Privacy — external meeting links | Legal | ⬜ |
| Play flags: booking on only when ops ready; PSP/wallet stay off | Release | ⬜ |

---

## Ops checklist (Egypt paid launch)

1. Admin → Market Pricing **EG**: enable market, set EGP price `> 0`, enable **manual payment**, set WhatsApp/InstaPay fields, keep PSP toggle **off**.
2. Teacher pricing override (optional) via teacher panel.
3. Deploy: `./scripts/deploy_quran_session_callables.sh <project>`
4. Staging smoke: student books → `pending_payment` + `QS-` ref → WhatsApp → admin confirm → `scheduled`.
5. Reject + TTL expire (24h manual hold) release slot.

---

## Kill switch quick reference

| Flag | Layer | Effect |
|------|-------|--------|
| `TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED=false` | App | Router redirect; home entry hidden |
| `TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=false` | App | Booking route redirect; CTAs off |
| Market `isEnabled` / `manualPaymentEnabled` | Firestore | Server blocks booking/quote |
| `TILAWA_LAUNCH_QURAN_SESSIONS_PAID_BOOKING_SANDBOX_ENABLED` | App | Wallet/PSP sandbox (keep **false**) |
| `QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED` | CF env | Keep **unset/false** for this release |
| `QURAN_SESSIONS_ENFORCE_APP_CHECK` | CF env | Callable App Check (ops flip) |

---

## Go / No-Go matrix

| Eng (manual payment) | Manual QA | App Check + deploy | Legal | Verdict |
|----------------------|-----------|--------------------|-------|---------|
| ✅ | ✅ | ✅ | ✅ | **Production Go (Egypt paid)** |
| ✅ | ❌ | — | — | **Conditional Go** (internal only) |
| ❌ | — | — | — | **No-Go** |

**Current:** Conditional Go — ship staging/closed after ops deploy + QA sign-off; **No-Go** for unrestricted Play until gates above pass.
