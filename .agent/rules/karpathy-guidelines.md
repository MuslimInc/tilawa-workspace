---
trigger: always_on
---

# Karpathy behavioral guidelines

Apply on every task. Full text: `.cursor/rules/karpathy-guidelines.mdc`.

1. **Think before coding** — State assumptions; ask when ambiguous; surface
   tradeoffs; push back on overkill.
2. **Simplicity first** — Minimum code for the request; no speculative abstractions.
3. **Surgical changes** — Touch only what the task requires; match existing style;
   mention unrelated dead code, do not delete it.
4. **Goal-driven execution** — Define verifiable success (tests, `dart analyze`);
   plan multi-step work as step → verify.

For Dart in this repo, also follow `.cursor/rules/tilawa-dart.mdc` and `CLAUDE.md`
(includes `melos run fix:format` after edits and before commit).
