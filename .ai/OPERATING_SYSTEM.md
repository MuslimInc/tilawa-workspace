# AI Agent Operating System — Tilawa

Main rules for **any** AI agent working in this repository. Read this before
touching anything. It is intentionally short. When in doubt, stop and ask.

Companion files:
- Paste-in task spec → [`.ai/TASK_TEMPLATE.md`](TASK_TEMPLATE.md)
- Human review gate → [`.ai/REVIEW_CHECKLIST.md`](REVIEW_CHECKLIST.md)
- Job-specific prompts → [`.ai/prompts/`](prompts/)
- Deep style/architecture rules → [`AGENTS.md`](../AGENTS.md), [`CLAUDE.md`](../CLAUDE.md), [`DESIGN.md`](../DESIGN.md)

---

## 1. Golden rules

1. **Do only the task.** Every changed line must trace to the request. No
   drive-by refactors, renames, reformatting, or "while I'm here" fixes.
2. **Think before editing.** Read the relevant code first. State assumptions and
   success criteria before writing code.
3. **Smallest possible diff.** Prefer 5 correct lines over 50 clever ones.
4. **No new regressions.** If you can't show the change is safe, it isn't done.
5. **Respect the architecture.** flutter_bloc (Cubit preferred), get_it DI,
   GoRouter, `Either<Failure, T>` from dartz_plus, no `BuildContext` below the
   presentation layer. Never invent new patterns for solved problems.
6. **Use the design system.** All sizes/colors/strings come from theme tokens
   and `context.l10n` — never hard-code. See [`DESIGN.md`](../DESIGN.md).
7. **Verify with the project's own commands** (§5), not by eyeballing.
8. **Ask when the risk is High or the request is ambiguous.** A 20-second
   question beats a wrong High-risk change.
9. **Report honestly.** If tests fail, say so with output. If you skipped a
   step, say that. Never claim "done and verified" without running §5.

---

## 2. Mandatory workflow

```
UNDERSTAND → PLAN → CONFIRM (if needed) → IMPLEMENT → VERIFY → REPORT
```

1. **Understand** — restate the task, expected behavior, scope, and risk level
   (§4). Read the code paths involved.
2. **Plan** — list the files you will touch and why. For Medium/High risk,
   surface the plan before coding.
3. **Confirm** — for High risk or ambiguity, ask before implementing.
4. **Implement** — surgical edits only, matching surrounding style.
5. **Verify** — run the relevant checks in §5. Fix what you broke.
6. **Report** — use the format in §6.

---

## 3. Forbidden behavior (never do without explicit instruction)

- Touch files unrelated to the task, or reformat/re-sort imports repo-wide.
- Change **application/business logic** during a UI, refactor, or test task.
- Change **behavior** during a refactor. Refactor ≠ redesign ≠ bug fix — never
  mix them in one change.
- Modify or delete **existing tests** to make a change "pass". Fix the code.
- Write **fake/coverage-padding tests** (asserting `true`, snapshotting current
  buggy output, testing framework internals).
- Hard-code colors, sizes, spacing, or user-facing strings.
- Rename packages, move public APIs, or bump dependency versions.
- Change build config, flavors, signing, CI, `firebase.json`,
  `firestore.rules`, or `firestore.indexes.json`.
- Add a new Firestore collection without a matching rule in `firestore.rules`
  (causes `PERMISSION_DENIED`).
- Run destructive git (`reset --hard`, force-push), or commit/push unless asked.
- Deploy anything (`firebase deploy`, release builds) unless the task is
  explicitly Release/build and authorized.
- Bypass layer boundaries (throw across layers, use `BuildContext` in domain/data).

---

## 4. Task types & risk levels

Pick the **mode** and **risk level** for every task. When unstated, infer and
state your inference before starting.

### Modes
| Mode | Agent does | Agent must NOT |
| --- | --- | --- |
| **Review only** | Read + report findings | Edit any file |
| **Plan only** | Produce a step plan + file list | Edit source |
| **Implement** | Full workflow (§2) | Exceed scope |
| **Implement step only** | Do exactly ONE named step, then stop | Continue to next step |
| **Test only** | Add/adjust tests + run them | Change non-test source |
| **Diff review only** | Review staged/uncommitted changes | Edit; only report |
| **Release/build only** | Verify env, build, verify artifact | Change source/behavior |

### Risk levels
| Level | Examples | Required rigor |
| --- | --- | --- |
| **Low** | Copy/text, spacing, icon swap, small UI tweak | Analyze + format; targeted test if one exists |
| **Medium** | UI layout, navigation, loading/empty/error states, component behavior | Full verify (§5) + manual QA of the changed screen |
| **High** | Auth, payment, booking, routing, delete-account, state management, offline behavior, Firestore rules, Cloud Functions, CI/CD, release builds | Plan + confirm first. Mandatory in the report: **root cause** (for fixes), **named regression/blast radius**, **tests** (unit/bloc + emulator/rules where relevant), and **manual QA steps**. Full verify (§5). |

**High-risk hotspots in this repo:** `packages/quran_sessions*` (booking/RTC),
`functions/src/quranSessions/`, `firestore.rules`, `firestore.indexes.json`,
auth flows, `lib/router/`, admin deletion, release flavors and workflows.

---

## 5. Verification commands (this repo)

Run from the **workspace root** unless noted. Use only what the task touches.

**Dart / Flutter (apps + packages)**
```sh
dart run melos bootstrap          # link workspace packages (once per clone / pubspec change)
dart run melos run fix:format     # dart fix + format — run after edits, before finishing
dart run melos run analyze        # dart analyze --fatal-infos across packages
dart run melos run bloc:lint      # bloc_tools lint (state-management changes)
dart run melos run test           # all package/app tests
dart run melos run gen            # l10n + build_runner (only if you changed generated inputs)
```
App-scoped (faster, from `apps/tilawa/`):
```sh
flutter test                             # app tests
flutter test test/features/<feature>     # single feature
```

**Cloud Functions (from `functions/`)**
```sh
npm run build           # tsc typecheck/compile
npm test                # unit tests
npm run test:emulator   # integration + firestore rules tests (needs emulator)
npm run test:rules      # firestore.rules tests only
```

**Build / release (only in Release/build mode, when authorized)**
```sh
dart run melos run tilawa:build:android:production   # signed-ready production AAB (arm64)
```
CI reference: `.github/workflows/` — `pr-checks.yml`, `android-release.yml`,
`firebase-app-distribution.yml`, `firebase-admin-hosting.yml`.

> If a command is unavailable in your environment, say so in the report — do
> **not** silently skip verification and claim success.

---

## 6. Final report format

Always end an Implement/Test/Release task with:

```
## Summary
<1–3 sentences: what changed and why>

## Mode / Risk
<mode> / <Low|Medium|High>

## Files changed
- path — one-line reason (repeat per file)

## Verification
- <command> → <PASS/FAIL + key output>
(list every check you ran; note anything you could NOT run)

## Regression check
<what could this break, and why it doesn't>

## Manual QA needed
<steps a human should click through, or "none">

## Out of scope / follow-ups
<things you noticed but deliberately did NOT touch>
```

For **Review only / Plan only / Diff review only**, replace "Files changed"
and "Verification" with your findings/plan; do not report edits you didn't make.

---

## 7. Task-type quick rules

- **Bug fix** → root-cause first, failing test when practical, fix, no unrelated
  changes. Prompt: [`prompts/bug-fix.md`](prompts/bug-fix.md).
- **UI/UX** → design tokens + l10n only, no business-logic changes, manual QA
  checklist. Prompt: [`prompts/ui-ux.md`](prompts/ui-ux.md).
- **Refactor** → zero behavior change, no bug fixes mixed in.
  Prompt: [`prompts/refactor.md`](prompts/refactor.md).
- **Tests** → match existing patterns, real assertions only.
  Prompt: [`prompts/test-coverage.md`](prompts/test-coverage.md).
- **Release/build** → verify env + artifact + output path.
  Prompt: [`prompts/release-build.md`](prompts/release-build.md).
- **Diff review** → flag unrelated/risky changes, missing tests, QA needs.
  Prompt: [`prompts/diff-review.md`](prompts/diff-review.md).
