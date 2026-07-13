# Al-Khatmah release UX: flow-to-implementation map

**Status:** canonical release UX mapping  
**Source of truth:** `amendment-production-readiness.md`

| UX step | Screen/state | Route | BLoC / use case | Storage | Status |
|---|---|---|---|---|---|
| Home entry | `SmartKhatmaHomeEntryCard` | `SmartKhatmaHubRoute` (`/smart-khatma`) | `KhatmaPlanBloc`, `GetActiveKhatmaPlanUseCase` | v2 active plan | Implemented in worktree; duplicate More entry and hub FAB removed |
| No plan | `_KhatmaHubEmptyBody`, `KhatmaPlanLoaded(plan: null)` | Hub | Bloc load | none | Implemented: one Create CTA |
| Choose boundary mode | Create Plan | Hub | local creation draft + preview event | none | Implemented |
| Select Surah start/end | Create Plan, Surah mode | Hub | Ayah selectors + `KhatmaPlanBoundaries` | none | Implemented |
| Select page start/end | Create Plan, Page mode | Hub | bounded ordered page validation | none | Implemented |
| Choose duration / target date | `_KhatmaHubEmptyBody` | Hub | `KhatmaPlanPreviewRequested` | none | Implemented: presets + target date |
| Edit plan | Active hub sheet | Hub | `KhatmaPlanEditPreviewRequested` / `UpdateKhatmaPlanUseCase` | v2 plan | Implemented |
| Delete plan | confirmed reset row | Hub | `ResetKhatmaPlanUseCase` | clears v2 | Implemented |
| Preview | `_KhatmaCreationReviewBody`, `KhatmaPlanCreationReview` | Hub | `CreateKhatmaPlanUseCase.preview` | none | Implemented for selected boundaries |
| Confirm/cancel | Creation review | Hub | `KhatmaPlanCreationConfirmed`; `CreateKhatmaPlanUseCase.confirm` | `smart_khatma.active_plan.v2` | Implemented |
| Active/no progress | `_KhatmaHubActiveBody`, `KhatmaPlanLoaded` | Hub | `GetKhatmaTodayTargetUseCase` | frozen assignment in v2 plan | Implemented with required facts |
| Active/partial | Same | Hub | same | same | Mostly implemented; Start/Resume title changes correctly |
| Start Wird | Active Hub | `KhatmaReaderRoute(initialPage)` (`/khatma-reader/:initialPage`) | `KhatmaPlan.resumePage` | global reader history remains separate | Implemented |
| Resume Wird | Active Hub | same | first unconfirmed page | same | Implemented |
| Quran reading | Existing `QuranReaderHostScreen` / `QuranImageReaderScreen` | Khatma reader route | reader navigation only | global last-read only | Implemented: generic navigation has no Khatma mutation dependency |
| Save Progress | Khatmah-only reader action then confirmation sheet | reader + modal over Hub | `KhatmaProgressConfirmed`; `UpdateKhatmaProgressUseCase` | v2 confirmed boundary | Implemented |
| Today completed | `_KhatmaHubActiveBody` calm card | Hub | derived `isTodayCompleted` | frozen assignment unchanged | Implemented in worktree |
| Full completed | `_KhatmaHubCompletedBody` | Hub | derived `isCompleted` | confirmed boundary equals target | Implemented with both actions |
| Extension | Recovery panel/dialog | Hub | `ExtendKhatmaPlanUseCase` | duration/adjustment | Implemented in worktree with before/after review |
| Catch-up | none | none | use case removed | none | Correctly hidden |
| Malformed/error | `_KhatmaHubErrorBody`, `KhatmaPlanFailure` | Hub | repository/load use case | malformed raw v2 left untouched | Implemented with Retry and confirmed Reset |
| Today Plan | `TodayPlanCard` | generic route | separate Today Plan Bloc | separate store | Default-off; must remain off until reconciled |
| Android widget | native widget | widget deep link | Flutter summary adapter only | presentation snapshot | Default-off and deferred |

## Remaining validation gaps

1. Production App Bundle build on release lane.
2. Physical-device smoke for reader Save Progress return path.
3. Optional: automated route/integration test for `KhatmaReaderRoute`.

These are release gaps. They do not justify range ledgers, event histories,
another reader, another progress store, or Android work.
