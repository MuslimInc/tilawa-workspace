# UI/UX guard review report template

Use in **review mode** (findings only) or append after **guard-pass** fixes.

```markdown
## Summary
(2–4 bullets: ship / ship with fixes / block)

## Scope
- Files / screens reviewed:
- Skills applied: tilawa-apply-ux-principles, tilawa-apply-ui-principles, tilawa-ui-ux-guard

## Findings

### Critical
(must fix — worship interrupt, broken primary path, a11y blocker, duplicated shell IA)

| # | Finding | Evidence | Fix |
|---|---------|----------|-----|

### Major
(hierarchy, missing states, brand/token break, destructive flow without confirm)

| # | Finding | Evidence | Fix |
|---|---------|----------|-----|

### Minor
(spacing, copy tone, nit)

| # | Finding | Evidence | Fix |
|---|---------|----------|-----|

## Visual verification
- [ ] Light theme
- [ ] Dark theme
- [ ] RTL (Arabic locale)
- [ ] Text scale 1.4
- [ ] Player bar / FAB clearance (if screen has FAB or lists above shell chrome)

## Checklists
- [ ] UX checklist complete
- [ ] UI checklist complete

## Residual risk
(optional — what was not manually verified)
```

## Severity guide

| Level | Examples |
|-------|----------|
| **Critical** | Support UI on worship surface; Home tile duplicates bottom-nav tab; no semantics on sole CTA; data loss without confirm |
| **Major** | Missing empty state; raw hex in feature; two primary CTAs; `TilawaCard` nested conflicting taps |
| **Minor** | Inconsistent `spaceSmall` vs neighbor screen; slightly marketing copy |
