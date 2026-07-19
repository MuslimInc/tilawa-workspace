import 'package:test/test.dart';
import 'package:tilawa_core/utils/reciter_portrait_catalog.dart';

void main() {
  test('returns CDN URL for known popular reciters', () {
    expect(
      ReciterPortraitCatalog.photoUrlFor(51),
      startsWith('https://tvquran.com/uploads/authors/images/'),
    );
    expect(
      ReciterPortraitCatalog.photoUrlFor(92),
      startsWith('https://tvquran.com/uploads/authors/images/'),
    );
    expect(ReciterPortraitCatalog.byId.containsKey(51), isTrue);
    expect(ReciterPortraitCatalog.byId.containsKey(92), isTrue);
  });

  test('returns null for unmapped reciters', () {
    expect(ReciterPortraitCatalog.photoUrlFor(999999), isNull);
    expect(ReciterPortraitCatalog.photoUrlForIdString(null), isNull);
    expect(ReciterPortraitCatalog.photoUrlForIdString('nope'), isNull);
  });

  test('parses id strings used in audio extras', () {
    expect(
      ReciterPortraitCatalog.photoUrlForIdString('102'),
      ReciterPortraitCatalog.photoUrlFor(102),
    );
  });
}
