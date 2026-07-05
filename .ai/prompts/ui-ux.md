# Prompt — UI / UX

> Paste this, then describe the UI change. Rules from
> [`.ai/OPERATING_SYSTEM.md`](../OPERATING_SYSTEM.md) apply.

You are doing UI/UX work in the Tilawa app. **Mode: Implement. Default risk:
Medium** (Low for pure copy/spacing/icon).

Constraints:

1. **Use the existing design system only.**
   - All colors/sizes/spacing/radius from theme tokens:
     `theme.tokens`, `theme.componentTokens`, `theme.colorScheme`.
   - **Never hard-code** colors, dimensions, or text. User-facing strings go
     through `context.l10n`.
   - Reuse `packages/ui_kit` components (`TilawaCard`, etc.) — don't build
     bespoke equivalents. See [`DESIGN.md`](../../DESIGN.md) and the
     `flutter-apply-tilawa-theming` / `tilawa-apply-ui-principles` skills.

2. **No business-logic changes** unless I explicitly ask. Do not touch blocs/
   cubits, repositories, DI, routing logic, or data mapping. Presentation only.
   If the UI needs new state, ask before adding it.

3. **Preserve approved layouts.** Do not redesign or reorder the home dashboard
   or other approved screens unless I request it.

4. **Watch the known pitfalls:**
   - `TilawaCard` nested interactive children → use the sibling `Row` pattern
     when a nested control needs a *different* action (see `CLAUDE.md`).
   - FluentIcons auto-mirror in RTL — don't "fix" mirrored chevrons.

5. **Verify:** `melos run fix:format`, `melos run analyze`, and any existing
   widget test for the screen (`flutter test test/features/<feature>`).

6. **Manual QA checklist (include in report, and do it for Medium+):**
   - [ ] Light **and** dark theme
   - [ ] Arabic (RTL) **and** English (LTR)
   - [ ] Small phone width — no overflow; large width still balanced
   - [ ] Loading / empty / error states unaffected
   - [ ] Tap targets and pressed feedback behave; nothing else on screen moved

Report in the §6 format. List anything you deliberately left untouched.
