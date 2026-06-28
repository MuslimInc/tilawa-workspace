---
name: tilawa-ui-ux-guard
description: >-
  Review generated or changed Tilawa UI before it ships — visual hierarchy,
  UX flows, brand alignment, accessibility, placement policy, and kit
  component usage. Best used reactively after an agent builds or refactors
  screens in apps/tilawa. Use when the user asks to review UI/UX, audit a
  screen, check home dashboard design, or before merging presentation-layer
  changes. Pair with flutter-apply-tilawa-theming for token violations. DO NOT
  USE for pure Dart logic review (clean-code-guard), tests (test-guard), or
  documentation (docs-guard).
---

# Tilawa UI/UX Guard

Second-pass quality gate for **presentation-layer** changes. Run after the first
implementation pass; fix violations before delivery.

Does not replace `dart analyze` or widget tests — those are mechanical; this is
the judgement layer for look, feel, and flow.

## How to use

**Guard-pass mode** (default): After UI code is written, walk both checklists
below. Fix must-fix items before handoff.

**Review mode** (user asks "review UI/UX"): Produce findings using
[references/review-report-template.md](references/review-report-template.md)
— do not edit unless asked.

### Severity model

| Level | Ship? | Examples |
|-------|-------|----------|
| **Critical** | Block | Worship-surface interrupt; Home duplicates bottom nav; broken primary path; data loss without confirm; a11y blocker on sole CTA |
| **Major** | Fix first | Missing empty/error state; hierarchy confusion; raw hex; nested `TilawaCard` conflicting taps; unreachable FAB under player |
| **Minor** | Optional | Spacing drift vs neighbor; slightly marketing copy |

## Pre-flight

1. Read changed widgets + one neighbor file for style match
2. Skim `DESIGN.md` §6–§12 and `docs/tilawa_brand.md` §5–§10 if brand-bearing
3. Load checklists from companion skills (do not guess rules)

## Checklists (run both)

### UX — [`tilawa-apply-ux-principles/references/ux-checklist.md`](../tilawa-apply-ux-principles/references/ux-checklist.md)

Focus: user goal, tap depth, placement policy, states, copy, a11y, Home IA.

### UI — [`tilawa-apply-ui-principles/references/ui-checklist.md`](../tilawa-apply-ui-principles/references/ui-checklist.md)

Focus: hierarchy, tokens, elevation, components, RTL, density, FAB/player clearance.

## Tilawa-specific red flags (always check)

| Flag | Why |
|------|-----|
| **Home tile duplicates shell tab** | See home-dashboard-patterns.md |
| **Home redesign without user request** | See home-dashboard-patterns.md |
| Donation/support on reader/prayer/athkar | Violates §9 placement |
| Cold-start modal for new feature | Breaks calm entry |
| Settings-only path to daily action | UX anti-pattern |
| Nested `onTap` inside `TilawaCard` with different actions | Hit-test bug |
| `Color(0xFF...)` in feature code | Bypasses theme |
| `displayLarge` on utility screen | Off-brand hierarchy |
| Gold `tertiary` on button | Reads as paywall |
| Exclamation marketing copy | Off-brand voice |
| No empty state on user-customizable list | Dead end |
| Full-screen picker for ≤10 local toggles | Use bottom sheet |
| Destructive delete without confirm/undo | Data-loss UX |
| FAB/list ignores player bottom inset | Obscured by mini-player or nav |

## Home dashboard extra checks

If touching `features/home/`, verify against
[home-dashboard-patterns.md](../tilawa-apply-ui-principles/references/home-dashboard-patterns.md):

- [ ] No unapproved redesign, reorder, or stale widgets
- [ ] Scope limited to bugs / spacing / overflow / a11y / tokens / RTL unless user asked for redesign

## Visual verification (manual or Maestro)

- [ ] Light + dark theme
- [ ] RTL Arabic locale
- [ ] Text scale 1.4
- [ ] Player bar + bottom nav do not cover FAB or last list items

## Self-check before delivery

- [ ] Ran both checklists on changed files
- [ ] Cited specific widgets for each finding
- [ ] Critical/major items fixed or explicitly deferred with user approval
- [ ] `dart analyze` + targeted widget tests mentioned in handoff

## Companion skills

| Skill | When |
|-------|------|
| `tilawa-apply-ux-principles` | Designing flows / IA |
| `tilawa-apply-ui-principles` | Composing layout / components |
| `flutter-apply-tilawa-theming` | Token and color details |
| `flutter-build-responsive-layout` | Breakpoints / constraints |
| `clean-code-guard` | Non-UI logic quality |
