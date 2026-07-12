import 'package:equatable/equatable.dart';

import 'daily_guidance_enums.dart';

/// Tracks the delivery lifecycle of a single guidance item on a specific local date.
/// Used to ensure anti-repetition and daily stability.
class DailyDeliveryRecord extends Equatable {
  final String localDate; // Format: YYYY-MM-DD
  final String itemId;
  final int itemRevision;
  final DateTime? scheduledAt;
  final DateTime? deliveredAt;
  final DateTime? openedAt;
  final DeliveryStatus deliveryStatus;
  final String? selectionReason;
  final String? timezoneAtSelection;

  const DailyDeliveryRecord({
    required this.localDate,
    required this.itemId,
    required this.itemRevision,
    this.scheduledAt,
    this.deliveredAt,
    this.openedAt,
    required this.deliveryStatus,
    this.selectionReason,
    this.timezoneAtSelection,
  });

  DailyDeliveryRecord copyWith({
    String? localDate,
    String? itemId,
    int? itemRevision,
    DateTime? scheduledAt,
    DateTime? deliveredAt,
    DateTime? openedAt,
    DeliveryStatus? deliveryStatus,
    String? selectionReason,
    String? timezoneAtSelection,
  }) {
    return DailyDeliveryRecord(
      localDate: localDate ?? this.localDate,
      itemId: itemId ?? this.itemId,
      itemRevision: itemRevision ?? this.itemRevision,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      openedAt: openedAt ?? this.openedAt,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      selectionReason: selectionReason ?? this.selectionReason,
      timezoneAtSelection: timezoneAtSelection ?? this.timezoneAtSelection,
    );
  }

  @override
  List<Object?> get props => [
    localDate,
    itemId,
    itemRevision,
    scheduledAt,
    deliveredAt,
    openedAt,
    deliveryStatus,
    selectionReason,
    timezoneAtSelection,
  ];
}
