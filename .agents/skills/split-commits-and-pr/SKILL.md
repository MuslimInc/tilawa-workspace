---
name: split-commits-and-pr
description: >-
  Split the current branch into logical commits, push, open a GitHub PR against
  the correct base, and request reviewers. Use when the user asks to split
  commits, prepare a PR, assign reviewers, or hand off a feature branch for review.
---
# Split Commits and Open PR

Turn a feature branch into review-ready commits and a GitHub pull request.

## Hard rules

- Save a backup ref before rewriting history:
  `git update-ref refs/backup/<branch>-pre-split-$(date +%s) HEAD`
- Stage only named files per slice — never `git add .` / `git add -A`.
- Do not force-push without explicit user approval when the branch is shared.
- Follow repo commit message style from `git log` on the base branch.
- Use `gh` for all GitHub operations (push, PR create, reviewer assignment).

## 1. Inspect state

Run in parallel:

```bash
git status
git branch -vv
git log <base>..HEAD --oneline
git diff <base>..HEAD --stat
```

Pick the PR **base** (usually the branch this feature was cut from, not always
`master`). Check `CODEOWNERS` / `PRODUCTOWNERS` for reviewer boundaries.

## 2. Propose commit slices

Default slice order for UI features:

1. `packages/ui_kit` tokens / shared components
2. Domain + data + domain tests
3. Presentation / screens
4. Debug-only or settings tooling (last)

Ask for approval when slices are ambiguous or history rewrite is needed.

## 3. Rewrite commits (when splitting)

```bash
git reset --soft <base>
git reset HEAD
# stage + commit each slice with focused messages
```

## 4. Verify

```bash
dart analyze   # or targeted paths
flutter test test/features/<feature>/
```

## 5. Push and open PR

```bash
git push -u origin HEAD --force-with-lease   # only if history was rewritten
gh pr create --base <base> --title "..." --body "$(cat <<'EOF'
## Summary
- ...

## Commits
- ...

## Test plan
- [ ] ...
EOF
)"
```

## 6. Assign reviewers

**Default reviewer for this repo:** Gemini Code Assist (`gemini-code-assist`).

```bash
# Request reviewer (if the GitHub App is installed)
gh pr edit <number> --add-reviewer gemini-code-assist

# Trigger review when the bot does not auto-assign
gh pr comment <number> --body "/gemini review

@gemini-code-assist please review this PR."
```

Add a **Reviewers** section to the PR body:

```markdown
## Reviewers

- **Gemini Code Assist** (`@gemini-code-assist`) — automated code review
```

If `gh pr edit --add-reviewer` fails, the `/gemini review` comment still
invokes the bot when the app is installed (see PR #90 / #91).

## 7. Report back

Return: commit list, PR URL, reviewers requested, backup ref name.

For implementation fixes from review comments, delegate to
**TilawaAISeniorFlutter** (`tilawa-senior-flutter` skill) — clean architecture,
SOLID, surgical diffs, verified tests.
