import 'package:equatable/equatable.dart';

/// User-facing release notes for one app version.
class ChangelogRelease extends Equatable {
  const ChangelogRelease({
    required this.id,
    required this.version,
    required this.buildNumber,
    required this.highlightsByLocale,
    this.publishedAt,
  });

  final String id;
  final String version;
  final int buildNumber;
  final Map<String, List<String>> highlightsByLocale;
  final DateTime? publishedAt;

  static String composeId({
    required String version,
    required int buildNumber,
  }) {
    return '$version+$buildNumber';
  }

  List<String> highlightsFor(String languageCode) {
    final List<String>? localized = highlightsByLocale[languageCode];
    if (localized != null && localized.isNotEmpty) {
      return localized;
    }
    return highlightsByLocale['en'] ?? const <String>[];
  }

  @override
  List<Object?> get props => [
    id,
    version,
    buildNumber,
    highlightsByLocale,
    publishedAt,
  ];
}
