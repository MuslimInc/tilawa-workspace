# Requirements Checklist: Quran Player Shell Expand

**Spec**: [../spec.md](../spec.md)  
**Release**: Next app release

## Functional

- [x] FR-001 In-shell overlay expand without `/player` push on shell routes
- [x] FR-002 Continuous drag progress (`drag.update` monotonic in QA)
- [x] FR-003 Drag start does not orphan gesture at ~1px
- [x] FR-004 Footer mini stays mounted during drag
- [x] FR-005 Overlay ignores pointers during drag
- [x] FR-006 Shell pointer route available for move/end retention
- [x] FR-007 YTM-style interactive physics curves
- [x] FR-008 Presentation controller sync during shell drag
- [x] FR-009 Stable semantics IDs for tests/a11y

## Success criteria

- [x] SC-001 Maestro parity flow passes (emulator)
- [x] SC-002 Logcat shows multi-step `drag.update` on slow drag
- [x] SC-003 Unit tests pass
- [x] SC-004 `dart analyze` clean on touched files

## Post-release (explicitly deferred)

- [ ] Phase C legacy route/controller deletion
- [ ] Full YTM visual parity sign-off
- [ ] iOS Maestro parity run
