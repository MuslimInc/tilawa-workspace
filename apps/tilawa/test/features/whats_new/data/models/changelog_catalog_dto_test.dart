import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/whats_new/data/models/changelog_catalog_dto.dart';

void main() {
  group('ChangelogCatalogDto', () {
    test('parses bundled release shape', () {
      final ChangelogCatalogDto dto = ChangelogCatalogDto.fromJson(
        <String, dynamic>{
          'schemaVersion': 1,
          'releases': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': '2.0.8+52',
              'version': '2.0.8',
              'buildNumber': 52,
              'publishedAt': '2026-06-10',
              'highlights': <String, List<String>>{
                'en': <String>['First highlight'],
                'ar': <String>['أول نقطة'],
              },
            },
          ],
        },
      );

      expect(dto.schemaVersion, 1);
      expect(dto.releases, hasLength(1));
      expect(dto.releases.first.id, '2.0.8+52');
      expect(dto.releases.first.highlightsByLocale['en'], <String>[
        'First highlight',
      ]);

      final catalog = dto.toEntity();
      expect(catalog.findById('2.0.8+52')?.version, '2.0.8');
    });
  });
}
