## 4.2.6 (Tilawa fork)

- Expose `totalBytesToDownload` and `bytesDownloaded` on `AppUpdateInfo`.
- Add `InAppUpdate.openAppStoreListing()` to open the Play Store listing
  without the immediate-update dialog that shows full APK size.
- Re-fetch fresh `AppUpdateInfo` from Play before each immediate, flexible,
  or complete flow; invalidate cached info after cancel/failure.
- Register flexible update listener before starting the download flow.
- Complete flexible updates only after verifying `InstallStatus.DOWNLOADED`.
- Fix `checkForUpdate` missing-activity path (no longer throws after `result.error`).
- Add Dart unit tests (`test/in_app_update_test.dart`) and Android Robolectric tests
  with JaCoCo gate at 90%+ line coverage.

## 4.2.5

See upstream [CHANGELOG.md](https://github.com/jonasbark/flutter_in_app_update/blob/master/CHANGELOG.md).
