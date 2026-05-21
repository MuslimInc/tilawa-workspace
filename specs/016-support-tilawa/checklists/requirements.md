# Checklist: Support Tilawa — Product & Documentation

**Feature**: [spec.md](../spec.md)  
**Created**: 2026-05-22

## Philosophy & terminology

- [x] Canonical positioning documented (“voluntary support”, not subscription app)
- [x] Banned terms listed (Premium, Pro, VIP, Unlock, Upgrade)
- [x] Preferred terms listed (Support Tilawa, Supporter, etc.)
- [x] Rationale for “support” vs “premium” explained for future contributors

## Monetization ethics

- [x] No intrusive monetization rule
- [x] No worship interruption rule
- [x] No Quran/prayer/athkar feature gating
- [x] No dark patterns / urgency tactics
- [x] No fake Firestore completion / client-only verification
- [x] Ad-free + transparency copy guidance

## UX constraints

- [x] Allowed entry points: Settings, About, Profile
- [x] Disallowed entry points: Quran reader, prayer, athkar, onboarding
- [x] MVP screen flow described
- [x] Feature flag documented

## MVP scope

- [x] Android + Google Play Billing only
- [x] Consumable one-time tiers only (3 SKUs)
- [x] No subscriptions/perks/entitlement sync in MVP
- [x] Cloud Function verification noted
- [x] Post-MVP items explicitly deferred

## Design system linkage

- [x] `DESIGN.md` updated (§15)
- [x] `docs/tilawa_brand.md` updated (§12)
- [x] `packages/ui_kit/docs/support_visual_system.md` created
- [x] Play product IDs documented in `docs/support_play_products.md`

## Roadmap alignment

- [x] `specs/002-product-growth-roadmap` §4.11 cross-referenced
- [x] Growth checklist DECISION-002 updated

## Implementation readiness (engineering — separate track)

- [ ] Play Console products created for three SKUs
- [ ] `verifySupportPurchase` deployed with Play API access
- [ ] Internal testing with license testers
- [ ] Feature flag enabled in internal/closed track only
