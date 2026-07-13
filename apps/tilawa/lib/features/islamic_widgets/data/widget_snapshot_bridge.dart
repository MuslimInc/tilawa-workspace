import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/entities/widget_snapshot_envelope.dart';

/// Bridges [WidgetSnapshotEnvelope] payloads to the native Android widget hosts.
class WidgetSnapshotBridge {
  const WidgetSnapshotBridge(this._channel);

  final MethodChannel _channel;

  /// Enables or disables launcher discovery of the staged Daily Wird widget.
  Future<void> setWirdWidgetEnabled({required bool enabled}) =>
      _channel.invokeMethod<void>(
        'setWirdWidgetEnabled',
        <String, bool>{'enabled': enabled},
      );

  /// Serializes and sends a snapshot to the native Android storage.
  /// The generic type [T] must be JSON-encodable (e.g., via `toJson()`).
  Future<void> dispatchSnapshot<T extends Object>(
    WidgetSnapshotEnvelope<T> envelope,
  ) async {
    // Key names must match the native parser contract
    // (WidgetSnapshotEnvelope.kt): generatedAtMs / validUntilMs.
    final Map<String, dynamic> jsonMap = <String, dynamic>{
      'schemaVersion': envelope.schemaVersion,
      'widgetType': envelope.widgetType.name,
      'generatedAtMs': envelope.generatedAt.millisecondsSinceEpoch,
      'validUntilMs': envelope.validUntil?.millisecondsSinceEpoch,
      // Assume T has a toJson() method or is directly encodable.
      'payload': (envelope.payload as dynamic).toJson(),
    };

    final String jsonString = jsonEncode(jsonMap);

    await _channel.invokeMethod<void>(
      'updateIslamicWidgetSnapshot',
      <String, dynamic>{
        'widgetType': envelope.widgetType.name,
        'json': jsonString,
      },
    );
  }
}
