<!-- AI-OS START (kept above SpecKit markers so regeneration won't clobber it) -->
## ⚑ AI Agent Operating System — read first

Before any task, read **[`.ai/OPERATING_SYSTEM.md`](.ai/OPERATING_SYSTEM.md)** —
the canonical rules for AI agents in this repo (golden rules, mandatory
workflow, forbidden behavior, modes, risk levels, verification, report format).

**Golden rules (summary):** do only the task • think before editing • smallest
diff • no new regressions • respect the architecture (bloc / get_it / GoRouter /
`Either`) • use design tokens + `context.l10n`, never hard-code • verify with the
project's own commands • ask on High risk or ambiguity • report honestly.

Workflow files:
- Paste-in task spec → [`.ai/TASK_TEMPLATE.md`](.ai/TASK_TEMPLATE.md)
- Human review gate → [`.ai/REVIEW_CHECKLIST.md`](.ai/REVIEW_CHECKLIST.md)
- Job prompts → [`.ai/prompts/`](.ai/prompts/): `bug-fix`, `ui-ux`, `refactor`,
  `test-coverage`, `release-build`, `diff-review`.

**Verify (workspace root):** `melos run fix:format` · `melos run analyze` ·
`melos run test` (or `flutter test test/features/<feature>`) · functions:
`npm run build` / `npm run test:emulator`. Full command list in the OS file §5.

Tilawa architecture, repo layout, testing, and common commands:
**[`CLAUDE.md`](CLAUDE.md)** (canonical). Do not invent stack defaults that
conflict with it (e.g. prefer built-in state management over `flutter_bloc`).
<!-- AI-OS END -->

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan:
[specs/039-learn-quran-admin-backend/plan.md](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/specs/039-learn-quran-admin-backend/plan.md)
<!-- SPECKIT END -->

## Agent behavior (required)

On every task, follow the **Karpathy guidelines** in
[`.cursor/rules/karpathy-guidelines.mdc`](.cursor/rules/karpathy-guidelines.mdc):

think before coding, simplicity first, surgical changes, goal-driven execution
with verifiable checks.

When editing Dart (`apps/tilawa/`, `packages/`), also apply
[`.cursor/rules/tilawa-dart.mdc`](.cursor/rules/tilawa-dart.mdc) — run
`melos run fix:format` from the workspace root after edits and before commit,
then `dart analyze` and targeted `flutter test` from `apps/tilawa/` before finishing.

See [`.cursor/README.md`](.cursor/README.md) for the rules index.

**Home dashboard (approved):** Implementation →
[home-dashboard-patterns.md](.agents/skills/tilawa-apply-ui-principles/references/home-dashboard-patterns.md).
Design intent →
[home_screen_design_artifacts.md](docs/design/home_screen_design_artifacts.md).
Preserve layout; do not redesign or reorder unless the user asks.

---

## UI Kit interaction feedback

Interactive surfaces ([`TilawaInteractiveSurface`](packages/ui_kit/lib/src/foundation/tilawa_interactive_surface.dart))
use **soft Material ink (splash/highlight) plus stable state-layer press feedback**.
See [`packages/ui_kit/docs/design_system.md`](packages/ui_kit/docs/design_system.md) §4.1.

**TilawaCard nested taps:** parent `onTap` fires from blank areas only; enabled
nested controls keep their own action; disabled nested controls are dead zones.
Conflicting actions → sibling `Row` pattern (see [`CLAUDE.md`](CLAUDE.md)).

---

## Docs & skills (open on demand)

| Need | Read |
| --- | --- |
| Visual / UX tokens | [`DESIGN.md`](DESIGN.md), [`docs/tilawa_brand.md`](docs/tilawa_brand.md) |
| Support / monetization ethics | [`specs/016-support-tilawa/spec.md`](specs/016-support-tilawa/spec.md), [`packages/ui_kit/docs/support_visual_system.md`](packages/ui_kit/docs/support_visual_system.md) |
| Backlog | [`docs/TODO.md`](docs/TODO.md) |
| Quran Sessions (perf → UX → UI) | [`docs/quran_sessions/performance_first_review_framework.md`](docs/quran_sessions/performance_first_review_framework.md); Cursor: [`.cursor/rules/quran-sessions-performance-first.mdc`](.cursor/rules/quran-sessions-performance-first.mdc) |
| Startup / splash (P0) | [`docs/startup_splash_plan.md`](docs/startup_splash_plan.md) |
| Senior Flutter agent | [`tilawa-senior-flutter`](.agents/skills/tilawa-senior-flutter/SKILL.md) |
| UI / UX skills | `tilawa-apply-ux-principles`, `tilawa-apply-ui-principles`, `tilawa-ui-ux-guard`; tokens: `flutter-apply-tilawa-theming` |
| External moodboards (optional) | [`design-md/`](design-md/), [`docs/design/awesome-design-md-readme.md`](docs/design/awesome-design-md-readme.md) |

Caveman reply style and lean-ctx MCP usage are covered by always-applied Cursor
rules (`.cursor/rules/caveman.mdc`, `~/.cursor/rules/lean-ctx.mdc`). Do not
duplicate them here.

<!-- lean-ctx -->
## lean-ctx

lean-ctx is active — the MCP tools replace native equivalents.
Full rules: LEAN-CTX.md (open on demand — do not auto-load).
<!-- /lean-ctx -->
