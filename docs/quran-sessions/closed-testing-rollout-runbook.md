# Learn Quran — Closed-Testing Rollout Runbook (official)

**Status:** active gate — step 1 in progress (Agora staging QA)
**Last updated:** 2026-07-04

This is the authoritative sequence for rolling the Learn Quran
(quran_sessions) feature out to closed testers. Do not reorder the steps: the
platform-config flip (step 2) breaks in-app Agora video joins for the staging
QA builds, so it must not happen while step 1 is running.

## Rollout steps

1. **Finish Agora staging QA** (MeMuslim video QA, `staging.video.local.json`
   builds). Until this is done, `quran_session_platform_config/global` keeps
   the `video-qa` values (`enabledCallProviders: ["mock","agora"]`,
   `sessionMode: "videoOnly"`).

2. **Flip the platform config to closed testing:**

   ```sh
   cd functions
   npm run seed:platform-config -- --mode closed-testing          # dry run
   npm run seed:platform-config:apply -- --mode closed-testing    # write
   ```

3. **Verify the live doc** (read-only) shows exactly:
   - `enabledCallProviders: ["external", "mock"]`
   - `sessionMode: "freeBeta"`

   Verification snippet and full field reference:
   [admin-config-seed.md → Closed-testing gate](admin-config-seed.md#closed-testing-gate--required-platform-config).

4. **Cut the internal-track build:** GitHub → Actions →
   *Android Release (Google Play)* → `track=internal`,
   `learn_quran_student=true`, next `build_name`/`build_number`.
   Full walkthrough: [docs/ci_release.md](../ci_release.md).

5. **Run real-device QA on the internal track before widening** to
   alpha/closed testing:
   - Student funnel end-to-end with a real auth account: hub → teacher list →
     profile → book (free, requires tutor approval) → my sessions → cancel →
     join via external meeting link.
   - Teacher side with an approved teacher account: dashboard load (summary
     doc and fallback paths), respond to booking request, weekly schedule +
     overrides, block/delete slot + undo, cancelled sessions disappear after
     refresh.
   - Airplane-mode / slow-network pass on dashboard and booking screens.
   - Arabic (RTL) pass and booking-lifecycle push notifications on device.

## Promotion policy (non-negotiable)

**Never promote an internal/alpha/beta AAB to production in the Play
Console.** Feature flags are compiled into the artifact
(`TILAWA_DISTRIBUTION=play_<track>` plus the `learn_quran_student` define);
promotion would ship closed-testing behaviour to all users. Production is
always a fresh workflow run with `track=production`, which compiles
`play_production` defaults (all testing flags off). The workflow enforces the
build side (it rejects `learn_quran_student=true` on the production track and
stamps a "do not promote" warning on every testing-track run), but Play
Console promotion is a manual action only this policy prevents.

## Rollback

- Feature exposure: closed-testing visibility is compile-time; pulling the
  testing-track release (or halting the rollout in Play Console) removes it.
  Production builds never contained the student hub.
- Platform config: re-seed the previous behaviour with
  `npm run seed:platform-config:apply -- --mode video-qa`.
