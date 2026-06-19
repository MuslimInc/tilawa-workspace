import 'package:test/test.dart';
import 'package:tilawa/features/home/domain/home_daily_inspiration_catalog.dart';

void main() {
  test('rotates inspiration catalog by day of year', () {
    expect(
      homeDailyInspirationCatalogIndex(DateTime(2026, 1, 1)),
      0,
    );
    expect(
      homeDailyInspirationCatalogIndex(DateTime(2026, 1, 2)),
      1,
    );
    expect(
      homeDailyInspirationCatalogIndex(DateTime(2026, 1, 3)),
      2,
    );
    expect(
      homeDailyInspirationCatalogIndex(DateTime(2026, 1, 4)),
      0,
    );
  });
}
