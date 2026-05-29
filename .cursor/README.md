# Cursor project rules

Rules in `.cursor/rules/` apply when this workspace is open in Cursor.

| Rule | Scope | Purpose |
|------|--------|---------|
| [karpathy-guidelines.mdc](rules/karpathy-guidelines.mdc) | Always | Think first, simplicity, surgical diffs, verifiable goals |
| [tilawa-dart.mdc](rules/tilawa-dart.mdc) | `**/*.dart` | Tilawa architecture + `dart analyze` / `flutter test` checks |

**Confirm in Cursor:** Settings → Rules — both rules should appear;
`karpathy-guidelines` is always on; `tilawa-dart` activates when editing Dart.

**Other agents:** Same behavior is mirrored in `CLAUDE.md`, `AGENTS.md`, and
`.agent/rules/karpathy-guidelines.md`.

Source for behavioral guidelines:
[multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills).
