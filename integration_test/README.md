# Integration Tests for Tilawa

This directory contains integration tests for the Tilawa app. Integration tests verify that different parts of the app work together correctly in a real environment.

## Surah Download Integration Tests

The `surah_download_test.dart` file contains comprehensive tests for downloading surahs from the reciter details screen.

### Test Coverage

1. **Online Download** - Downloads a surah with an active internet connection
   - Navigates to reciter details screen
   - Finds a downloadable surah
   - Initiates download
   - Verifies progress indicator appears
   - Waits for download completion
   - Verifies green checkmark appears

2. **Offline Download** - Attempts to download without internet
   - Tests error handling when network is unavailable
   - Verifies appropriate error message is shown
   - Note: Requires manual airplane mode activation or network mocking

3. **Download Progress** - Monitors progress during download
   - Verifies progress percentage updates
   - Ensures progress is monotonically increasing
   - Tracks progress from 0% to 100%

4. **Already Downloaded** - Verifies UI for downloaded surahs
   - Checks that downloaded surahs show green checkmark
   - Verifies checkmark icon is displayed correctly

5. **Download Cancellation** - Tests canceling an ongoing download
   - Starts a download
   - Cancels it mid-download
   - Verifies download button reappears

6. **Search and Download** - Tests search functionality with download
   - Uses search field to find a specific surah
   - Downloads the searched surah
   - Verifies download starts correctly

## Bottom Player Integration Tests

The `bottom_player_test.dart` file contains comprehensive tests for the bottom player widget functionality when playing surahs.

### Test Coverage

1. **Playing Surah Shows Bottom Player** - Tapping a surah from reciter details displays the bottom player
   - Navigates to reciter details screen
   - Taps on a surah to start playback
   - Verifies bottom player appears

2. **Correct Info Display** - Bottom player shows correct surah and reciter info
   - Verifies reciter name is displayed
   - Verifies surah title is shown

3. **Play/Pause Controls** - Play/Pause button toggles playback state
   - Taps play/pause button
   - Verifies button state changes

4. **Skip Next** - Skip next button advances to next surah
   - Taps next button in bottom player
   - Verifies playback continues

5. **Skip Previous** - Skip previous button goes to previous surah
   - Starts from surah 2
   - Taps previous button
   - Verifies playback continues

6. **Dismiss by Swiping** - Swiping down dismisses bottom player and stops playback
   - Swipes bottom player down
   - Verifies player is dismissed

7. **Progress Indicator** - Bottom player shows linear progress indicator
   - Verifies LinearProgressIndicator is present

8. **Tap to Expand** - Tapping bottom player navigates to expanded player
   - Taps on bottom player content
   - Verifies navigation to expanded player

## Running Integration Tests

### Prerequisites

1. **Device or Emulator**: Integration tests must run on a real device or emulator
2. **Internet Connection**: Most tests require an active internet connection
3. **Clean State**: For best results, start with a fresh app installation

### Run All Integration Tests

```bash
# On a connected device or running emulator
flutter test integration_test/

# Or run a specific test file
flutter test integration_test/surah_download_test.dart
flutter test integration_test/bottom_player_test.dart
flutter test integration_test/download_all_button_test.dart
```

### Run on Specific Platform

```bash
# Android
flutter test integration_test/ --device-id <android-device-id>

# iOS
flutter test integration_test/ --device-id <ios-device-id>

# Get list of available devices
flutter devices
```

### Run with Verbose Output

```bash
flutter test integration_test/ --verbose
```

### Run in Debug Mode

```bash
# This allows you to see the UI during test execution
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/surah_download_test.dart
```

## Test Driver Setup (Optional)

If you want to use `flutter drive` instead of `flutter test`, create a test driver:

1. Create `test_driver/integration_test.dart`:

```dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

2. Run with:

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/surah_download_test.dart
```

## Troubleshooting

### Tests Fail to Find Widgets

- **Issue**: Finders can't locate UI elements
- **Solution**: Increase `pumpAndSettle` delays or use `pump` with longer durations
- **Example**: Change `await tester.pumpAndSettle(const Duration(seconds: 2));` to 3-5 seconds

### Network-Related Failures

- **Issue**: Downloads fail or timeout
- **Solution**:
  - Ensure stable internet connection
  - Increase timeout duration in tests
  - Check if API endpoints are accessible

### Offline Test Not Working

- **Issue**: Offline test doesn't detect network absence
- **Solution**:
  - Manually enable airplane mode before running the test
  - Or implement platform-specific network mocking
  - Consider using `connectivity_plus` package to verify network state

### Download Already Completed

- **Issue**: Test expects download button but finds checkmark
- **Solution**:
  - Clear app data before running tests
  - Or modify test to handle already-downloaded state
  - Use `flutter run --clear-cache`

## Best Practices

1. **Clean State**: Always start tests with a clean app state
2. **Timeouts**: Use generous timeouts for network operations
3. **Pumping**: Use `pumpAndSettle` after navigation and `pump` for animations
4. **Finders**: Use multiple finder strategies (icon, text, type) for robustness
5. **Assertions**: Add descriptive `reason` parameters to `expect` calls
6. **Cleanup**: Clean up downloads in `tearDown` to avoid test pollution

## CI/CD Integration

To run integration tests in CI/CD:

```yaml
# Example GitHub Actions workflow
- name: Run Integration Tests
  run: |
    flutter emulators --launch <emulator-name>
    flutter test integration_test/
```

Note: CI/CD integration tests require emulator/simulator setup and may need additional configuration for network access.

## Writing New Integration Tests

When adding new integration tests:

1. Follow the existing test structure
2. Use descriptive test names
3. Add comments explaining each step
4. Handle edge cases (already downloaded, no internet, etc.)
5. Use `pumpAndSettle` after user interactions
6. Add appropriate timeouts for async operations
7. Clean up state in `tearDown`

## Related Documentation

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [integration_test package](https://pub.dev/packages/integration_test)
- [Widget Testing](https://docs.flutter.dev/testing/overview#widget-tests)
