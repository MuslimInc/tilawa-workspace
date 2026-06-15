# Feature Specification: Smart Khatma & Reading Plan

**Feature Branch**: `023-smart-khatma-reading-plan`  
**Created**: 2026-06-15  
**Status**: Draft  
**Input**: Phase 2 engagement engine behind Today Plan.

## Product Specification

Smart Khatma helps users complete the Quran through a calm adaptive plan. Today
Plan answers "what should I do today?"; Smart Khatma answers "where am I going?"

The MVP supports one active plan, generated from a duration preset or custom
duration, and uses the reader's last page as the continuation point. The plan
feeds Today Plan so the daily reading recommendation becomes the active Khatma
target rather than a generic fallback.

## UX Flow

1. User sees a Khatma card on Home.
2. If no plan exists, user chooses a quick duration: 7, 15, 30, or 60 days.
3. App creates a plan from the current/last read page.
4. Home shows progress, day count, remaining pages, remaining days, and today's
   target.
5. Today Plan reads the Khatma target automatically.
6. If the user falls behind, the domain computes an adjusted daily target. Phase
   2.1 exposes the catch-up/extend choice as a dedicated bottom sheet.

## User Stories

- As a reader, I can start a Khatma without manually calculating pages per day.
- As a returning reader, I can see how far I am through my current Khatma.
- As an inconsistent reader, I see a calm adjusted target instead of failure.
- As a Today Plan user, my reading task reflects my long-term Khatma goal.

## Edge Cases

- No last-read page: start at page 1.
- Last-read page beyond 604: clamp to page 604 and mark complete when needed.
- Duration shorter than remaining pages: daily pages can be high but explicit.
- Missed days: target increases using remaining pages / remaining days.
- Expired plan with remaining pages: MVP uses catch-up target; later UX offers
  extend or catch-up selection.
- Storage missing/corrupt: ignore corrupt plan and show empty state.

## Premium Strategy

Free:
- One active Khatma plan.
- Standard progress tracking.
- Today Plan integration.

Premium:
- Multiple plans.
- Custom schedules.
- Smart recovery choice UI.
- Reading analytics and insights.
- Historical completions.
- Completion prediction and adaptive plans.

## Analytics Plan

- `khatma_created`: `plan_id`, `duration_days`, `start_page`,
  `target_page`, `daily_target_pages`, `reading_style`.
- `khatma_started`: same as created, emitted when first shown as active.
- `khatma_progress_updated`: `plan_id`, `current_page`, `progress_percent`,
  `remaining_pages`.
- `khatma_goal_completed`: `plan_id`, `date_key`, `pages_completed`.
- `khatma_plan_adjusted`: `plan_id`, `old_daily_target_pages`,
  `new_daily_target_pages`, `missed_days`.
- `khatma_catchup_selected`: `plan_id`, `new_daily_target_pages`.
- `khatma_extend_selected`: `plan_id`, `new_target_date`.
- `khatma_completed`: `plan_id`, `duration_days`, `completed_days`.
- `khatma_dashboard_viewed`: `plan_id`, `progress_percent`, `current_day`.
- `khatma_continue_reading`: `plan_id`, `start_page`, `today_target_pages`.

## Database Schema

MVP local key: `smart_khatma.active_plan.v1`

```json
{
  "id": "local_2026-06-15T09:00:00.000",
  "created_at": "2026-06-15T09:00:00.000",
  "start_date": "2026-06-15T00:00:00.000",
  "duration_days": 30,
  "start_page": 1,
  "target_page": 604,
  "current_page": 1,
  "reading_style": "pages",
  "preferred_minutes_per_day": null,
  "status": "active"
}
```

Migration strategy: keep versioned keys; when adding multiple plans, migrate
the active-plan object into a list table/key and preserve active `id`.

## Domain Models

- `KhatmaPlan`: active long-term plan.
- `KhatmaTodayTarget`: computed today's target for Home and Today Plan.
- `KhatmaReadingStyle`: pages or minutes.
- `KhatmaPlanStatus`: active or completed.

## Flutter Architecture Design

- `features/smart_khatma/domain`: entities, repository interface, use cases.
- `features/smart_khatma/data`: SharedPreferences datasource and repository.
- `features/smart_khatma/presentation`: Bloc and Home card.
- Home composes `SmartKhatmaCard`.
- Today Plan receives `GetKhatmaTodayTargetUseCase` and uses it for the reading
  task when an active plan exists.

## Implementation Roadmap

1. MVP: one active plan, Home card, Today Plan integration.
2. Recovery UX: catch up faster vs extend plan bottom sheet.
3. Progress write-back from reader session completion.
4. Premium analytics and historical insights.
5. Multiple plans and custom weekly schedules.

## Two-Week Smallest Premium Version

Ship one active Smart Khatma plan with duration presets, a polished Home
dashboard card, Today Plan integration, and calm recovery math that adjusts the
daily page target. This is small enough for two weeks, feels premium because it
is adaptive and integrated, and directly improves retention by giving every
opening session a long-term purpose.
