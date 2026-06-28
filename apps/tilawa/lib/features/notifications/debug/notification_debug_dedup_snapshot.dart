import 'package:flutter/foundation.dart';

@immutable
class NotificationDebugDedupSnapshot {
  const NotificationDebugDedupSnapshot({
    required this.currentPid,
    this.storedPid,
    this.storedNotificationId,
    this.storedPayloadSignature,
    this.lastProcessedNotificationId,
    this.pendingColdStartLocation,
    this.pendingColdStartExtra,
    this.athkarLastHandledPayload,
    this.athkarLastHandledTimestampMs,
    this.incomingSignaturePreview,
    this.isProcessedPreview,
  });

  final int currentPid;
  final int? storedPid;
  final int? storedNotificationId;
  final String? storedPayloadSignature;
  final int? lastProcessedNotificationId;
  final String? pendingColdStartLocation;
  final Object? pendingColdStartExtra;
  final String? athkarLastHandledPayload;
  final int? athkarLastHandledTimestampMs;
  final String? incomingSignaturePreview;
  final bool? isProcessedPreview;
}
