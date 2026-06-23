# PSP Selection Gate — Tap vs Stripe Egypt

**Blueprint:** `036` Phase 2-1  
**Status:** Decision gate — **no production integration until sign-off**  
**Market:** Egypt (EGP) Paid v1

---

## Context

Paid v1 needs one primary PSP for pay-per-session card capture. Wallet checkout and subscriptions are out of scope for this gate. Phase 2 ships **sandbox only** (`SandboxPaymentProvider`); this document selects the production PSP for Phase 3+.

---

## Candidates

| Criterion | Tap Payments | Stripe (Egypt) |
|-----------|--------------|----------------|
| Egypt market presence | Strong MENA focus, local methods | Available; Egypt entity requirements |
| EGP settlement | Native | Supported with local entity |
| Marketplace / split | Connect-style payouts (manual Phase 5) | Connect (manual Phase 5) |
| Mobile SDK (Flutter) | Official SDK | `flutter_stripe` mature |
| Webhook reliability | Good; retry documented | Excellent; idempotent events |
| PCI scope | SDK tokenization — SAQ A | SDK — SAQ A |
| Onboarding timeline | Often faster for EG startups | KYC can be longer |
| Refund API | Card refund available (we use wallet policy) | Card refund available |
| Play Store / data safety | Standard disclosure | Well-understood patterns |
| Tilawa team familiarity | — | — |

---

## Recommendation

**Primary: Tap Payments** for Egypt Paid v1.

**Rationale:**
1. Regional product fit for Quran-session marketplace in EG.
2. Aligns with 031/032 docs referencing Tap as primary candidate.
3. Stripe remains valid **fallback** if Tap onboarding blocks launch.

**Not chosen yet for code:** Phase 2 uses `SandboxPaymentProvider` only. Real Tap/Stripe adapter is Phase 3+ after this gate passes.

---

## Sign-off checklist

| # | Item | Owner | Status |
|---|------|-------|--------|
| 1 | Legal review of marketplace + wallet refund policy | Legal | ⬜ |
| 2 | Finance: fee structure + reconciliation with PSP reports | Finance | ⬜ |
| 3 | Engineering: webhook endpoint + secret management design | Eng | ⬜ |
| 4 | Security: PCI scope confirmation (SDK-only) | Security | ⬜ |
| 5 | Ops: sandbox merchant account provisioned | Ops | ⬜ |
| 6 | Product: checkout copy + refund-to-wallet disclosure | Product | ⬜ |
| 7 | Executive GO on PSP vendor | Executive | ⬜ |

**Blockers for real PSP wiring:**
- Any ⬜ above remains open → stay on sandbox / Free Beta.

---

## Rollback

If selected PSP fails staging E2E: keep `QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED=false`, evaluate alternate vendor, do not enable prod.

---

## References

- [payment-flow.md](./payment-flow.md)
- [security-compliance-checklist.md](./security-compliance-checklist.md) S-01
- [implementation-roadmap.md](./implementation-roadmap.md) Phase 2–3
