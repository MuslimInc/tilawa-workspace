# Quran Sessions — Phase 2 Learn Playbook

Phase 2 runs **4–8 weeks** after Phase 1 ships. Goal: collect decision metrics
to approve or reject Phase 3 (`PublishedWeekAvailability`, hybrid /
weekly_publish bookability). No new bookability model ships in Phase 2.

---

## Decision metrics

| Metric | Event(s) | Params to segment | What “good” looks like |
|--------|----------|-------------------|------------------------|
| Friday banner engagement | `friday_review_banner_shown`, `friday_review_banner_tapped`, `friday_review_banner_dismissed` | `market_code`, `next_week_slot_count`, `this_week_slot_count` | CTR (tapped / shown) **> 15%** on Fridays where `next_week_slot_count = 0` |
| Next-week gap signal | `week_view_opened` | `section=next_week`, `slot_count` | High share of Friday `week_view_opened` with `slot_count=0` confirms problem size |
| Template save after reminder | `weekly_template_saved` within 24h of `friday_review_banner_tapped` (same `teacher_id` / device) | `days_open`, `open_day_count_change`, `duration_changed` | **≥ 30%** of banner tappers save template within 24h |
| Student booking friction | `booking_lost_due_to_no_availability` | `teacher_id`, `requested_from`, `requested_to`, `market_code` | Flat or declining trend vs baseline; spike triggers teacher outreach, not Phase 3 by itself |

### Go / no-go thresholds (Phase 3 gate)

Proceed to Phase 3 design only if **all** hold for the primary pilot market(s)
over the learn window:

1. **Banner CTR > 15%** (tapped ÷ shown) when `next_week_slot_count = 0`.
2. **≥ 30%** of `friday_review_banner_tapped` users fire `weekly_template_saved`
   within 24 hours.
3. **Qualitative:** ≥ 5 teacher interviews agree week-scoped planning matches
   mental model (see interview guide below).
4. **No-go:** `booking_lost_due_to_no_availability` rises **> 20%** week-over-week
   without corresponding template-save uplift — indicates UX confusion, not
   unmet demand.

If thresholds fail, keep Phase 1 UX, disable experiment per market (below), and
defer Phase 3.

---

## Querying analytics

Event names (Firebase / internal analytics):

| Event | Key params |
|-------|------------|
| `week_view_opened` | `scheduling_mode`, `policy_version`, `market_code`, `section`, `slot_count` |
| `friday_review_banner_shown` | above + `next_week_slot_count`, `this_week_slot_count` |
| `friday_review_banner_tapped` | same as shown |
| `friday_review_banner_dismissed` | same as shown |
| `weekly_template_opened` | `scheduling_mode`, `policy_version`, `market_code`, `source` |
| `weekly_template_saved` | above + `days_open`, `duration_changed`, `open_day_count_change` |
| `booking_lost_due_to_no_availability` | `teacher_id`, `requested_from`, `requested_to`, `market_code` |

Example funnels:

- **Banner CTR:** `friday_review_banner_tapped` / `friday_review_banner_shown`
  filter `next_week_slot_count = 0`.
- **Save after tap:** users with `friday_review_banner_tapped` then
  `weekly_template_saved` within 24h (device or authenticated teacher id).
- **Booking loss rate:** count `booking_lost_due_to_no_availability` per week /
  active teachers with zero next-week slots.

Constants: `packages/core/lib/constants/analytics_constants.dart`.

---

## Ops: disable experiment per market

Without an app release, ops can tone down or disable Phase 1–2 UX per market via
Firestore.

**Global defaults**

```
quran_session_platform_config/global
  scheduling: { ... }
```

**Market override**

```
quran_session_market_configs/{countryCode}
  scheduling:
    week_scoped_dashboard_enabled: false   # revert to horizon list
    friday_review_reminder_enabled: false # hide banner
    scheduling_mode: recurring            # keep bookability safe
```

Changes propagate on next teacher dashboard load (`GetMarketSchedulingConfigUseCase`).

---

## Teacher interview guide (5–10 teachers)

Target: verified teachers in pilot markets who saw the Friday banner or use the
week-scoped dashboard.

1. Walk me through how you plan availability for **this week** vs **next week**.
2. When you open the dashboard, do the two sections match how you think?
3. Did you notice the Friday reminder? What did you do after tapping it?
4. How do you decide which days to open / close for the coming week?
5. Would you prefer to **publish** next week explicitly, or keep editing the
   recurring template?
6. Have students told you they could not find a slot? When did that happen?
7. What would make you trust that “next week is ready” without checking every day?
8. Anything confusing about lesson duration vs open hours?
9. Would a weekly publish step feel like extra work or helpful control?
10. If we removed the banner tomorrow, would you miss it?

Capture quotes + whether they align with go threshold #3.

---

## Engineering checklist (Phase 2 complete)

- [x] `weekly_template_saved` on successful availability save
- [x] `booking_lost_due_to_no_availability` on empty unbooked slot list
- [x] Persistent `FridayReviewReminderStore` (SharedPreferences in production)
- [x] ADR-006 + this playbook
- [ ] 4–8 week data collection window (ops / product)
- [ ] Go/no-go review with metrics + interviews

---

## Phase 3 follow-ups (out of scope for Phase 2)

- `PublishedWeekAvailability` entity + Firestore artifact
- `SchedulingMode.hybrid` / `weekly_publish` in `SlotGenerator` path
- Publish / unpublish flows and admin panel (MeMuslim) — separate initiative
- Push notifications for Friday review — deferred
