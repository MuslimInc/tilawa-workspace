# Morning Handoff — Quran Sessions Stable Production (Phases 7–11)

**Date:** 2026-06-24  
**Overnight engineering verdict:** **Ready for your full manual E2E** on staging / closed track  
**Not ready for:** unrestricted Play production (App Check ops flip, legal privacy, manual sign-off table)

---

## What was completed overnight

### Phase 7 — Ops-ready App Check + CF deploy

| Deliverable | Status |
|-------------|--------|
| `scripts/deploy_quran_session_callables.sh` — batch deploy 12 stable callables + `sessionReminders` | ✅ |
| `sessionReminders` exported from `functions/src/index.ts` | ✅ |
| Wiring test guards `sessionReminders` export | ✅ |
| `security-safety-checklist.md` — deploy script documented | ✅ |
| Client App Check in release (`app_startup_tasks.dart`, skip in debug) | ✅ verified unchanged |
| Live CF deploy to `quran-playera-app` | ⬜ **Not run** — Firebase CLI authenticated; ops should run script when ready |

**Deploy command (ops):**

```sh
# Default off — safe staging deploy
./scripts/deploy_quran_session_callables.sh quran-playera-app

# After staging smoke — App Check enforcement flip
QURAN_SESSIONS_ENFORCE_APP_CHECK=true ./scripts/deploy_quran_session_callables.sh quran-playera-app
```

### Phase 8 — UI/UX polish

| Area | Change |
|------|--------|
| **MeMuslim branding** | User-visible sessions copy updated EN + AR (external join sheet, teacher apply, application status) — `Tilawa` → `MeMuslim` |
| **Session detail** | Pull-to-refresh; auto-reload on app resume when awaiting reschedule counterparty |
| **Teacher discovery home** | Load failure shows **Retry** button (no dead-end) |
| **Experimental badges** | None in sessions paths (already clean; home hero WIP untouched except compile fix) |
| **Home entry** | Footer + discover carousel unchanged (polish-only scope respected) |

### Phase 9 — Product gaps

| Item | Status |
|------|--------|
| Requester refresh after counterparty responds | ✅ resume + pull-to-refresh on session detail |
| `sessionReminders` CF export | ✅ |
| Admin reports/disputes | ✅ read-only triage unchanged; no regressions found |

### Phase 10 — Test hardening

| Suite | Result |
|-------|--------|
| `packages/quran_sessions` `flutter test` | **702/702** pass |
| `functions` unit (`npm test`) | **142/142** pass |
| `functions` rules (`npm run test:rules`, JDK 21) | **33/33** pass |
| `functions` integration (JDK 21) | **36/38** pass — 2 pre-existing agora/webrtc provider-hint failures |
| `./scripts/quran_sessions_preflight.sh` | ✅ pass |
| **New:** `reschedule_bloc_test.dart` | 3/3 pass |

**Surgical fix (blocking preflight):** missing `)` in `home_dashboard_hero_sliver.dart` — compile-only, no behavior change.

### Phase 11 — Documentation

- This file (`MORNING-HANDOFF.md`)
- `final-report.md` — Phases 7–11 appended
- `security-safety-checklist.md` — deploy script reference

---

## Your manual E2E checklist (step-by-step)

Use a **release/staging build** (`kDebugMode` skips App Check — debug builds are not valid for CF enforcement smoke).

### Build flags (staging)

```sh
cd apps/tilawa
flutter run --release \
  --dart-define=TILAWA_DISTRIBUTION=staging \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=external,mock
```

### Build flags (staging + Agora RTC)

Requires CF secrets + Firestore `enabledCallProviders` (see **Agora staging setup** below). VS Code: **Tilawa (Staging Agora)** launch config.

```sh
cd apps/tilawa
flutter run --release \
  --dart-define=TILAWA_DISTRIBUTION=staging \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_QURAN_SESSIONS_BOOKING_ENABLED=true \
  --dart-define=TILAWA_LAUNCH_ENABLED_CALL_PROVIDERS=external,mock,agora \
  --dart-define=TILAWA_LAUNCH_AGORA_APP_ID=aacd48a930944ecea29bec112f229eb9
```

### Agora staging setup (ops)

**Cloud Functions secrets** (`quran-playera-app`):

```sh
# Interactive — paste App ID and Primary Certificate when prompted (never commit cert)
firebase functions:secrets:set AGORA_APP_ID AGORA_APP_CERTIFICATE --project quran-playera-app

# Redeploy token callable after secrets are set
cd functions
firebase deploy --only functions:issueSessionRtcToken --project quran-playera-app
```

**Local emulator / scripts only** (gitignored):

```sh
cp functions/.env.agora.local.example functions/.env.agora.local
# Edit .env.agora.local — certificate stays local; do not commit
```

**Firestore** (`quran-playera-app` staging only — merge, do not wipe global config):

```json
// quran_session_platform_config/global
{
  "enabledCallProviders": ["external", "mock", "agora"]
}
```

Set via Firebase Console or Admin SDK merge. Required for server-side Agora booking validation.

**Temp Agora Console token:** manual Agora Console test only (~24h TTL). The app mints tokens at join time via `issueSessionRtcToken` — do not embed console tokens in the app or repo.

**Security:** Primary Certificate was shared in chat for setup — rotate in Agora Console after testing if chat is logged.

### Student (B1–B5)

1. [ ] Sign in; complete profile (gender, DOB, location)
2. [ ] Home → **Learn Quran** (footer or discover carousel) → teacher list loads
3. [ ] Toggle airplane mode on home → **Retry** restores list
4. [ ] Book free **external** session → My Sessions shows booking
5. [ ] Session detail → locked-at-booking footnote visible
6. [ ] Join → **Join outside MeMuslim?** sheet → external browser opens
7. [ ] Request reschedule → counterparty accepts on other account → **pull down or background/resume app** → requester sees updated time (not stuck on “awaiting”)
8. [ ] Cancel inside policy window
9. [ ] Report (20+ chars) + open dispute
10. [ ] Kill switch off → sessions routes redirect home

### Teacher (T2–T8)

1. [ ] Apply → admin approve → dashboard without app restart
2. [ ] Set availability + external meeting URL card
3. [ ] See upcoming session; join external link
4. [ ] Request reschedule; **counterparty** sees Accept/Reject (not requester)
5. [ ] Suspended teacher → dashboard blocked

### Admin

1. [ ] Reports queue — filter/search readable
2. [ ] Disputes queue — open detail; act via session detail CF
3. [ ] Confirm reschedule by request ID (ops escalation path)

### Device / security

1. [ ] Device A books → Device B login → A cannot mutate (epoch)
2. [ ] FCM on active device only

### Optional — Agora (two physical devices, not emulators)

See `final-report.md` RTC / Phase 3 staging checklist. **No-Go for Play wide** until device E2E + minified APK smoke.

---

## Feature flags / rollback

| Flag | Location | Effect |
|------|----------|--------|
| `quranSessionsEnabled` | `AppLaunchConfig` | Full kill — router redirect + home hide |
| `quranSessionsBookingEnabled` | `AppLaunchConfig` | Blocks booking CTAs |
| `QURAN_SESSIONS_ENFORCE_APP_CHECK` | CF runtime env | Callable App Check enforcement (default **off**) |
| `DEPLOY_SESSION_REMINDERS=false` | deploy script env | Skip `sessionReminders` on deploy |

**Rollback:** `quranSessionsEnabled=false` in app config; unset App Check env + redeploy CFs (~15 min).

---

## Deploy status

| Artifact | Status |
|----------|--------|
| `firestore.rules` + indexes (Phase 5) | ✅ deployed `quran-playera-app` (prior pass) |
| `confirmSessionReschedule` | ✅ deployed (prior pass) |
| 12 stable callables + `sessionReminders` (Phase 4 wiring) | ⬜ **Run** `./scripts/deploy_quran_session_callables.sh quran-playera-app` |
| `issueSessionRtcToken` + Agora secrets (`AGORA_APP_ID`, `AGORA_APP_CERTIFICATE`) | ✅ deployed `quran-playera-app` (2026-06-24) |
| App Check enforcement flip | ⬜ ops — after staging smoke |

---

## Known limitations (unchanged)

1. **Agora** — device-only native join; placeholder call shell; ProGuard release smoke unsigned
2. **App Check** — staged in code; CF enforcement off until ops sets env + redeploy
3. **Legal** — privacy policy not verified for external links + voice/video
4. **WebRTC** — stub throws; signaling postponed
5. **Paid/wallet/group** — out of stable scope
6. **Manual sign-off table** — [docs/qa/quran_sessions_free_beta_signoff.md](../../docs/qa/quran_sessions_free_beta_signoff.md) still ⬜
7. **Integration tests** — 2 agora/webrtc provider-hint cases fail in emulator suite (pre-existing; not blocking manual E2E)

---

## Go / No-Go for your testing session

| Track | Verdict |
|-------|---------|
| **Your manual E2E today** | **Go** — engineering complete for stable scope; run checklist above |
| **Deploy remaining CFs** | **Go** — run deploy script once before session-heavy testing |
| **App Check enforcement on staging** | **Conditional** — after CF deploy + release build smoke |
| **Play production (wide)** | **No-Go** — manual sign-off + App Check + legal |

---

## Files changed (overnight)

```
scripts/deploy_quran_session_callables.sh
functions/src/index.ts
functions/test/quranSessions/sessionCallableWiring.test.ts
packages/quran_sessions/lib/l10n/intl_en.arb
packages/quran_sessions/lib/l10n/intl_ar.arb
packages/quran_sessions/lib/l10n/quran_sessions_localizations*.dart
packages/quran_sessions/lib/src/presentation/screens/session_detail_screen.dart
packages/quran_sessions/lib/src/presentation/screens/quran_sessions_home_screen.dart
packages/quran_sessions/lib/src/presentation/widgets/external_meeting_join_sheet.dart
packages/quran_sessions/test/presentation/blocs/reschedule_bloc_test.dart
packages/quran_sessions/test/presentation/screens/session_detail_screen_test.dart
packages/quran_sessions/test/presentation/widgets/external_meeting_join_sheet_test.dart
apps/tilawa/lib/features/home/presentation/widgets/home_dashboard_hero_sliver.dart  (compile fix)
specs/038-quran-session-stable-production-release/security-safety-checklist.md
specs/038-quran-session-stable-production-release/final-report.md
specs/038-quran-session-stable-production-release/MORNING-HANDOFF.md
```
