import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/islamic_widgets/domain/entities/widget_snapshot_envelope.dart';

void main() {
  group('WidgetSnapshotEnvelope', () {
    test('becomes stale exactly at its freshness boundary', () {
      final DateTime generatedAt = DateTime(2026, 7, 11, 8);
      final DateTime validUntil = DateTime(2026, 7, 12);
      final WidgetSnapshotEnvelope<String> snapshot = WidgetSnapshotEnvelope(
        schemaVersion: 1,
        widgetType: IslamicWidgetType.ayah,
        generatedAt: generatedAt,
        validUntil: validUntil,
        payload: 'display-ready',
      );

      check(
        snapshot.isStaleAt(validUntil.subtract(const Duration(seconds: 1))),
      ).isFalse();
      check(snapshot.isStaleAt(validUntil)).isTrue();
    });

    test('snapshot without a boundary does not become stale', () {
      final WidgetSnapshotEnvelope<String> snapshot = WidgetSnapshotEnvelope(
        schemaVersion: 1,
        widgetType: IslamicWidgetType.prayer,
        generatedAt: DateTime(2026, 7, 11),
        payload: 'display-ready',
      );

      check(snapshot.isStaleAt(DateTime(2030))).isFalse();
    });
  });
}
