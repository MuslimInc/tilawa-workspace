# Feature Specification: Support Tilawa (Voluntary Contribution)

**Status**: Approved direction — documented before broad rollout  
**Created**: 2026-05-22  
**Feature branch**: `016-support-tilawa` (when used)  
**Related**: [`DESIGN.md`](../../DESIGN.md) §15 · [`docs/tilawa_brand.md`](../../docs/tilawa_brand.md) §12 · [`packages/ui_kit/docs/support_visual_system.md`](../../packages/ui_kit/docs/support_visual_system.md) · [`docs/support_play_products.md`](../../docs/support_play_products.md)

---

## 1. Product philosophy

Tilawa is **not** a premium subscription app. It is a calm Quran and worship
companion sustained by people who choose to support it.

**Positioning (canonical):**

> A respectful Quran and worship app that stays calm, beautiful, and ad-free
> because users voluntarily support it.

### 1.1 Why “Support” instead of “Premium”

| “Premium / Pro / VIP” implies | “Support Tilawa / Supporter” implies |
|------------------------------|-------------------------------------|
| Feature gating, paywalls | Optional contribution |
| Commercial upgrade funnel | Shared ownership of the mission |
| Urgency and exclusivity | Gratitude and transparency |

**Banned user-facing terms:** Premium, Pro, Unlock, Upgrade, VIP, subscription
tier marketing on worship surfaces.

**Preferred terms:** Support Tilawa, Support the mission, Help keep Tilawa free,
Become a supporter, Thank you (post-contribution).

The legacy `features/premium` module name may remain in code during migration;
**new** UI, routes, analytics, and specs MUST use **support** vocabulary.

---

## 2. Monetization ethics (product rules)

These rules are **non-negotiable** for Tilawa. They apply to all current and
future monetization work unless explicitly revised in a new spec.

### 2.1 Always free (no gates)

- Quran reading (all mushafs / render modes in scope)
- Quran listening (core reciters reasonably available without payment)
- Prayer times, qibla, and athkar flows
- Reasonable offline download access (no artificial “premium-only” download wall)

### 2.2 Never do

- Intrusive monetization (launch popups, forced sheets, onboarding paywalls)
- Worship interruption (banners/dialogs in Quran reader, prayer countdown,
  athkar sessions, first launch)
- Dark patterns: guilt copy, fake scarcity, countdown timers, streaks tied to
  spending, public spend leaderboards
- Gold “VIP” chrome, confetti, casino/reward aesthetics on purchase success
- Client-only purchase completion (e.g. writing `status: 'completed'` to
  Firestore without Google Play verification)
- Framing support as unlocking worship or religious reward

### 2.3 Always do

- Make support **optional** and easy to dismiss
- Explain **what support helps with** (hosting, audio, prayer tools, development,
  staying ad-free)
- Process payments via **Google Play**; state that Tilawa does not store card data
- Verify purchases server-side before thanking the user
- Use calm, grateful copy after success — not “Unlock benefits”

### 2.4 Legal / trust copy

- Support funds the **Tilawa app**, not a registered charity, unless a formal
  charity partnership exists (then update copy with legal review).
- Payments are **managed by Google Play**.

---

## 3. UX rules

### 3.1 Allowed entry points (MVP and default policy)

| Location | Allowed | Notes |
|----------|---------|-------|
| Settings → Support group | Yes | Primary discovery |
| About / app info (version footer area) | Yes | Trust + transparency |
| Profile card (Settings header) | Yes | Secondary, non-pushy link |
| Deep link `/support` | Yes | Feature-flagged in rollout |
| Quran reader | **No** | Mushaf-first; no banners |
| Prayer times / notifications | **No** | Worship context |
| Athkar flows | **No** | Worship context |
| Cold start / onboarding | **No** | No monetization in first-run |
| Occasional interstitial | **No** in MVP | Defer any “gratitude moment” to post-MVP spec |

Legacy `/premium` route MAY redirect or render the same Support screen during
migration; do not advertise “Premium” in UI.

### 3.2 Support Tilawa screen (MVP)

**Flow:** mission copy → impact transparency → tier selection → confirmation
sheet → Google Play → thank-you → Done.

**Tone:** grateful, factual, low pressure.

**Restore purchases:** present with honest copy (consumables are not “restored”
like subscriptions; copy explains pending/incomplete purchases).

### 3.3 Feature flag

`TILAWA_LAUNCH_SUPPORT_TILAWA_ENABLED` (default **`true`**; set `false` to hide
Support entry points before Play products and Cloud Function are ready).

---

## 4. MVP scope

### 4.1 In scope (MVP)

| Area | Detail |
|------|--------|
| Platform | **Android only** (Google Play) |
| Billing | **Google Play Billing** via `in_app_purchase` |
| Products | **Three consumable** one-time support tiers |
| Play IDs | `support_once_small`, `support_once_kind`, `support_once_generous` |
| Verification | Lightweight **`verifySupportPurchase`** Cloud Function |
| Ledger | Token-hash replay protection in `support_purchases` (no user entitlement doc) |
| UI | Support screen, Settings/Profile entry, AR/EN l10n |
| Analytics | Funnel events (`support_screen_viewed`, tier selected, verified, failed) |

### 4.2 Out of scope (MVP — document for roadmap only)

- iOS / StoreKit / cross-platform billing abstractions (e.g. RevenueCat)
- Subscriptions (monthly/yearly sustain)
- Supporter badges, themes, perks, cloud-sync gates
- Firestore entitlement mirror / RTDN subscription webhooks
- Custom donation amounts
- Public supporter recognition
- Ads (Tilawa default policy: **no ads** on worship surfaces; support replaces ad monetization)

### 4.3 Post-MVP (requires new or amended spec)

- Optional monthly “sustain Tilawa” subscription
- Private Settings-only supporter label
- Cosmetic perks (themes) — must not gate worship utilities
- Account-linked cross-device supporter state

---

## 5. Architecture notes (MVP)

```text
SupportBloc → UseCases → SupportRepository
                              ├── PlayBillingDataSource (in_app_purchase)
                              ├── SupportLocalDataSource (last thank-you only)
                              └── PurchaseVerificationClient → Cloud Function
```

### 5.1 Required patterns

- **Server verification** before `completePurchase` / consume on device
- **No fake Firestore purchase flow** as source of truth
- **No entitlement sync** in MVP (local thank-you timestamp optional)
- **Either&lt;Failure, T&gt;** use cases; `PurchaseFailure` for billing errors
- Purchase stream handled in data layer; bloc stays testable

### 5.2 Explicit anti-patterns (do not reintroduce)

- `purchaseSubscription()` writing completed status to Firestore without Play token verification
- Global `PremiumBloc` driving worship CTAs
- Download bloc emitting `premiumRequired` for normal users

See implementation map: `apps/tilawa/lib/features/support/`.

---

## 6. Visual & UI Kit

Follow [`packages/ui_kit/docs/support_visual_system.md`](../../packages/ui_kit/docs/support_visual_system.md):

- Calm surfaces (`surfaceContainerLow`, hairline, one Ink CTA)
- No gold gradients on CTAs; Gilding (`tertiary`) not for pay buttons
- Thank-you via `TilawaEmptyState` — no confetti
- Optional ambient geometry only at low opacity (brand §7)
- `TilawaContentBounds.form` for screen width

---

## 7. Success criteria (MVP)

1. With flag on, user can open Support from Settings without seeing “Premium” copy.
2. User can complete a consumable purchase in Play sandbox; server verifies token.
3. Quran reader and prayer screens show **no** support prompts in MVP build.
4. Downloads proceed without premium gate for anonymous and signed-in users.
5. Duplicate `purchaseToken` rejected server-side.
6. AR and EN strings use support vocabulary throughout the flow.

---

## 8. Roadmap cross-reference

| Document | Update |
|----------|--------|
| [`specs/002-product-growth-roadmap/spec.md`](../002-product-growth-roadmap/spec.md) §4.11 | Ethical monetization → Support Tilawa MVP |
| [`specs/002-product-growth-roadmap/checklists/requirements.md`](../002-product-growth-roadmap/checklists/requirements.md) | DECISION-002 superseded by this spec |
| [`docs/missing_features.md`](../../docs/missing_features.md) | Link voluntary support when audited |

**For contributors:** When proposing monetization, start from this spec. If the
proposal uses “premium”, “unlock”, or worship gating, it is out of policy unless
this document is explicitly amended.

---

## 9. Open decisions (post-MVP)

- [ ] **DECISION-S01**: Introduce optional monthly subscription — needs legal/copy review
- [ ] **DECISION-S02**: Private supporter badge in Settings — cosmetic only
- [ ] **DECISION-S03**: Guest purchase vs require sign-in for ledger attribution
