import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../core/logging/app_logger.dart';
import '../domain/entities/athkar_widget_payload.dart';
import '../domain/entities/widget_snapshot_envelope.dart';
import 'widget_snapshot_bridge.dart';

/// Composes and publishes the athkar widget snapshot (spec 041, T026) from
/// the bundled athkar catalog. Content is static, so one publish per
/// content/schema revision is enough — the native host handles the
/// morning/evening window switching by local time.
class AthkarWidgetRepository {
  AthkarWidgetRepository({
    required this._bridge,
    Future<String> Function(String key)? loadAsset,
  }) : _loadAsset = loadAsset ?? rootBundle.loadString;

  static const String catalogAssetKey = 'assets/data/athkar.json';

  /// Category ids in athkar.json.
  static const int _morningCategoryId = 1;
  static const int _eveningCategoryId = 2;

  final WidgetSnapshotBridge _bridge;
  final Future<String> Function(String key) _loadAsset;

  Future<AthkarWidgetPayload> publish(DateTime now) async {
    final Map<String, dynamic> root =
        jsonDecode(await _loadAsset(catalogAssetKey)) as Map<String, dynamic>;
    final List<dynamic> categories = root['categories'] as List<dynamic>;
    final List<dynamic> items = root['athkar'] as List<dynamic>;

    String titleFor(int categoryId) {
      final Map<String, dynamic> category = categories
          .cast<Map<String, dynamic>>()
          .firstWhere((c) => c['id'] == categoryId);
      return category['name_ar'] as String;
    }

    List<AthkarWidgetItem> itemsFor(int categoryId) => <AthkarWidgetItem>[
      for (final dynamic item in items)
        if ((item as Map<String, dynamic>)['category_id'] == categoryId)
          AthkarWidgetItem(
            text: item['text_ar'] as String,
            count: (item['count'] as num?)?.toInt() ?? 1,
          ),
    ];

    final AthkarWidgetPayload payload = AthkarWidgetPayload(
      morningTitle: titleFor(_morningCategoryId),
      eveningTitle: titleFor(_eveningCategoryId),
      morning: itemsFor(_morningCategoryId),
      evening: itemsFor(_eveningCategoryId),
    );
    if (payload.morning.isEmpty || payload.evening.isEmpty) {
      throw StateError('athkar.json produced an empty morning/evening set');
    }

    await _bridge.dispatchSnapshot(
      WidgetSnapshotEnvelope<AthkarWidgetPayload>(
        schemaVersion: 1,
        widgetType: IslamicWidgetType.athkar,
        generatedAt: now,
        payload: payload,
      ),
    );
    logger.d(
      '[AthkarWidgetRepository] Published '
      '${payload.morning.length} morning / ${payload.evening.length} evening',
    );
    return payload;
  }
}
