# Review Checklist

Run through this before accepting an agent's work. Anything unchecked = send it
back. Skim `git diff` alongside these questions.

## Scope
- [ ] Every changed file traces to the task. No unrelated files touched.
- [ ] No drive-by renames, import re-sorting, or repo-wide reformatting.
- [ ] The agent stayed in the declared **mode** (didn't implement during a
      Plan/Review task, didn't exceed a single step, etc.).

## Diff quality
- [ ] Smallest reasonable diff; no dead code, no commented-out blocks left.
- [ ] Matches surrounding style, naming, and comment density.
- [ ] No hard-coded colors, sizes, spacing, or user-facing strings
      (tokens + `context.l10n` used).
- [ ] No debug prints / leftover TODOs introduced.

## Architecture & state
- [ ] flutter_bloc used correctly (Cubit preferred); no business logic in widgets.
- [ ] DI via get_it constructor injection; nothing new-ed up ad hoc.
- [ ] `Either<Failure, T>` at boundaries; nothing thrown across layers.
- [ ] No `BuildContext` below the presentation layer.
- [ ] Routing changes go through GoRouter config / typed routes.

## Tests
- [ ] New behavior has a test; a fixed bug has a regression test.
- [ ] Assertions are real (not `expect(true)`, not snapshots of buggy output).
- [ ] Existing tests were **not** weakened or deleted to pass.
- [ ] `melos run test` (or the relevant feature test) actually passed — output shown.

## Regressions
- [ ] `melos run analyze` clean; `melos run fix:format` applied.
- [ ] Blast radius named: what else uses this code, and why it's still fine.
- [ ] Shared code (`packages/ui_kit`, `packages/core`) changes checked against
      all consumers.

## UI / UX (if presentation touched)
- [ ] Loading / empty / error states still correct.
- [ ] RTL/Arabic + light/dark still look right (FluentIcons auto-mirror in RTL —
      not a bug).
- [ ] No layout overflow; responsive on small screens.
- [ ] Approved layouts (home dashboard) not silently redesigned.

## Release / build risk (if touched)
- [ ] No unintended changes to flavors, signing, `firebase.json`,
      `firestore.rules`, `firestore.indexes.json`, or CI workflows.
- [ ] New Firestore collection ⇒ matching rule added.
- [ ] Cloud Functions changes: `npm run build` + `npm run test:emulator` passed.
- [ ] No version bumps or dependency changes snuck in.

## Report
- [ ] Final report follows §6 format (summary, files, verification, regression,
      manual QA, out-of-scope).
- [ ] Manual QA steps are listed and you actually did them for Medium/High risk.
