# Code Review: Download Single Surah and Download All Surahs

I have conducted a strict code review of the single and batch download features, reviewing the data layer (`DownloadServiceImpl`, `DownloadsRepositoryImpl`, `DownloadQueueManager`, `BatchDownloadManager`), the domain layer use cases, and the presentation layer (`ReciterDownloadBloc`, `DownloadAllButton`).

Here are the findings regarding bugs, edge cases, and design issues. No refactoring has been suggested unless necessary to fix these issues.

## 1. [Bug / Edge Case] Duplicate Downloads in `DownloadsRepositoryImpl.startDownloadBatch`

**Issue:**
When a user taps "Download All", the `startDownloadBatch` method checks if items are currently queued or active:

```dart
if (queueManager.isQueued(downloadId) || queueManager.isActive(downloadId)) {
  continue;
}
```

However, it **does not check if the items are already downloaded** (unlike the UI which might filter them out, though `DownloadAllButton` passes all `surahs` directly).
As a result, if a user downloads Surah 1 manually and later taps "Download All", Surah 1 will be marked as `pending` in the local DB again and enqueued.

- If `flutter_downloader` still has the completed task, it might instantaneously emit a `completed` event (causing UI flicker).
- If the task was cleared but the file exists, it will re-download the file, wasting bandwidth and overwriting the existing file.

**Fix Recommendation:**
Filter out already downloaded items before enqueueing by checking `isSurahDownloaded` or comparing against completed items in the local data source.

---

## 2. [Bug / Edge Case] Unhandled Abandoned Tasks in `DownloadServiceImpl.download`

**Issue:**
When checking for existing tasks, the service handles `complete`, `running`, and `enqueued` statuses:

```dart
if (task.status == DownloadTaskStatus.complete) { ... } 
else if (task.status == DownloadTaskStatus.running || task.status == DownloadTaskStatus.enqueued) { ... }
```

If an existing task is in a `failed` or `canceled` state, the `if/else` block falls through, and the service invokes `_flutterDownloader.enqueue` with the exact same URL and path. `flutter_downloader` does not overwrite failed tasks on enqueue; it generates a new `taskId`. Over time, this inflates the SQLite database with abandoned failed tasks.

**Fix Recommendation:**
Explicitly handle `failed` or `canceled` task statuses by removing them via `_removeTaskWithRetries(task.taskId)` before falling through to `enqueue`, ensuring clean state.

---

## 3. [Design Issue] Blocking Queue Processing Loop in `DownloadQueueManager`

**Issue:**
In `_processQueue()`, after starting a download, the manager aggressively polls for the status to verify it actually started:

```dart
for (var i = 0; i < 10; i++) {
  try {
    actualStatus = await _downloadService.getStatus(queuedDownload.url);
    if (actualStatus != null) break;
    if (i < 9) await Future.delayed(const Duration(milliseconds: 500));
    ...
```

This loop runs sequentially inside a `while` loop over the queue. If the underlying platform plugin is slow to register the task or fails silently (returning `null`), `_processQueue` blocks for **5 seconds** per item. For a batch download of 114 surahs, this could stall the entire queue processing loop for nearly 10 minutes, preventing other downloads from starting.

**Fix Recommendation:**
Do not block the main queue processing loop with a 500ms delay per retry. Instead, fire and forget the enqueue request, and rely exclusively on the `globalProgressStream` to mark downloads as active when the platform layer reports them as `enqueued` or `running`.

---

## 4. [Design / Edge Case] UI State vs Action Discrepancy in `ReciterDownloadBloc`

**Issue:**
In `ReciterDownloadBloc`, `isDownloadingAll` only becomes `true` if `_isBatchDownload` is `true`.

```dart
final bool hasActiveDownloads = _downloadingSurahs.isNotEmpty && _isBatchDownload;
```

If a user manually taps "Download" on 5 individual surahs, `_downloadingSurahs.isNotEmpty` will be true, but the "Download All" button will not switch to its active (pausable) state because it wasn't triggered as a batch.
However, if the user taps "Pause All" (via an external event) or if `CancelDownloadsForReciterUseCase` is invoked, it cancels **all** downloads for that reciter—including the individually started ones.

**Fix Recommendation:**
Determine if the "Download All" button represents "the current state of the batch action" or "the aggregate state of the reciter's downloads". If the latter, `_isBatchDownload` should be removed from the condition, allowing the button to reflect active individual downloads natively.

---

## 5. [Design Issue] Premature Batch Cleanup in `BatchDownloadManager`

**Issue:**
When a batch finishes, it is immediately removed from the active batches map:

```dart
if (batch.isFinished) {
  if (batch.isFullyCompleted) {
    batchesToRemove.add(batch.id);
  }
}
```

The instant the final progress payload arrives, the batch is wiped from memory. If the `NotificationService` or any UI component (e.g., a "Downloads Manager" screen) queries `BatchDownloadManager` for the final status or attempts a final UI update milliseconds later, it will receive `null`.

**Fix Recommendation:**
Keep completed batches in the map for a short TTL (Time-To-Live) or explicitly wait for UI/notification layers to dismiss them before wiping them from trackable state.

---

## 6. [Bug / Edge Case] Unhandled `MissingPluginException` in `DownloadQueueManager.enqueueBatch`

**Issue:**
In `DownloadsRepositoryImpl.startDownloadBatch`, the call to `queueManager.enqueueBatch` is wrapped in a `try-catch` that swallows `MissingPluginException`. However, inside `DownloadQueueManager.enqueueBatch`, it iterates over items and calls `_processQueue()`. Inside `_processQueue()`, it calls `_downloadService.download(...)`.
If this `download(...)` call throws a `MissingPluginException` (which happens frequently in test environments or on unsupported platforms), the catch block inside `_processQueue()` catches it as a generic `Exception`:

```dart
catch (e) {
  // If start fails, don't mark as active
  _activeDownloads.remove(queuedDownload.id);
  ...
  // Ensure UI is not stuck in pending
  await _downloadService.cancel(queuedDownload.id);
}
```

If `download` fails due to `MissingPluginException`, the subsequent `cancel` call will *also* throw a `MissingPluginException`, which is uncaught and crashes the `_processQueue` loop entirely, leaving remaining items stuck in the `pending` state forever without attempting to process them.

**Fix Recommendation:**
Wrap the `cancel` call inside the `catch` block in `_processQueue` with another `try-catch` to safely ignore platform exception fallouts when handling start failures.

---

## 7. [Design Issue] Polling vs Event-Driven Syncing in `DownloadQueueManager`

**Issue:**
`DownloadQueueManager` uses a `Timer.periodic` every 5 seconds to call `_syncActiveDownloads()`, which queries `_downloadService.getActiveDownloadIds()` to detect stuck or stale downloads.

```dart
_syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
  ...
}
```

While a watchdog is a good idea to prevent stuck states, polling the native platform (via `FlutterDownloader.loadTasks()`) every 5 seconds is heavy and drains battery. `FlutterDownloader` requires an SQLite query on the native side over a platform channel for every `loadTasks()` call.

**Fix Recommendation:**
Increase the polling interval to 30 or 60 seconds. The library already provides the `globalProgressStream` which pushes updates. The watchdog should only act as a true fallback for missed events, not as a primary state synchronization mechanism running every 5 seconds.

---

## 8. [Design Issue] Potential O(N^2) Complexity in `BatchDownloadManager._handleProgressUpdate`

**Issue:**
`BatchDownloadManager` listens to global progress updates. For every single progress update (which fires frequently during active downloads), it iterates over all `_activeBatches.values` and checks if the batch contains the `progress.id`.

```dart
for (final _BatchInfo batch in _activeBatches.values) {
  if (batch.itemIds.contains(progress.id)) { ... }
}
```

If a user enqueues 114 surahs, and 2 are downloading concurrently firing progress updates every 3%, this iteration happens hundreds of times. While `Set.contains` is O(1), iterating all batches is O(B) where B is the number of active batches. Not severe right now, but a reverse-mapping dictionary (`Map<String, String> _downloadIdToBatchId`) would make this O(1).

**Fix Recommendation:**
Maintain a secondary map linking `downloadId -> batchId` to avoid iterating all active batches on every granular progress update.
