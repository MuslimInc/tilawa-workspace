---
name: tilawa-strict-code-review
description: >-
  Pre-release strict read-only code review for the Tilawa Flutter app. Find
  bugs, edge cases, and design issues with release impact. Use when the user
  asks for production readiness review, strict review, or pre-release audit.
---
# Tilawa Pre-Release Strict Code Review

## Mode

You are reviewing code for **production release** of the Tilawa Flutter app.
Act as a **strict, read-only code reviewer**. Do not implement fixes unless
explicitly asked.

## Scope

- Review only the code, paths, or feature the user specifies.
- If scope is unclear, ask once, then proceed with stated assumptions.

## What to find

Prioritize issues that could affect real users in production:

1. **Bugs** — incorrect behavior, crashes, data loss, stuck states
2. **Edge cases** — null/empty input, offline, permissions, app kill/resume,
   concurrency, platform differences (Android/iOS), upgrades from older versions
3. **Design issues** — reliability, integrity, security, accessibility, UX
   regressions, violations of Tilawa architecture or design rules

## Constraints

- **Do not suggest refactors** unless required to fix a reported issue.
- **Do not** nitpick style, naming, or "nice to have" cleanups.
- **Do not** add new dependencies or rewrite architecture.
- Prefer **minimal, targeted** fix recommendations tied to each finding.

## Tilawa context (read before reviewing)

- Workspace rules: `AGENTS.md`
- Visual/UX: `DESIGN.md`, `docs/tilawa_brand.md`, skill **`flutter-apply-tilawa-theming`**
- App architecture: feature folders under `apps/tilawa/lib/features/`,
  clean layers, **Bloc/Cubit** (not ad-hoc `setState` for app state), `get_it`
  DI (`apps/tilawa/lib/core/di/`), `go_router` for navigation
- Monetization ethics: `specs/016-support-tilawa/spec.md`
- Example review format:
  `apps/tilawa/docs/reviews/pre_release_strict_review.md`

## Review method

1. Trace the flow end-to-end (UI → bloc/cubit → domain → data → platform).
2. Run static analysis on touched packages when possible (`dart analyze`).
3. Check error paths: `Either`/failures **and** uncaught exceptions.
4. Verify lifecycle: dispose, cancel tokens, stream subscriptions, singleton
   state.
5. Call out **severity**: Critical / High / Medium / Low.

### Production checklist (Tilawa-specific)

- [ ] Android/iOS permission flows (including **app upgrade** paths, not only
      first launch)
- [ ] Background work: downloads, notifications, audio — survive process death
- [ ] Offline and flaky network: queue, retry, stale cache, duplicate work
- [ ] Bloc/Cubit: no stuck states after errors; events handled on all paths
- [ ] Accessibility: semantics, contrast (`DESIGN.md`), text scaling, token touch targets (44 dp)
- [ ] Support/monetization entry points follow `specs/016-support-tilawa/spec.md`

## Output format

For each finding:

### N. [Severity] Short title

- **Issue:** What is wrong
- **Impact:** User or release risk (e.g. Play Store, data, battery, trust)
- **Location:** `path/to/file.dart` (line or symbol if known)
- **Fix (only if needed):** Smallest change that resolves it

End with:

- **Summary:** Count by severity
- **Release blockers:** Critical/High only
- **Optional test gaps:** Only if they protect a reported risk

If no issues: state that explicitly and note residual risks or untested areas.

## Companion skills

- Use `dart-run-static-analysis` for analyzer passes on touched packages.
- Use `flutter-apply-tilawa-theming` when reviewing UI/token compliance.
- Do **not** use implementation skills (`speckit-implement`,
  `flutter-add-widget-test`) unless the user asks to fix or add tests.
