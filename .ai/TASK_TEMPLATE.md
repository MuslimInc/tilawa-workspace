# Task Template

Copy this block, fill it in, and paste it to the agent. Keep it short — the
agent already knows the rules from [`.ai/OPERATING_SYSTEM.md`](OPERATING_SYSTEM.md).

```md
## Task
<what you want, in one or two sentences>

## Expected behavior
<what "correct" looks like after the change; observable result>

## Scope
Touch: <files/features allowed>
Do NOT touch: <anything off-limits — default: everything else>

## Risk level
Low | Medium | High
(Low: copy/spacing/icon. Medium: layout/nav/states/component behavior.
 High: auth, payment, booking, routing, delete-account, state mgmt, offline,
 firestore rules, cloud functions, CI/CD, release.)

## Mode
Review only | Plan only | Implement | Implement step only | Test only |
Diff review only | Release/build only
(If "Implement step only": step = <name the single step>)

## Verification required
- [ ] melos run fix:format
- [ ] melos run analyze
- [ ] flutter test test/features/<feature>   (or melos run test)
- [ ] <functions: npm run build / npm run test:emulator, if backend touched>
- [ ] Manual QA: <screens/flows to click through>

## Notes / constraints
<links, design intent, tickets, edge cases, "ask me before X">
```

### Minimal example
```md
## Task
The booking "Confirm" button stays disabled after selecting a valid slot.
## Expected behavior
Selecting any available slot enables Confirm; deselecting disables it again.
## Scope
Touch: packages/quran_sessions/lib/.../booking_screen*, booking_bloc*
Do NOT touch: pricing, session creation, firestore rules.
## Risk level
High (booking)
## Mode
Implement
## Verification required
- [ ] melos run fix:format
- [ ] melos run analyze
- [ ] flutter test (from packages/quran_sessions)
- [ ] Manual QA: pick slot → Confirm enables; unpick → disables
## Notes
Root-cause first; add a failing bloc test before fixing.
```
