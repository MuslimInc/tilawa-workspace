# Quran Tutor Visual QA Checkpoints

Use these checkpoints when golden tests are not practical. Capture Arabic RTL
screens on a 360x800 Android viewport, then repeat one pass on a larger Android
device.

## Teachers List With Filters And 3+ Teachers

- Route: `/sessions/teachers`
- State: at least three verified teachers, mixed price/specialization, at least
  one teacher with a generated slot today.
- Verify: compact header, horizontal filters, three cards visible without
  oversized CTAs, card-level `احجز` action is small, profile action is
  secondary, rating uses `جديد` when there are no reviews.
- Expected result: list scans like a compact booking dashboard and availability
  labels come from generated slots.

## Teachers List Empty

- Route: `/sessions/teachers`
- State: no teachers returned for the active market/filter.
- Verify: illustrated empty state, no blank list, teacher-apply and interest
  actions follow feature flags.
- Expected result: user understands there are no matching teachers and has one
  clear next action.

## Teacher Profile With No Slots

- Route: `/sessions/teachers/:teacherId`
- State: verified teacher with valid public profile and no generated slots in
  the 14-day availability window.
- Verify: compact hero, chips in one horizontal row, `نبذة عن المعلم` section,
  slots section says no slots are published, sticky CTA says
  `لا توجد مواعيد متاحة` and is disabled.
- Expected result: no active booking affordance appears when booking cannot
  happen.

## Teacher Profile With Available Slots

- Route: `/sessions/teachers/:teacherId`
- State: verified teacher with one or more generated slots.
- Verify: slot picker is visible, bottom CTA says `احجز جلسة`, selected slot
  is retained when tapped, CTA remains inside safe area and does not cover the
  final content.
- Expected result: user can continue to booking with or without a preselected
  slot.

## My Sessions Upcoming Tab

- Route: `/sessions/my`
- State: at least two upcoming sessions; one nearest session, one session inside
  join window, one outside join window if possible.
- Verify: summary strip, segmented tabs, nearest session highlighted, join CTA
  only when allowed, secondary actions in overflow.
- Expected result: primary action is obvious without repeated heavy action
  groups.

## My Sessions Past Tab

- Route: `/sessions/my`
- State: at least one completed session.
- Verify: no join/cancel heavy actions, optional details/book-again actions are
  compact.
- Expected result: past sessions read as history, not active tasks.

## My Sessions Empty State

- Route: `/sessions/my`
- State: no upcoming or past sessions.
- Verify: empty state title and helper copy are visible, no broken summary/card
  spacing.
- Expected result: user understands they have not booked sessions yet.
