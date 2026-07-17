import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/domain/home_daily_inspiration_catalog.dart';

void main() {
  test('catalog has 30 day entries with verse coordinates', () {
    expect(homeDailyInspirationCatalogLength, 30);
    expect(homeDailyInspirationEntries, hasLength(30));
    expect(homeDailyAyahCatalogVerses, hasLength(30));

    for (final HomeDailyInspirationEntry entry in homeDailyInspirationEntries) {
      expect(entry.ayahBodyAr, isNotEmpty);
      expect(entry.ayahBodyEn, isNotEmpty);
      expect(entry.duaBodyAr, isNotEmpty);
      expect(entry.duaBodyEn, isNotEmpty);
      expect(entry.surahNumber, greaterThan(0));
      expect(entry.ayahNumber, greaterThan(0));
    }
  });

  test('catalog index cycles every 30 days of year', () {
    expect(homeDailyInspirationCatalogIndex(DateTime(2026, 1, 1)), 0);
    expect(homeDailyInspirationCatalogIndex(DateTime(2026, 1, 30)), 29);
    expect(homeDailyInspirationCatalogIndex(DateTime(2026, 1, 31)), 0);
    expect(homeDailyInspirationCatalogIndex(DateTime(2026, 2, 1)), 1);
  });
}
