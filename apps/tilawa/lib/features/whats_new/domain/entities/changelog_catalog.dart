import 'package:equatable/equatable.dart';

import 'changelog_release.dart';

/// Bundled changelog entries ordered newest-first.
class ChangelogCatalog extends Equatable {
  const ChangelogCatalog({
    required this.schemaVersion,
    required this.releases,
  });

  final int schemaVersion;
  final List<ChangelogRelease> releases;

  ChangelogRelease? findById(String releaseId) {
    for (final ChangelogRelease release in releases) {
      if (release.id == releaseId) {
        return release;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [schemaVersion, releases];
}
