# Cursor project rules

Rules in `.cursor/rules/` apply when this workspace is open in Cursor.

| Rule | Scope | Purpose |
|------|--------|---------|
| [karpathy-guidelines.mdc](rules/karpathy-guidelines.mdc) | Always | Think first, simplicity, surgical diffs, verifiable goals |
| [tilawa-dart.mdc](rules/tilawa-dart.mdc) | `**/*.dart` | Tilawa architecture + `dart analyze` / `flutter test` checks |
| [clean-code-guard.mdc](rules/clean-code-guard.mdc) | `**/*.dart`, agent-requested | Guard pass for changed production code (Clean Code, SOLID, DRY/KISS/YAGNI, LLM failure modes) |
| [test-guard.mdc](rules/test-guard.mdc) | `**/*_test.dart`, agent-requested | Guard pass for changed test code (mock abuse, bloat, implementation-detail asserts) |
| [docs-guard.mdc](rules/docs-guard.mdc) | `**/*.md`, agent-requested | Guard pass for changed docs (verify symbols/samples vs source, catch drift) |

**Senior Flutter persona:** skill [`tilawa-senior-flutter`](../.agents/skills/tilawa-senior-flutter/SKILL.md)
(**TilawaAISeniorFlutter**) — clean architecture, SOLID, and verifiable feature
implementation. Delegate PR fixes and feature work to this agent by name.

**Confirm in Cursor:** Settings → Rules — all rules should appear;
`karpathy-guidelines` is always on; the others activate by glob or when the
agent requests them for a review/guard pass.

**Other agents:** Same behavior is mirrored in `CLAUDE.md`, `AGENTS.md`, and
`.agent/rules/karpathy-guidelines.md`. The three guard rules are condensed from
the canonical skills in [`.agents/skills/`](../.agents/skills/) (`clean-code-guard`,
`test-guard`, `docs-guard`), which Claude Code consumes directly via
[`.claude/skills/`](../.claude/skills/); see
[`.agents/skills/GUARD_SKILLS_LICENSE`](../.agents/skills/GUARD_SKILLS_LICENSE)
for attribution.

Source for behavioral guidelines:
[multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills).
