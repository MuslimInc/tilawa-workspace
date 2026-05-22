---
name: dart-fix-runtime-errors
description: >-
  Resolve active Flutter/Dart runtime failures using MCP stack traces and hot
  reload when available; otherwise use static analysis. For analyzer-only
  workflows, prefer dart-run-static-analysis.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Sat, 23 May 2026 12:00:00 GMT
---
# Resolving Dart Runtime and Analysis Errors

## Contents
- [When to use which workflow](#when-to-use-which-workflow)
- [Workflow: Runtime errors (app running)](#workflow-runtime-errors-app-running)
- [Workflow: Static analysis only](#workflow-static-analysis-only)
- [Core guidelines](#core-guidelines)

## When to use which workflow

| Situation | Skill / action |
|-----------|----------------|
| App running, red screen, hot-reload failure | This skill — **Runtime** workflow |
| `dart analyze` failures, no running app | `dart-run-static-analysis` |
| Pre-release review | `tilawa-strict-code-review` |

## Workflow: Runtime errors (app running)

Use when the user reports a crash, exception, or broken UI while the app is
running (Flutter MCP / DevTools available).

**Task Progress:**
- [ ] 1. Fetch the active error via MCP `get_runtime_errors` (or user stack
      trace).
- [ ] 2. Open the failing file/line; read surrounding control flow.
- [ ] 3. Classify: `TypeError` / null assertion → types or `late` init;
      `StateError` → lifecycle; platform channel → permissions/native config.
- [ ] 4. Apply the **smallest** fix; avoid unrelated refactors.
- [ ] 5. Verify with `hot_reload` or restart; confirm error cleared.
- [ ] 6. If fix touches logic, run targeted tests: `flutter test <path>`.

**Do not** catch `Error` subtypes to mask bugs — fix the root cause.

## Workflow: Static analysis only

If there is no running app, **do not** use this skill for deep static-analysis
guidance. Follow `dart-run-static-analysis` instead:

```bash
dart analyze <target>
dart fix --dry-run
dart fix --apply
dart format .
```

## Core guidelines

### Type system
- Add explicit generic types; avoid assigning `List<dynamic>` to `List<T>`.
- Use `covariant` only when intentionally tightening override parameters.
- Prefer `strict-casts` / `strict-inference` in `analysis_options.yaml`.

### Null safety
- Prefer `?`, `??`, and `?.` over `!` unless non-null is guaranteed.
- Use `late` only when initialization is guaranteed before read.

### Error handling (Tilawa)
- Expected failures: return `Either<Failure, T>` (or project pattern).
- Unexpected failures: log and map to failure in Bloc `on<Event>` handlers;
  avoid leaving blocs in a permanent loading/pending state.
- Catch `Exception`, not `Error`; use `rethrow` when wrapping.
