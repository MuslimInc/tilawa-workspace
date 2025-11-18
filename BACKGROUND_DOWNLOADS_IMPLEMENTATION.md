# Background Downloads Implementation Guide

## Current Situation
- Downloads use Dart isolates which are **killed when app closes/terminates**
- Downloads fail when app is closed
- No true background download capability

## Recommended Solution: `background_downloader` Package

### Why `background_downloader`?
- ✅ **True background downloads** - continues even when app is terminated
- ✅ **Cross-platform** - Works on Android, iOS, macOS, Windows, Linux, Web
- ✅ **Resumable downloads** - Can pause/resume downloads
- ✅ **Progress tracking** - Real-time progress updates
- ✅ **Well maintained** - Active development and good documentation
- ✅ **Battery efficient** - Uses platform-native download managers

### Alternative: Native Platform Solutions
- **Android**: Use `DownloadManager` (built-in Android service)
- **iOS**: Use `URLSession` with background configuration
- **Pros**: More control, platform-optimized
- **Cons**: Requires platform-specific code, more complex

## Implementation Plan

### Option 1: Use `background_downloader` (Recommended)

#### Step 1: Add Dependency
```yaml
dependencies:
  background_downloader: ^9.0.0
```

#### Step 2: Android Configuration
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<!-- For Android 10+ -->
<uses-permission android:name="android.permission.ACCESS_MEDIA_LOCATION"/>
```

#### Step 3: iOS Configuration
1. Enable Background Modes in Xcode:
   - Select Runner target → Signing & Capabilities
   - Add "Background Modes"
   - Enable "Background fetch" and "Background processing"

2. Add to `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
</array>
```

#### Step 4: Update DownloadService
Replace current isolate-based implementation with `background_downloader`:

```dart
import 'package:background_downloader/background_downloader.dart';

class DownloadService {
  static Future<void> startDownload({
    required String id,
    required String url,
    required String filePath,
    required String title,
    required String reciterName,
  }) async {
    final task = DownloadTask(
      url: url,
      filename: path.basename(filePath),
      directory: path.dirname(filePath),
      updates: Updates.statusAndProgress,
      retries: 3,
      requiresWiFi: false,
      allowPause: true,
    );

    // Enqueue the download task
    await FileDownloader().enqueue(task);
  }

  // Listen to download updates
  static Stream<DownloadProgress> progressStream(String id) {
    return FileDownloader().updates
        .where((update) => update.taskId == id)
        .map((update) {
          if (update is TaskStatusUpdate) {
            return DownloadProgress(
              id: id,
              status: _mapStatus(update.status),
              progress: 0.0,
              downloadedSize: 0,
              fileSize: 0,
            );
          } else if (update is TaskProgressUpdate) {
            return DownloadProgress(
              id: id,
              status: DownloadStatus.downloading,
              progress: update.progress,
              downloadedSize: update.progress * update.expectedFileSize,
              fileSize: update.expectedFileSize,
            );
          }
          return null;
        })
        .where((progress) => progress != null)
        .cast<DownloadProgress>();
  }
}
```

### Option 2: Hybrid Approach (Keep Current + Add Background)

Keep current implementation for in-app downloads, add background service for long downloads:

1. **Small/Quick downloads**: Use current isolate-based approach
2. **Large/Long downloads**: Use `background_downloader` for background capability

### Option 3: Native Platform Implementation

#### Android: DownloadManager
```kotlin
// android/app/src/main/kotlin/.../DownloadManagerService.kt
class DownloadManagerService {
    fun downloadFile(url: String, fileName: String) {
        val request = DownloadManager.Request(Uri.parse(url))
            .setTitle(fileName)
            .setDescription("Downloading $fileName")
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setDestinationInExternalFilesDir(context, Environment.DIRECTORY_DOWNLOADS, fileName)
        
        val downloadManager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        downloadManager.enqueue(request)
    }
}
```

#### iOS: URLSession Background Configuration
```swift
// ios/Runner/BackgroundDownloadManager.swift
class BackgroundDownloadManager: NSObject, URLSessionDownloadDelegate {
    lazy var backgroundSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.muzakri.downloads")
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    func download(url: URL) {
        let task = backgroundSession.downloadTask(with: url)
        task.resume()
    }
}
```

## Migration Strategy

### Phase 1: Add Background Support (Non-Breaking)
1. Add `background_downloader` package
2. Create new `BackgroundDownloadService` wrapper
3. Keep existing `DownloadService` for backward compatibility
4. Add feature flag to switch between implementations

### Phase 2: Gradual Migration
1. Use background service for new downloads
2. Migrate existing download logic
3. Update UI to handle both implementations

### Phase 3: Full Migration
1. Remove isolate-based implementation
2. Use only background service
3. Clean up old code

## Considerations

### Battery Optimization
- **Android**: Users may need to disable battery optimization
- **iOS**: System manages background tasks automatically
- **Best Practice**: Show user-friendly message if downloads fail due to battery optimization

### Permissions
- **Android 10+**: May need `ACCESS_MEDIA_LOCATION` for media files
- **iOS**: Background modes must be declared in Info.plist
- **Storage**: Ensure proper storage permissions

### User Experience
- Show notification for background downloads
- Allow users to see download progress in notification
- Provide option to pause/resume downloads
- Handle app restart gracefully (downloads continue)

## Testing Checklist

- [ ] Download continues when app goes to background
- [ ] Download continues when app is terminated
- [ ] Download resumes after app restart
- [ ] Progress updates work correctly
- [ ] Pause/resume functionality works
- [ ] Notifications show correct progress
- [ ] Battery optimization doesn't break downloads
- [ ] Works on both Android and iOS

## Recommended Next Steps

1. **Start with `background_downloader`** - Easiest to implement, cross-platform
2. **Test thoroughly** - Especially on different Android versions and iOS
3. **Handle edge cases** - Battery optimization, permissions, storage
4. **Update UI** - Show background download status, notifications
5. **Monitor** - Track download success/failure rates

## Resources

- [background_downloader package](https://pub.dev/packages/background_downloader)
- [Android DownloadManager docs](https://developer.android.com/reference/android/app/DownloadManager)
- [iOS URLSession Background Tasks](https://developer.apple.com/documentation/foundation/urlsession/1407628-backgroundconfiguration)

