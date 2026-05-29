# App review (Support Tilawa UX)

Provider-agnostic in-app review with **engagement-based** triggers — no launch popups.

## Layers

| Layer | Role |
|-------|------|
| `AppReviewPlatformDataSource` | Swap `in_app_review` ↔ `app_review` |
| `AppReviewRepository` | Domain API for request / store / availability |
| `AppReviewEngagementRepository` | Local counters + cooldown |
| `AppReviewTriggerManager` | When to ask (calm moments only) |
| `AppReviewFlowGuard` | Blocks prompts during worship flows |

## Default policy (`AppReviewTriggerPolicy`)

Tune in `di/app_review_policy_module.dart`:

- ≥ 2 distinct app days (sessions)
- ≥ 1 active day with signals
- ≥ 1 day since install
- At least one value moment (listening complete, prayer tab visits, favorite, bookmark)
- Max **2** lifetime prompts
- **90-day** cooldown between prompts
- **1.8s** delay before showing the OS dialog

Automatic prompts use **native in-app review only** (no store redirect).

## Sacred flows (never prompt)

- Quran reader routes
- Prayer Times tab
- Athkar tab + Athkar details

## Trigger hooks (MVP)

| Moment | Where |
|--------|--------|
| Session day counted | `MainScreen` shell activation |
| Listening completed | `AudioPlayerBloc` |
| Prayer tab visit | Leaving Prayer tab in `AppShellScreen` |
| Return to Reciters | Tab change in `AppShellScreen` |
| Favorite added | `AppReviewReciterEngagementReporter` (via `ReciterEngagementReporter`) |
| Bookmark created | `CreateBookmarkUseCase` |

## Manual / settings use

Inject `AppReviewCubit` and call [rateFromSettings] for explicit “Rate Tilawa”
settings actions. That opens the store listing directly — Play/App Store throttle
the native in-app dialog after dismissals and do not tell the app when nothing
is shown. Automatic engagement prompts still use native in-app review only.
