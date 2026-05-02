# Adhan Reliability Requirements Checklist

**Purpose**: Validate the quality and completeness of Adhan hardening requirements.
**Created**: 2026-05-02
**Feature**: [spec.md](../spec.md)

## Physical QA Blockers (Mandatory for GO)
- [ ] PQA001 **Direct Boot**: Reboot physical device, stay at lock screen, verify Adhan fires at scheduled time.
- [ ] PQA002 **OEM Survival**: Verify full 3-minute playback on OPPO/ColorOS with screen off and battery optimization enabled.
- [ ] PQA003 **App Lifecycle**: Swipe away app from recents and verify Adhan still fires.
- [ ] PQA004 **Notification Taps**: 
  - [ ] Tap from killed app (Cold start) -> Status Screen opens correctly.
  - [ ] Tap from background app -> Status Screen opens correctly.
  - [ ] Tap from foreground app -> Status Screen opens correctly.
- [ ] PQA005 **Duplicate Prevention**: Tap same notification multiple times; ensure only one status screen instance is active.
- [ ] PQA006 **Permission Revocation**: Revoke notification permission; verify native alarms are cleared immediately.
- [ ] PQA007 **Playback Completion**: Verify `adhan_service_completed` event in Logcat/Firebase after full playback.
- [ ] PQA008 **Abnormal Termination**: Force kill service during playback; verify `adhan_service_abnormal_termination` event is logged.

## Requirement Validation
- [x] CHK001 Are Direct Boot requirements defined?
- [x] CHK002 Is the minimal data schema for DPS explicitly defined?
- [x] CHK003 Are fallback requirements defined?
- [x] CHK004 Are requirements for multiple rapid reboots specified?
- [x] CHK005 Is "aggressive OEM" defined?
- [x] CHK006 Are observability metrics defined?
- [x] CHK007 Is "Force Stop" behavior clearly separated?
- [x] CHK010 Ghost Adhan prevention?
