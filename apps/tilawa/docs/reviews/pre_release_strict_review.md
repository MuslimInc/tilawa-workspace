# Pre-Release Strict Code Review: Downloads Feature

This review focuses on bugs, edge cases, and design issues that could impact the **Google Play** production release.

## 1. [Critical Bug] Android 13+ Notification Permissions

The `NotificationPermissionService` only requests the `POST_NOTIFICATIONS` permission on the "first launch" (based on personal app storage).

- **Issue**: Users who update their existing app to this new version will **never be prompted** for notification permissions, as it's not their first launch.
- **Impact**: On Android 13+, download progress notifications will not appear for these users, leading to a "broken" experience.
- **Location**: `NotificationPermissionService.requestPermissionOnFirstLaunch` ([line 105](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/core/services/notification_permission_service.dart#L105))

## 2. [Reliability] Batch Progress Persistence

The `BatchDownloadManager` is a non-persisted singleton.

- **Issue**: If the app is killed while a batch download (e.g., a "Download All" of 114 Surahs) is at 50%, the batch tracking information is lost.
- **Impact**: Upon restart, the specific "Batch Progress" notification (e.g., "Downloading 57/114") will disappear. Individual files will still download (managed by the platform), but the unified progress view will be broken.
- **Location**: `BatchDownloadManager._activeBatches` ([line 20](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/features/downloads/data/services/batch_download_manager.dart#L20))

## 3. [UX / Design] Lack of Pause/Resume

The current system implementation do not support true pause/resume.

- **Issue**: `cancelDownload` deletes the file content on disk.
- **Impact**: Users on limited mobile data who need to stop a large download temporarily cannot do so without losing all progress. They must cancel (deleting the file) and restart from zero later.
- **Location**: `DownloadsRepositoryImpl.cancelDownload` ([line 510](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/features/downloads/data/repositories/downloads_repository_impl.dart#L510))

## 4. [Integrity] Loose File Size Tolerance

The `DownloadRecoveryService` uses a 5% tolerance when verifying completed file sizes.

- **Issue**: For a 50MB audio file, this allows a mismatch of up to 2.5MB.
- **Impact**: A slightly corrupted or truncated file (missing last few seconds of a Surah) might be marked as "Completed" incorrectly.
- **Recommendation**: Reduce to 1% or smaller for audio content.
- **Location**: `DownloadRecoveryService._verifyCompletedDownload` ([line 252](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/features/downloads/data/services/download_recovery_service.dart#L252))

## 5. [Edge Case] Race Condition in `DownloadButtonBloc`

If the `_downloadSurah` UseCase throws an uncaught exception (e.g., `NetworkException` from the repository):

- **Issue**: The bloc will be stuck in the `pending` state indefinitely, as the error handling only catches `Left(Failure)` and not thrown exceptions.
- **Location**: `DownloadButtonBloc._onStartDownload` ([line 146](file:///Users/mohammadkamel/flutter_projects/tilawa_workspace/apps/tilawa/lib/features/downloads/presentation/bloc/download_button/download_button_bloc.dart#L146))
