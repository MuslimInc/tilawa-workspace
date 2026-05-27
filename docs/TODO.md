# Tilawa backlog (living)

Personal **features** and **refactors** to pick up later. Add a line whenever
something comes to mind; check boxes when done.

**Related (longer specs / gap analysis):**

- [`missing_features.md`](missing_features.md) — competitor-style feature gaps
- [`specs/002-product-growth-roadmap/spec.md`](../specs/002-product-growth-roadmap/spec.md) — roadmap spec
- [`specs/016-support-tilawa/spec.md`](../specs/016-support-tilawa/spec.md) — Support Tilawa rules
- [`release_notes.md`](release_notes.md) — Play Console copy per release
- [`startup_splash_plan.md`](startup_splash_plan.md) — P0 splash-held startup (Noon/Amazon style)

**Conventions**

| Prefix | Meaning |
|--------|---------|
| `[ ]` | Not started |
| `[~]` | In progress (optional) |
| `[x]` | Done — move to **Done** with date |
| `P0` / `P1` / `P2` | Urgency (optional) |

---

## Features

_Add new product work here._

- [ ] **Support Tilawa — Shorebird patch** `P1`  
  Ship PR #56 fixes (billing dedupe, app-review sacred-flow ref-count) on
  `1.0.4+31` via `shorebird patch android --release-version 1.0.4+31`, then
  update [`release_notes.md`](release_notes.md) Unreleased → shipped.

- [ ] **Support — optional UI listen to verified stream** `P2`  
  Consider `watchVerifiedPurchases` in Support bloc so background-only success
  can show thank-you without relying only on `purchaseSupportProduct` return.

- [ ] **Premium → Support copy audit** `P1`  
  Purge remaining user-facing “Premium” strings; align with
  [`specs/016-support-tilawa/spec.md`](../specs/016-support-tilawa/spec.md).

- [ ] **Share — disable video reel; keep screenshot only** `P1`  
  Disable or comment out the generate-video-reel flow; keep only custom surah/
  ayah **screenshot** sharing. Goal: reduce app size (e.g. drop or slim heavy
  video/ffmpeg dependencies where possible).

- [ ] **Settings — Preferences screen** `P2`  
  Add `settings.preferences` (or equivalent route): user can show/hide
  **alphabet index on Reciters**; move selected items from main Settings into
  Preferences for a cleaner layout.

- [ ] **Prayer — change Adhan audio file** `P2`  
  Replace the default Adhan sound asset with the chosen production file; verify
  notification and foreground playback paths.

- [ ] _Your next feature idea_

---

## Refactors & tech debt

_Code health, architecture, tests — not user-visible features._

- [ ] **Theme token harmonization (T4)** `P2`  
  See backlog in [`missing_features.md`](missing_features.md#-post-release-maintainability-backlog).

- [ ] **Firestore client bootstrap** `P1`  
  Confirm production builds do not seed/write `subscription_plans` from the app
  (see [`google_play_pre_release_audit_2026-03-25.md`](../apps/tilawa/docs/reviews/25_mar_2026/google_play_pre_release_audit_2026-03-25.md)).

- [~] **Startup — splash-held readiness (Noon / Amazon style)** `P0` ← **current focus**  
  Full plan: [`startup_splash_plan.md`](startup_splash_plan.md).  
  **Done (Phase 1 MVP):** `AppStartupReadiness`, `SplashBloc` (migrated from cubit),
  shell prep on splash for home; `MainScreenCubit` skips prep when already done.  
  **Next:** Single splash surface (`_BootGate` + `/splash`); profile cold start;
  re-budget background init.

- [ ] _Your next refactor_

---

## Ops & release

- [ ] **Tag hygiene** `P2`  
  Decide whether `v1.0.4+31` should include docs-only commits after the tag, or
  tag again on the next Play upload (`1.0.4+32`).

- [ ] **Play Console**  
  Keep three consumables active; license testers on closed/production as needed
  ([`support_play_products.md`](support_play_products.md)).

- [ ] _Your next ops item_

---

## Ideas (unscoped)

_Quick captures — sort into sections above when ready._

- 

---

## Done

_Move completed items here with date._

- [x] **1.0.4+31 production** — 2026-05-23 — Play production, `CHANGELOG`, tag
  `v1.0.4+31`, [`release_notes.md`](release_notes.md)
- [x] **PR #56 review follow-ups** — merged to `master` (billing + app review)
- [x] **Deploy `verifySupportPurchase` + App Check** — Blaze + Play Integrity

---

*Last touched: 2026-05-23 (P0 startup splash plan)*


Some issues need to be solved:

1. Make the app route only portrait except Quran Image Screen (should be portrait up and oriantation).