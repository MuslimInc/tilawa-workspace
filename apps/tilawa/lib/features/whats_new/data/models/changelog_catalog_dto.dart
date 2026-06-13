import '../../domain/entities/changelog_catalog.dart';
import '../../domain/entities/changelog_release.dart';

class ChangelogCatalogDto {
  const ChangelogCatalogDto({
    required this.schemaVersion,
    required this.releases,
    this.lastUpdatedAt,
  });

  factory ChangelogCatalogDto.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawReleases =
        json['releases'] as List<dynamic>? ?? <dynamic>[];
    final String? lastUpdatedAtRaw = json['lastUpdatedAt'] as String?;
    return ChangelogCatalogDto(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      releases: rawReleases
          .map(
            (dynamic entry) => ChangelogReleaseDto.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(),
      lastUpdatedAt: lastUpdatedAtRaw == null
          ? null
          : DateTime.tryParse(lastUpdatedAtRaw),
    );
  }

  final int schemaVersion;
  final List<ChangelogReleaseDto> releases;
  final DateTime? lastUpdatedAt;

  ChangelogCatalog toEntity() {
    return ChangelogCatalog(
      schemaVersion: schemaVersion,
      releases: releases
          .map((ChangelogReleaseDto dto) => dto.toEntity())
          .toList(),
      lastUpdatedAt: lastUpdatedAt,
    );
  }
}

class ChangelogReleaseDto {
  const ChangelogReleaseDto({
    required this.id,
    required this.version,
    required this.buildNumber,
    required this.highlightsByLocale,
    this.publishedAt,
  });

  factory ChangelogReleaseDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawHighlights =
        json['highlights'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final Map<String, List<String>> highlights = <String, List<String>>{};
    for (final MapEntry<String, dynamic> entry in rawHighlights.entries) {
      final List<dynamic> items = entry.value as List<dynamic>? ?? <dynamic>[];
      highlights[entry.key] = items.map((dynamic item) => '$item').toList();
    }

    final String? publishedAtRaw = json['publishedAt'] as String?;
    return ChangelogReleaseDto(
      id: json['id'] as String? ?? '',
      version: json['version'] as String? ?? '',
      buildNumber: json['buildNumber'] as int? ?? 0,
      highlightsByLocale: highlights,
      publishedAt: publishedAtRaw == null
          ? null
          : DateTime.tryParse(publishedAtRaw),
    );
  }

  final String id;
  final String version;
  final int buildNumber;
  final Map<String, List<String>> highlightsByLocale;
  final DateTime? publishedAt;

  ChangelogRelease toEntity() {
    return ChangelogRelease(
      id: id,
      version: version,
      buildNumber: buildNumber,
      highlightsByLocale: highlightsByLocale,
      publishedAt: publishedAt,
    );
  }
}
