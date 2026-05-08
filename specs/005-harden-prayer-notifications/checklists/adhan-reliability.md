# Adhan Reliability Requirements Checklist

**Purpose**: Validate the quality and completeness of Adhan hardening requirements.
**Created**: 2026-05-02
**Feature**: [spec.md](../spec.md)

## Physical QA Blockers (Mandatory for GO)
- [ ] PQA001 **Direct Boot**: Reboot physical device, stay at lock screen, verify Adhan fires at scheduled time. (PARTIAL: post-boot ingress improved; full re-arm/watchdog evidence still sparse)
- [ ] PQA002 **OEM Survival**: Verify full 3-minute playback on OPPO/ColorOS with screen off and battery optimization enabled.
- [ ] PQA003 **App Lifecycle**: Swipe away app from recents and verify Adhan still fires.
- [ ] PQA004 **Notification Taps**: (PARTIAL overall; sub-scenarios below passed)
  - [x] Tap from killed app (Cold start) -> Status Screen opens correctly.
  - [x] Tap from background app -> Status Screen opens correctly.
  - [x] Tap from foreground app -> Status Screen opens correctly.
- [ ] PQA005 **Duplicate Prevention**: Tap same notification multiple times; ensure only one status screen instance is active. (PARTIAL: duplicate tap guard PASS; explicit same-target AppRouter skip log not proven via current adb simulation path)
- [x] PQA006 **Permission Revocation**: Revoke notification permission; verify notification-denied behavior and routing expectations via manual toggle + runtime capture.
- [ ] PQA007 **Playback Completion**: Verify `adhan_service_completed` event in Logcat/Firebase after full playback.
- [ ] PQA008 **Abnormal Termination**: Force kill service during playback; verify `adhan_service_abnormal_termination` event is logged.

## Current Release Status (2026-05-08)
- Architecture audit verdict: GO
- Production code/test verdict: GO
- Android release QA verdict: CONDITIONAL GO
- Overall Android release readiness: CONDITIONAL GO
- Do not claim full production GO until remaining PARTIAL items are closed.
- Note: No architecture refactor should start before release.

### Post-Release Technical Debt
These items are not release blockers:
1. Extract notification routing state from `AppRouter` into a dedicated service.
2. Add `VibrationService` abstraction for `QiblaBloc` instead of direct plugin invocation.
3. Replace hardcoded `PrayerNotificationStatusRoute` same-target logic with generalized route matching.
4. Review `AppSystemChromeStyle` target enum if more special chrome routes appear.

## Conditions to Upgrade QA Verdict to GO
1. Capture explicit same-target AppRouter skip evidence from real tray taps (`Notification navigation skipped` or `Duplicate notification navigation ignored`).
2. Capture full reboot re-arm/watchdog evidence with clear post-boot re-arm observability.

## Requirement Validation
- [x] CHK001 Are Direct Boot requirements defined?
- [x] CHK002 Is the minimal data schema for DPS explicitly defined?
- [x] CHK003 Are fallback requirements defined?
- [x] CHK004 Are requirements for multiple rapid reboots specified?
- [x] CHK005 Is "aggressive OEM" defined?
- [x] CHK006 Are observability metrics defined?
- [x] CHK007 Is "Force Stop" behavior clearly separated?
- [x] CHK010 Ghost Adhan prevention?
