# Tilawa Support Surfaces — Visual System

Visual and UX rules for **Support Tilawa** (voluntary one-time contribution).
This is separate from “visual premium” (calm, high-quality UI) described in
[`premium_visual_system.md`](premium_visual_system.md).

**Product spec:** [`specs/016-support-tilawa/spec.md`](../../../specs/016-support-tilawa/spec.md)  
**Brand intent:** [`docs/tilawa_brand.md`](../../../docs/tilawa_brand.md) §12  
**Tokens:** [`DESIGN.md`](../../../DESIGN.md) §15

---

## 1. Design intent

Support screens should feel:

- **Calm** — parchment surfaces, generous spacing, one primary CTA
- **Respectful** — no sales pressure, no worship-adjacent urgency
- **Transparent** — impact bullets, Play footer, optional legal disclaimer
- **Grateful** on success — quiet thank-you, not a celebration

They must **not** feel like a SaaS upgrade page, fintech upsell, or game reward screen.

---

## 2. Color and accent rules

| Rule | Implementation |
|------|----------------|
| One **interactive** accent per screen | `colorScheme.primary` (Ink) for **Continue on Google Play** only |
| Tier identity washes | Muted tints from `primary` / `secondary` / `tertiary` @ ~7–16% on `surface` — decorative, not second CTAs |
| No gold pay CTA | Do **not** use `tertiary` (Gilding) on purchase buttons — brand anti-pattern |
| No gold gradients | No VIP headers, metallic meshes, or “luxury tier” backgrounds |
| Surfaces | Intro: plain text; tier **group**: `surfaceContainerLow`; cards: `surface` + hairline `outlineVariant` |
| Selected tier | Tier accent border (~1.25 dp) + stronger tint + check in tier accent — not shared `primaryContainer` for all |
| Success | `TilawaEmptyState` with neutral icon (`favorite_outline` or calm check) — not green confetti |

Subtle spiritual styling: open-corner arc painter per tier at ≤ `opacitySubtle × 0.4`,
**never** framing the CTA.

---

## 3. Typography and copy presentation

- **Title:** `supportTilawa` — app bar via `TilawaAppBar`
- **Intro:** single `supportIntroLine` — `bodyMedium`, `onSurfaceVariant`, `textHeightLoose` (Arabic)
- **Impact:** collapsible `supportImpactWhyTitle`, three `bodyMedium` bullets when expanded
- **Tier labels:** `titleSmall` w700 + price `titleMedium` w600; icons in 44 dp capsule
- **Trust:** one `supportTrustLine` — `labelSmall`, `onSurfaceVariant`

Avoid `displayLarge`, “% OFF”, streak counters, and exclamation marks.

---

## 4. Components (UI Kit)

| UI block | Kit component |
|----------|----------------|
| Screen scaffold | `TilawaAppBar` + `TilawaContentBounds` (`form`, max 560) |
| Impact list | Custom rows or `TilawaEmptyState`-level spacing — hairline-free bullets with quiet icons |
| Tier selector | `SupportTierSelector` group + `SupportTierCard` (accent, arc, capsule icon) |
| Primary CTA | `TilawaButton` primary variant; `isLoading` during purchase |
| Secondary restore | `TextButton` or `TilawaSettingsTile` pattern — not a second primary |
| Confirmation | `TilawaBottomSheetScaffold` + `TilawaBottomSheetTitleRow` |
| Thank-you | `TilawaEmptyState` + single `TilawaButton` Done |
| Errors / offline | `TilawaErrorState` with icon + retry — not red alarm panels |

Do **not** reuse subscription plan cards, “Popular” badges, or discount ribbons from legacy premium UI.

---

## 5. Motion

- Sheet open: default modal curve — `easeOutCubic`, no bounce
- Thank-you: cross-fade or simple replace — **no** confetti, Lottie celebrations, or haptics barrage
- Loading: inline on CTA or center `TilawaLoadingIndicator` on first product load only

---

## 6. Layout checklist

- [ ] Max width capped (`TilawaContentKind.form`)
- [ ] Touch targets ≥ 44 dp on tiers and CTAs
- [ ] RTL: tier cards and impact rows mirror; prices remain Play-localized strings
- [ ] Dark mode: same calm surfaces (true-black preset compatible)
- [ ] Text scale 1.4: tier cards grow vertically; no clipped prices

---

## 7. Anti-patterns (support-specific)

- Gold gradient hero with “GO PREMIUM”
- Crown / diamond / trophy icons on pay buttons
- Pulsing CTA or “limited time” banner
- Blocking overlay on Quran or prayer screens
- Post-purchase screen listing “exclusive features unlocked”
- Public leaderboard of supporters

---

## 8. Relationship to `premium_visual_system.md`

That document defines **calm product chrome** (cards, gradients policy, illustrated
states). This document defines **voluntary support monetization surfaces** only.

When both apply: support screens follow **this file** for CTA color, tone, and
entry-point policy; they follow **premium_visual_system** for spacing, hairlines,
and hit targets.
