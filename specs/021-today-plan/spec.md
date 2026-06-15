# Feature Specification: Today Plan

**Feature Branch**: `021-today-plan`  
**Created**: 2026-06-14  
**Status**: Draft  
**Input**: User description: "Tilawa — Today Plan (Premium MVP)"

## Product Specification

Today Plan is Tilawa's daily guidance surface: a calm, Quran-first plan that
answers "what should I do today, how long will it take, and what is next?"
without making the user assemble their own task list.

The MVP must feel like a premium daily companion, but it must also respect the
current Tilawa monetization policy in `specs/016-support-tilawa/spec.md`:
Quran reading, normal listening, prayer, and athkar stay free. User-facing
copy should avoid "Premium/Pro/Unlock" and use Support Tilawa language until
that policy is formally amended.

### Goals

- Increase daily opens by making the home screen immediately actionable.
- Increase Quran reading and listening consistency through small daily actions.
- Reduce decision fatigue for users who do not know where to resume.
- Create a clear roadmap for adaptive goals, recovery plans, weekly reports,
  and insights without gating worship basics.

### Non-Goals

- Generic task management.
- Aggressive gamification, public leaderboards, confetti, or childish rewards.
- Worship-surface paywalls for Quran, athkar, prayer, or reasonable listening.

## UX Flow

1. User opens Tilawa to the main shell.
2. The first launch-tab surface shows Today Plan above the reciters catalog.
3. User sees three calm actions: Quran reading, Quran listening, and one
   secondary Islamic action.
4. User taps Continue and lands in the next best Quran action.
5. User marks tasks complete as they finish.
6. The card updates completed count, estimated time left, and completion copy.
7. Future supporter entry points may explain advanced personalization from
   Settings/Profile only, not from reader, prayer, or athkar flows.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Know What To Do Today (Priority: P1)

As a returning user, I want the home screen to show one short daily plan so I
can resume Quran engagement without deciding what to do.

**Why this priority**: This is the DAU and retention core. If this works alone,
Today Plan already creates a daily reason to open Tilawa.

**Independent Test**: Open Tilawa with existing last-read/listening data and
verify the Today Plan card shows actionable tasks, progress, and a Continue CTA.

**Acceptance Scenarios**:

1. **Given** a user has a saved last-read page, **When** they open the main
   shell, **Then** Today Plan includes a reading task that resumes from that
   page.
2. **Given** a user has listening history, **When** they open the main shell,
   **Then** Today Plan includes a listening task that references the most recent
   surah and reciter.
3. **Given** no history exists, **When** the plan is generated, **Then** it
   still shows a short default reading task, a short listening task, and morning
   adhkar.

---

### User Story 2 - Complete A Calm Daily Plan (Priority: P1)

As a user, I want to mark today's actions complete so I can see clear progress
and know when I am done.

**Why this priority**: Completion creates a feedback loop and supports daily
habit formation without heavy gamification.

**Independent Test**: Mark tasks complete and relaunch the app on the same day;
the same tasks remain complete.

**Acceptance Scenarios**:

1. **Given** a task is pending, **When** the user taps it, **Then** it becomes
   complete and the progress count increases.
2. **Given** all tasks are complete, **When** the card rerenders, **Then** the
   card shows completion copy and zero minutes remaining.

---

### User Story 3 - Adapt Difficulty Gently (Priority: P2)

As a user with recent engagement patterns, I want Tilawa to suggest a realistic
daily plan that does not overwhelm me.

**Why this priority**: Adaptive difficulty is the difference between a premium
companion and a static checklist.

**Independent Test**: Generate plans for listening-heavy, inactive, and highly
active fake histories and verify ordering/difficulty changes.

**Acceptance Scenarios**:

1. **Given** recent listening time is high, **When** the plan is generated,
   **Then** listening appears before reading.
2. **Given** the user has missed several days, **When** the plan is generated,
   **Then** the reading goal is reduced.
3. **Given** the user has a stable streak, **When** the plan is generated,
   **Then** the reading goal can increase modestly.

---

### User Story 4 - Understand Supporter Value (Priority: P3)

As a free user, I want to understand which future capabilities are advanced
personalization features without feeling that core Quran worship is blocked.

**Why this priority**: This supports monetization, but the current product
policy forbids worship paywalls and intrusive upsells.

**Independent Test**: Review Settings/Profile support copy and verify reader,
prayer, and athkar flows contain no upgrade prompts.

**Acceptance Scenarios**:

1. **Given** a free user opens Today Plan, **When** they complete today's tasks,
   **Then** no payment is required.
2. **Given** a user visits allowed support surfaces, **When** Today Plan value
   is described, **Then** copy frames support as voluntary and advanced
   personalization as roadmap value.

### Edge Cases

- Offline: use cached last-read, listening history, and local completion state;
  analytics may upload later.
- RTL/LTR: card layout must mirror naturally; Arabic strings must not overflow
  at text scale 1.4.
- No history: generate a small default Quran-first plan.
- Several missed days: reduce difficulty and avoid guilt copy.
- Highly active users: increase challenge only by one small step.
- Dark mode and true-black: use theme tokens only.
- Low-memory devices: plan generation must be synchronous-light and avoid large
  Quran/audio scans.
- Analytics failure: never block plan rendering or completion.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST show Today Plan in the home/dashboard area on app open.
- **FR-002**: System MUST include Quran reading as the primary plan category.
- **FR-003**: System MUST include Quran listening when listening data is
  available and a sensible default when it is not.
- **FR-004**: System MUST keep daily Islamic actions optional and secondary.
- **FR-005**: Users MUST be able to complete today's tasks without payment.
- **FR-006**: System MUST persist task completion locally by day.
- **FR-007**: System MUST estimate remaining time from incomplete tasks.
- **FR-008**: System MUST reduce difficulty after missed days.
- **FR-009**: System MUST prioritize listening for listening-heavy users.
- **FR-010**: System MUST emit Today Plan analytics events for view, start,
  task completion, plan completion, continue reading/listening, and support
  interest.
- **FR-011**: System MUST avoid intrusive monetization and must not show payment
  prompts inside Quran reader, prayer, or athkar flows.
- **FR-012**: System MUST support Arabic/English localization and screen-reader
  semantics.

### Key Entities

- **TodayPlan**: Daily plan for one date; contains tasks, progress, streak
  summary, estimated remaining minutes, and adaptive flag.
- **TodayPlanTask**: One action; kind, title intent, estimated minutes,
  completion state, and metadata such as page, surah, or reciter.
- **TodayPlanCompletion**: Local per-day set of completed task IDs.
- **TodayPlanInsight**: Future supporter/reporting aggregate for weekly
  reading and listening trends.

## Premium Strategy

Requested Premium capabilities map to the following product tiers, subject to
the existing Support Tilawa policy:

| Capability | Free MVP | Future Supporter/Advanced |
|---|---:|---:|
| See Today Plan | Yes | Yes |
| Complete today's tasks | Yes | Yes |
| Personalized generation from history | Basic local | Rich adaptive |
| Adaptive daily goals | Basic rules | Tuned goals |
| Smart catch-up plans | Basic reduction | Multi-day recovery |
| Weekly progress reports | No | Yes |
| Reading/listening insights | No | Yes |
| Advanced streak tracking | Simple local | Recovery days + reports |
| Goal customization | No | Yes |

User-facing copy should say "Support Tilawa" and "advanced personalization"
unless the monetization spec is amended to permit Premium terminology and perks.

## Flutter Architecture Design

```text
features/today_plan/
  domain/
    entities/TodayPlan, TodayPlanTask
    repositories/TodayPlanRepository
    usecases/GenerateTodayPlanUseCase
    usecases/SetTodayPlanTaskCompletedUseCase
  data/
    datasources/TodayPlanLocalDataSource
    repositories/TodayPlanRepositoryImpl
  presentation/
    bloc/TodayPlanBloc
    widgets/TodayPlanCard

GenerateTodayPlanUseCase
  ├── QuranReaderRepository.getLastReadPosition()
  ├── HistoryRepository.getRecentHistory()
  └── TodayPlanRepository.getCompletedTaskIds()
```

State management follows Bloc. Dependencies should be registered with
`get_it`/`injectable` once the feature graduates from the MVP slice. The MVP may
compose dependencies in the screen scope to avoid a wide code-generation pass.

## Analytics Events

| Event | Trigger | Required Parameters |
|---|---|---|
| `today_plan_viewed` | Card rendered with a plan | date_key, task_count, completed_count, minutes_remaining, streak_days, is_adaptive |
| `today_plan_started` | Continue tapped | task_id, task_kind |
| `today_plan_completed` | All tasks complete | date_key, task_count |
| `today_plan_task_completed` | Task toggled complete | task_id, task_kind, completed_count |
| `today_plan_continue_reading` | Continue opens reading | page if known |
| `today_plan_continue_listening` | Continue opens listening | surah_id, reciter_id if known |
| `today_plan_premium_clicked` | User taps allowed support/value entry | source |
| `today_plan_premium_converted` | Advanced/support purchase verified | product_id, source |

Analytics must use the shared AnalyticsService and must not block UI.

## Database Models

### Local MVP

```json
{
  "key": "today_plan.completed.YYYY-MM-DD",
  "value": ["read_quran", "listen_quran"]
}
```

### Future Sync

```json
{
  "user_id": "uid",
  "date_key": "YYYY-MM-DD",
  "tasks": [
    {
      "id": "read_quran",
      "kind": "reading",
      "target": {"pages": 2, "start_page": 303},
      "completed_at": "timestamp|null"
    }
  ],
  "generated_at": "timestamp",
  "algorithm_version": "today_plan_v1"
}
```

## API Requirements

No remote API is required for the 2-week MVP. Future sync/reporting requires:

- `GET /today-plan?date=YYYY-MM-DD`
- `POST /today-plan/tasks/{taskId}/complete`
- `GET /today-plan/weekly-report`
- server-side entitlement/supporter state if advanced personalization is gated
- conflict policy: newest task completion wins, plan generation remains
  deterministic by date and algorithm version

## MVP Roadmap

### Week 1

- Build local plan generator from last-read position and listening history.
- Add local completion persistence.
- Add home dashboard card with localized Arabic/English copy.
- Emit analytics events.
- Unit-test generator rules.

### Week 2

- Add direct Continue behavior for reading and listening.
- Add completion celebration copy, no confetti.
- Add widget tests for RTL/text scale/dark mode.
- Add Settings/Profile support copy for advanced personalization if approved.
- QA on Android device with `dart analyze` and targeted Flutter tests.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: At least 80% of test users can identify the next action within
  5 seconds of opening Tilawa.
- **SC-002**: Today Plan renders in under 100 ms after cached app data is ready.
- **SC-003**: Users can complete all MVP tasks without network access.
- **SC-004**: The feature increases 7-day return rate among exposed users by at
  least 5% compared with control.
- **SC-005**: At least 20% of users who view Today Plan tap Continue during a
  daily session.
- **SC-006**: No user-facing worship surface contains banned Premium/Upgrade
  language.

## Assumptions

- Last-read position and listening history are already available locally.
- Reading target defaults to two pages, reduced to one after missed days.
- Listening target defaults to ten minutes.
- Morning adhkar is the only secondary action in the MVP.
- Supporter/advanced personalization requires a separate monetization-policy
  decision before any worship-adjacent gating is shipped.

## Smallest 2-Week Version

Ship a localized Today Plan card at the top of the launch tab with three local
tasks: continue reading, continue listening, and morning adhkar. Generate it
from last-read position plus recent listening history, persist daily completion
locally, emit the analytics events, and keep all tasks free. This is small
enough to ship safely, but still feels premium because it is personalized,
adaptive in a simple way, visually integrated, and answers the user's next
action immediately.
