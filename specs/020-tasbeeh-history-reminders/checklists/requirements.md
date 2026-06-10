# Requirements Checklist: Tasbeeh History Grid, Clear All & Reminders

**Spec**: [`../spec.md`](../spec.md) | **Status**: Draft

Use before marking feature **Implemented**.

## User Story 1 — Grid view

- [ ] List/grid toggle visible when saved dhikr count ≥ 1
- [ ] Grid shows 2 columns on phone-width, 3 on tablet-width
- [ ] Cell shows dhikr title + `count / target`
- [ ] Tap cell opens saved-dhikr counting
- [ ] Layout preference survives app restart
- [ ] RTL: grid order and typography correct in Arabic
- [ ] Dark mode: cells use theme tokens only

## User Story 2 — Clear all

- [ ] “Clear all” hidden/disabled when no saved dhikr
- [ ] Confirmation shows item count
- [ ] Confirm removes all Hive records
- [ ] Cancel leaves data unchanged
- [ ] Active counting session cleared after clear all
- [ ] l10n EN + AR for dialog copy

## User Story 3 — Reminders

- [ ] Enable/disable reminder per saved dhikr
- [ ] Time picker stores local time (hour/minute)
- [ ] Notification permission requested before first schedule
- [ ] Permission denied → explanatory UI + settings link
- [ ] Daily notification fires at chosen time (Android QA)
- [ ] Tap notification → Tasbeeh counting for correct dhikr
- [ ] Delete dhikr cancels its notification
- [ ] Clear all cancels all tasbeeh reminder notifications
- [ ] Timezone change reschedules on app resume
- [ ] No collision with prayer/athkar notification IDs

## Regression

- [ ] Per-item delete still works (list mode)
- [ ] Quick count unchanged
- [ ] Create new tasbeeh flow unchanged
- [ ] `flutter test test/features/athkar/` passes
- [ ] `dart analyze` clean

## Accessibility

- [ ] Grid cells have semantic labels (dhikr + progress)
- [ ] Toggle announces list vs grid state
- [ ] Reminder time picker accessible
