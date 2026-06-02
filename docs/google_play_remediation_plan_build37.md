# Google Play remediation plan — Build 37 (1.0.5)

Phased, batched fix plan to get **build 37** approved on Google Play, plus a
deferred backlog for the next release. Derived from a two-pass repository audit
(May 2026): standard Play-policy review + a native/release-engineering second pass.

**Related docs:**

- [google_play_compliance_plan.md](google_play_compliance_plan.md) — full audit
  findings and baseline this plan executes against
- [google_play_release_checklist.md](google_play_release_checklist.md) — upload checklist
- [release_notes.md](release_notes.md) — Play "What's new" copy
- [support_play_products.md](support_play_products.md) — Support Tilawa IAP

---

## Strategy & locked decisions

| Decision | Value | Consequence |
|----------|-------|-------------|
| Release target | **Ship build 37 ASAP** | Phases 0–3 are the critical path to submit; Phase 4 is deferred to a follow-up release |
| Auth model | **Mandatory login** (Google Sign-In before app entry) | Account deletion + privacy policy + Data Safety are **non-negotiable Critical gates** for this release |
| Implementation scope | **Plan only** | No code changed yet; implement only on approval of specific phases/batches |

**Baseline:** documented production = `1.0.5+32`; pending in repo = `1.0.5+37`;
target/compile SDK = **36**; Billing Library **7.1.1**; AGP **8.11.1**; Flutter **3.44.0**;
ABI **arm64-v8a only**.

**Legend:** 🔴 Critical · 🟠 High · 🟡 Medium/cleanup ·
`[code]` repo change · `[console]` Play Console/external · `[verify]` build-time or device check

---

## Critical path

```
Phase 0 (discovery, parallel) ─┬─► Phase 1 (1A account-del ‖ 1B 16KB ‖ 1C privacy)
                               │        │
                               └────────┴─► Phase 2 (Console) ─► Phase 3 (build+submit)
                                                                        │
                                                          Phase 4 (next release)
```

- **Longest pole:** Batch **1A (account deletion)** — real code + tests + server-side cleanup. Start the moment Phase 0 confirms scope.
- **Highest uncertainty:** Batch **1B (16 KB)** — cannot estimate until 0A runs.
- **Parallelism:** 1A/1B/1C are independent; Phase 2 can begin once the deletion **web URL** exists.

---

## Phase 0 — Discovery & verification (do first, parallelizable)

Gathers facts; changes no shippable code. Drives the conditional batches downstream.

| Batch | Task | Finding | Type | Output |
|-------|------|---------|------|--------|
| 0A | Build release AAB; check 16 KB alignment on every `lib/arm64-v8a/*.so` (objdump `LOAD` align `2**14`, or Google's `check_elf_alignment.sh`) | N7 | `[verify]` | List of non-aligned libs |
| 0B | Confirm the **March-2026 Firestore-seeding Critical** is fixed (`app_startup.dart`, `firebase_initialization_service.dart`) | carry-over | `[verify]` | Fixed / still-present |
| 0C | Confirm `setCrashlyticsCollectionEnabled(true)` is called post-consent | N14 | `[verify]` | Yes / No |
| 0D | Device tests on **Android 15/16**: edge-to-edge insets + cutout, predictive back, **adhan FGS fires when backgrounded/killed** | N8, N9 | `[verify]` | Pass/fail list |
| 0E | Inventory Console state: published versionCode, Data Safety, privacy URL, App Signing enrollment, content rating | #3,#6,N10 | `[console]` | Gap list |

**✅ Checkpoint 0:** 16 KB-offending lib list known; March critical confirmed dead;
Android 15/16 device results in hand; Console gap list complete.

---

## Phase 1 — Hard submission blockers

Items that make Play reject the binary or listing outright.

### Batch 1A — Account deletion `[code]` 🔴 (audit #1)
- Add `Future<void> deleteAccount()` to `AuthRepository` + impl (Firebase `user.delete()` with **re-authentication** for `requires-recent-login`).
- Delete server-side user data (Firestore user doc, FCM token, support/purchase records as applicable).
- Add **"Delete account"** in Settings (reachable while signed in) with a confirmation dialog (ar + en strings).
- Provide the **web-accessible deletion URL** for the Console Data Safety section.
- Tests: unit test for the use case (re-auth + delete paths); widget test for the Settings entry + confirm dialog.

### Batch 1B — 16 KB remediation `[code/verify]` 🔴 (N7) — *only if 0A found offending libs*
- For each non-aligned `.so`: upgrade the owning plugin to a 16 KB-aligned release; if none exists, evaluate alternatives or vendor a rebuilt lib.
- Re-run 0A until **all** libs are aligned. If 0A was clean, record "verified clean" (no-op).

### Batch 1C — Privacy policy in-app link `[code]` 🔴 (audit #2)
- Add an in-app privacy-policy link (Settings/About + login screen, since login is mandatory).
- Wire to the live policy URL (provided by you).

**✅ Checkpoint 1:** Account deletion works end-to-end on device (sign in → delete → data gone → signed out);
AAB has zero 16 KB-unaligned libs; privacy link opens in-app. `melos run analyze` + feature tests green.

---

## Phase 2 — Console & declarations `[console]` 🔴/🟠

In Play Console, informed by Phase 0E. No binary changes.

| Batch | Task | Finding |
|-------|------|---------|
| 2A | **Data Safety form**: reconcile vs. Firebase Auth (email/name), location (geolocator), analytics, crash logs, FCM token, purchase history; declare **no ads / no AD_ID**; add account-deletion web URL | #3 🔴 |
| 2B | **Privacy policy URL** set + valid on listing | #2 🔴 |
| 2C | **Foreground-service declaration** for `mediaPlayback` (audio_service + AdhanPlaybackService) with justification + demo video | #5 🟠 |
| 2D | **USE_EXACT_ALARM declaration**: justify adhan-at-exact-time as core function (fallback = `SCHEDULE_EXACT_ALARM`) | #4 🟠 |
| 2E | **Content rating / ads / IAP** questionnaire refreshed; "Contains ads" unchecked; IAP declared | #11 🟡 |
| 2F | Confirm **versionCode 37 > published**; **Play App Signing** enrolled | #6, N10 🟠 |

**✅ Checkpoint 2:** Every Console section complete and consistent with the binary's actual behavior.

---

## Phase 3 — Release hygiene & build 🟠/🟡

| Batch | Task | Finding | Type |
|-------|------|---------|------|
| 3A | Write `[1.0.5+37]` **CHANGELOG** entry (builds 33–37) + refresh `release_notes.md` en-US + ar so Console "What's new" matches the build | N1 | `[code]` |
| 3B | Bump versionName to **1.0.6** for the production track (recommended — 6 builds under 1.0.5 muddies Vitals) | N2 | `[code]` |
| 3C | Regenerate **store screenshots** for the new launcher icon / coral theme / splash; verify listing icon + title consistency | N11, N12 | `[console]` |
| 3D | Build via **`shorebird release android --flutter-version=3.44.0`** (full release, **not patch** — native code changed) | N5 | `[verify]` |
| 3E | Run the existing **release checklist** (`melos bootstrap/analyze/format/test`, signing checks, internal upload, **Pre-launch report** review) | checklist | `[verify]` |

**✅ Checkpoint 3 (Submission gate):** Internal-track AAB uploaded; Pre-launch report shows
**no 16 KB warnings, no new crashes/ANRs**; screenshots current; changelog matches build.
→ Submit to production with staged rollout (5 → 20 → 50 → 100%).

---

## Phase 4 — DEFERRED to follow-up release (out of scope for 37) 🟡

| Task | Finding | Why deferred |
|------|---------|--------------|
| `extractNativeLibs` → default `false` (smaller install) | N3 | Size/perf only; needs playback + downloader re-test |
| Billing Library **v7 → v8** (gated on `in_app_purchase` plugin v8) | N4 | Deadline **Aug 31 2026**; not due for 37 |
| Bump firebase-crashlytics Gradle plugin to BoM-aligned version | N6 | Build hygiene; verify mapping upload |
| Re-enable Crashlytics collection post-consent (if 0C found it off) | N14 | Improves future Vitals; not a 37 blocker |
| Android 15/16 edge-to-edge / adhan-FGS hardening (**if 0D found regressions** → escalates into Phase 1) | N8, N9 | Conditional on Phase 0 results |
| `ACCESS_MEDIA_LOCATION` removal if unused | #9 | Permission hygiene |

> ⚠️ **Escalation rule:** If Phase 0D finds the **adhan FGS doesn't fire** on Android 14/15
> or edge-to-edge **clips content**, those move **out of Phase 4 into Phase 1** — a core
> prayer feature silently breaking is worse than a delayed submission, even though Play
> won't reject for it.

---

## Go / No-Go

🔴 **NO-GO until Phases 0–3 complete.** Two independent hard blockers gate submission:
1. **Audit #1** — no in-app account deletion (hard policy blocker given mandatory login).
2. **N7** — 16 KB page-size compatibility must be verified against the actual `.so` files in the AAB before the upload can be trusted to pass.

**First implementation PR (on approval):** Batch **1A (account deletion)** — the gating
Critical — paired with Batch **3A (changelog/release-notes)** as a low-risk companion.
