# Refund-to-Wallet Policy

**Blueprint:** `036`  
**Default:** Refunds and marketplace compensations credit the **in-app wallet**  
**Card reversal:** Exceptional, manual, finance-approved — **postponed for automation**

---

## Policy statement (user-facing draft — legal review required)

> When you cancel or when we approve a refund for your Quran session, the refund amount is added to your Tilawa wallet as credit. You can use this credit toward future Quran sessions and eligible MeMuslim services. Wallet credit is not automatically returned to your card or bank account.

This copy must appear:

- At paid checkout (checkbox acknowledgment or linked terms)
- In cancellation confirmation when refund > 0
- In refund/dispute resolution notification
- In wallet screen footer + Terms of Service section

**Status:** Draft for legal/owner review — do not ship without sign-off.

---

## When wallet credit applies (default)

| Scenario | Refund destination | Policy rule IDs (031) |
|----------|---------------------|------------------------|
| Student early cancel (full refund fraction) | Wallet | CN-02, RF-01 |
| Student late cancel (partial) | Wallet (partial amount) | CN-03 |
| Teacher cancel | Wallet (full session price) | CN-06, CP-teacherCancel |
| Teacher no-show | Wallet per compensation policy | NS-*, CP-noShow |
| Admin cancel with refund choice | Wallet | CN-09 |
| Dispute resolved with refund | Wallet | Dispute resolution |
| Dispute resolved with compensation (`wallet_credit`) | Wallet | `with_compensation` path |
| Session `pricingType: free` | No money; optional session credit only | Beta path |

**Execution:** Server creates `quran_session_refunds` or uses compensation record → posts `WalletTransaction` → sets `refundExecutionStatus` / `compensationExecutionStatus` to `executed` when wallet post succeeds.

---

## When original payment method applies (exception)

| Trigger | Actor | Notes |
|---------|-------|-------|
| Regulatory requirement | Legal + finance | Document case-by-case |
| PSP chargeback won in customer favor | Finance | May require card refund outside wallet |
| Duplicate charge / billing error | Admin + finance | Prefer wallet first; card if wallet empty and legal requires |
| User explicit request for card refund | Admin | **Manual** in Paid v1; not self-serve |
| Wallet frozen / account closed | Admin | Off-platform settlement process |

**Postponed:** Automated PSP `refund()` on `paymentReference` — `DisabledPaymentProvider.refund` returns failure today; `PaymentProvider.refund` exists in domain but not wired.

---

## Transparency requirements

| Moment | Required disclosure |
|--------|---------------------|
| First paid booking | Wallet refund policy summary + link to full terms |
| Cancel sheet | "X EGP will be added to your wallet" (not "refunded to card") |
| Refund approved push | Amount, currency, new wallet balance, expiry if any |
| Dispute resolution | Resolution type + financial outcome |
| Admin manual credit | Reason code visible to user in transaction history |
| Wallet screen | "Credits from refunds and compensation" section |

### Prohibited copy

- "Money will be returned to your card" (unless card exception approved)
- "Cash withdrawal" unless legally supported and implemented

---

## Free Beta behavior (unchanged)

| Aspect | Today |
|--------|-------|
| Sessions | Free — no payment capture |
| Refund/compensation CF | Writes `manual_pending` to `quran_session_refunds` / `compensations` |
| Wallet entity | **Does not exist** in production data |
| Admin disputes UI | Read-only (035) — no financial execution |
| User expectation | Set Beta copy: "No charges during beta; future refunds will be wallet credit" |

Manual records in Free Beta prepare ops for Paid v1 without moving money.

---

## Amount calculation

Use **booking payment snapshot** at time of refund:

```
refundAmount = floor(amount * refundFraction, currency)
```

- `refundFraction` from `ConfigurableCancellationPolicy` (031 CN-*)
- Do not refund `platformFee` separately — gross session price policy per product decision
- Partial refunds create single wallet credit transaction (not fee line items) in Paid v1

---

## Timing

| Stage | SLA (product target — ops to confirm) |
|-------|--------------------------------------|
| Auto cancel refund | Immediate on CF success (wallet post) |
| Dispute refund | After admin resolve action |
| `manual_pending` (transition) | Until wallet Phase 1 live; then backfill or execute |

Notification: `refundApproved` outbox kind exists in `notificationOutboxService.ts` — extend payload with `walletTransactionId` and balance.

---

## Reversal and clawback

| Case | Action |
|------|--------|
| Erroneous admin credit | `admin_reversal` debit if balance sufficient; else flag account |
| Fraudulent refund | Freeze wallet + admin reversal + account review |
| User spends credit then chargeback on original card | Finance playbook — **legal review** |

---

## Relation to compensation types (CF)

Existing `CompensationType`:

| Type | Paid v1 behavior |
|------|------------------|
| `wallet_credit` | Post to wallet |
| `restore_credit` | Free Beta session credit; Paid: wallet or free rebook token |
| `replacement_session` | No wallet; book replacement slot |
| `extend_subscription` | Postponed (no subscriptions) |
| `manual_review` | Admin chooses wallet or other |

---

## Postponed: automatic card refund

| Item | Rationale to postpone |
|------|----------------------|
| PSP refund API on student early cancel | Wallet-first simpler; fewer PSP fees |
| Partial card + partial wallet reversal | Reconciliation complexity |
| Refund to original payment method self-serve | Support load; legal |

**Future gate:** If legal requires card parity, implement `PaymentProvider.refund` with idempotency before enabling self-serve card choice.

---

## Compliance triggers (document, not resolve)

- [ ] Legal: wallet credit classification (stored value vs promotional)
- [ ] Legal: refund policy in Terms + checkout
- [ ] Finance: chargeback playbook when wallet-only refunds
- [ ] Product: minor/guardian wallet ownership
- [ ] Ops: manual_pending backlog SOP before Paid launch

See [security-compliance-checklist.md](./security-compliance-checklist.md).
