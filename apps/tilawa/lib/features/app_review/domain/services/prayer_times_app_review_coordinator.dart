import 'package:injectable/injectable.dart';

/// Arms the post-prayer review prompt when the user next opens Reciters.
///
/// Prayer times moved from a main tab to a pushed route; this replaces the
/// old shell-tab leave handler that fired when leaving viewport index 2.
@lazySingleton
class PrayerTimesAppReviewCoordinator {
  bool _armLeftPrayerRecitersPrompt = false;

  /// Call when [PrayerTimesScreenScope] is disposed (user left prayer times).
  void onPrayerTimesScreenClosed() {
    _armLeftPrayerRecitersPrompt = true;
  }

  /// Returns whether Reciters navigation should attempt
  /// [AppReviewPromptMoment.leftPrayerTimesTab], then clears the arm.
  bool consumeRecitersPrompt() {
    if (!_armLeftPrayerRecitersPrompt) {
      return false;
    }
    _armLeftPrayerRecitersPrompt = false;
    return true;
  }

  /// Clears a pending prompt when the user switches to another shell tab.
  void cancelRecitersPrompt() {
    _armLeftPrayerRecitersPrompt = false;
  }
}
