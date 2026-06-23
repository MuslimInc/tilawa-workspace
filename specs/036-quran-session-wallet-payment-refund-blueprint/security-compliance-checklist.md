# Security & Compliance Checklist

**Blueprint:** `036`  
**Status:** Design checklist — **does not claim compliance**  
Items marked **⚠️ LEGAL/OWNER** require explicit review before Paid launch.

---

## Payment service provider (PSP)

| # | Item | Status | Notes |
|---|------|--------|-------|
| S-01 | Select PSP (Tap vs Stripe EG) | ⚠️ OWNER | Phase 2 gate |
| S-02 | PSP contract + MSA | ⚠️ LEGAL | |
| S-03 | Sandbox + prod keys in Secret Manager | Required | Never in repo |
| S-04 | Webhook signature verification | Required | Reject unsigned |
| S-05 | Idempotent webhook handling | Required | [booking-payment-state-machine.md](./booking-payment-state-machine.md) |
| S-06 | PCI SAQ scope minimization | Required | Card fields only in PSP SDK |
| S-07 | **No card PAN/CVV in Firestore** | Required | Opaque refs only |
| S-08 | 3DS / SCA per PSP market rules | ⚠️ LEGAL | EG requirements |
| S-09 | PSP outage runbook | Required | [032 rollback](../032-quran-session-delivery-plan/rollback-plan.md) |

---

## Google Play policy

| # | Item | Status | Notes |
|---|------|--------|-------|
| P-01 | Digital goods / services classification | ⚠️ LEGAL | External PSP may be required vs Play Billing |
| P-02 | Data safety form: financial info | Required if paid | Update before paid rollout |
| P-03 | Privacy policy mentions payment + wallet | ⚠️ LEGAL | |
| P-04 | No misleading pricing in screenshots | Required | Free Beta today |
| P-05 | Target audience / children | ⚠️ LEGAL | Quran sessions + minors |
| P-06 | Permissions justification | Required | No unnecessary financial permissions |

---

## Legal & terms

| # | Item | Status | Notes |
|---|------|--------|-------|
| L-01 | Terms of Service: wallet credit nature | ⚠️ LEGAL | Not cash unless licensed |
| L-02 | Refund policy disclosure (wallet default) | ⚠️ LEGAL | [refund-to-wallet-policy.md](./refund-to-wallet-policy.md) |
| L-03 | Consumer protection (EG) | ⚠️ LEGAL | Cooling-off, dispute rights |
| L-04 | Teacher independent contractor / marketplace | ⚠️ LEGAL | Payout off-platform Paid v1 |
| L-05 | Age of consent for paid booking | ⚠️ LEGAL | Guardian flow deferred 031 |
| L-06 | Data retention period for payment records | ⚠️ LEGAL | Finance + privacy |

---

## Refund transparency

| # | Item | Status |
|---|------|--------|
| T-01 | Checkout shows wallet refund policy | Required |
| T-02 | Cancel flow shows credit amount | Required |
| T-03 | Push/email on refund executed | Required |
| T-04 | Wallet history human-readable | Required |
| T-05 | Support contact for refund disputes | Required |

---

## Wallet terms

| # | Item | Status | Notes |
|---|------|--------|-------|
| W-01 | Wallet credit non-withdrawable (unless licensed) | ⚠️ LEGAL | |
| W-02 | Expiry policy for promo credits | Future | Document if added |
| W-03 | Wallet freeze appeals process | Required | Admin SOP |
| W-04 | Cross-service eligibility list | Product | Quran + eligible MeMuslim |
| W-05 | Insolvency / platform shutdown user funds | ⚠️ LEGAL | |

---

## Tax

| # | Item | Status | Notes |
|---|------|--------|-------|
| X-01 | VAT applicability on session fees | ⚠️ LEGAL/FINANCE | `tax` field snapshot |
| X-02 | Tax invoice to student | Postponed Paid v1 | |
| X-03 | Teacher tax reporting | Postponed | Manual payout |
| X-04 | Platform fee accounting | ⚠️ FINANCE | |

---

## Fraud & abuse

| # | Item | Status |
|---|------|--------|
| F-01 | Rate limit booking + payment attempts | Required |
| F-02 | Velocity checks on wallet credits | Required |
| F-03 | Admin credit requires reason + audit | Required |
| F-04 | Duplicate idempotency enforcement | Required |
| F-05 | Account freeze linked to wallet freeze | Required |
| F-06 | Suspicious dispute pattern review | Ops |

---

## Chargeback

| # | Item | Status | Notes |
|---|------|--------|-------|
| C-01 | Chargeback webhook from PSP | Required | Alert finance |
| C-02 | Policy when refund was wallet-only | ⚠️ LEGAL | User spent credit? |
| C-03 | Evidence pack (booking, join logs, policy) | Required | |
| C-04 | Lifecycle flag on chargeback received | Required | |

---

## Child / guardian

| # | Item | Status | Notes |
|---|------|--------|-------|
| G-01 | Guardian approval for child booking | 031 deferred | Block paid until resolved? ⚠️ OWNER |
| G-02 | Who owns wallet for minor | ⚠️ LEGAL | Guardian account? |
| G-03 | `videoCallAllowedForChildren` policy | 031 | |

---

## Privacy

| # | Item | Status |
|---|------|--------|
| PR-01 | Minimize payment PII in logs | Required |
| PR-02 | GDPR/PDPL retention | ⚠️ LEGAL |
| PR-03 | User export includes wallet history | Required |
| PR-04 | User deletion: wallet balance handling | ⚠️ LEGAL |

---

## Technical security

| # | Item | Status | Notes |
|---|------|--------|-------|
| TS-01 | Firebase App Check on payment callables | Required | |
| TS-02 | Webhook signature verification | Required | |
| TS-03 | Idempotency on all financial callables | Required | |
| TS-04 | Audit log append-only | Required | `quran_session_audit_events` |
| TS-05 | Admin custom claims / RBAC | Required | [admin-operations.md](./admin-operations.md) |
| TS-06 | Firestore rules: deny client financial writes | Required | |
| TS-07 | Secrets rotation procedure | Required | |
| TS-08 | No payment secrets in mobile binary | Required | |
| TS-09 | `QURAN_SESSIONS_PAYMENT_PROVIDER_ENABLED` prod default false | Required | Until Go/No-Go |

---

## Pre-launch review meeting

| Attendee | Sign-off |
|----------|----------|
| Product | Scope Paid v1 |
| Engineering | Technical checklist TS-* |
| Finance | Tax, chargeback, reconciliation |
| Legal | L-*, W-*, wallet classification |
| Ops | Admin SOP, manual_pending |
| Release | Play P-*, rollback |

**Outcome:** Documented Go/No-Go — not compliance certification.

---

## Free Beta specific

| Item | Status |
|------|--------|
| Paid path blocked at CF + `DisabledPaymentProvider` | ✅ Verified smoke #10 |
| No wallet collection in prod | ✅ |
| Admin financial resolve disabled | ✅ 035 |
| Privacy: no payment data collected | ✅ |
