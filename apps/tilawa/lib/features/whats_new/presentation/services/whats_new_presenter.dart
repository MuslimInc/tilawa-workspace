import '../../domain/entities/changelog_release.dart';

/// Presentation port for the what's new bottom sheet.
abstract class WhatsNewPresenter {
  Future<void> show({
    required ChangelogRelease release,
    required Future<void> Function() onDismissed,
  });
}
