import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/islamic_widgets/data/widget_snapshot_bridge.dart';
import 'package:tilawa/features/islamic_widgets/domain/entities/widget_snapshot_envelope.dart';
import 'package:tilawa/features/islamic_widgets/domain/entities/wird_progress_widget_payload.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('tilawa/islamic_widgets');

  WirdProgressWidgetPayload payload(DateTime generatedAt, DateTime expiresAt) =>
      WirdProgressWidgetPayload(
        locale: 'en',
        textDirection: WirdWidgetTextDirection.ltr,
        localizedTitle: "Today's Wird",
        localizedSubtitle: '5 of 20 pages completed · 15 remaining',
        formattedAssignedAmount: '20',
        formattedCompletedAmount: '5',
        formattedRemainingAmount: '15',
        progressValue: 0.25,
        accessibilityLabel:
            "Today's Wird. 5 of 20 pages completed · 15 remaining",
        action: WirdWidgetAction.openTodayWird,
        generatedAt: generatedAt,
        expiresAt: expiresAt,
        isStale: false,
      );

  group('wird snapshot over the existing widget bridge', () {
    late List<MethodCall> calls;

    setUp(() {
      calls = <MethodCall>[];
      final TestDefaultBinaryMessenger messenger =
          TestWidgetsFlutterBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        return null;
      });
    });

    tearDown(() {
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
      'dispatches a wird envelope with the "wird" discriminator and a '
      'render-verbatim payload the native side can parse back',
      () async {
        final DateTime generatedAt = DateTime.utc(2026, 7, 12, 9, 30);
        final DateTime expiresAt = DateTime.utc(2026, 7, 13);
        final WidgetSnapshotEnvelope<WirdProgressWidgetPayload> envelope =
            WidgetSnapshotEnvelope<WirdProgressWidgetPayload>(
              schemaVersion: WirdProgressWidgetPayload.currentSchemaVersion,
              widgetType: IslamicWidgetType.wird,
              generatedAt: generatedAt,
              validUntil: expiresAt,
              payload: payload(generatedAt, expiresAt),
            );

        await const WidgetSnapshotBridge(channel).dispatchSnapshot(envelope);

        check(calls).length.equals(1);
        final MethodCall call = calls.single;
        check(call.method).equals('updateIslamicWidgetSnapshot');

        final Map<Object?, Object?> args =
            call.arguments as Map<Object?, Object?>;
        check(args['widgetType']).equals('wird');

        final Map<String, Object?> decoded =
            jsonDecode(args['json']! as String) as Map<String, Object?>;
        check(decoded['widgetType']).equals('wird');
        check(decoded['generatedAtMs']).equals(
          generatedAt.millisecondsSinceEpoch,
        );
        check(decoded['validUntilMs']).equals(expiresAt.millisecondsSinceEpoch);

        // The envelope's payload survives the bridge and round-trips back into a
        // domain payload (the shape the native provider renders verbatim).
        final WirdProgressWidgetPayload? reparsed =
            WirdProgressWidgetPayload.tryParse(
              decoded['payload']! as Map<String, Object?>,
            );
        check(reparsed).isNotNull();
        check(reparsed!.action).equals(WirdWidgetAction.openTodayWird);
      },
    );
  });
}
