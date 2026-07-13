import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/daily_delivery_record.dart';
import '../../domain/entities/daily_guidance_enums.dart';

part 'daily_delivery_record_model.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class DailyDeliveryRecordModel extends Equatable {
  final String localDate;
  final String itemId;
  final int itemRevision;
  final DateTime? scheduledAt;
  final DateTime? deliveredAt;
  final DateTime? openedAt;
  final DeliveryStatus deliveryStatus;
  final String? selectionReason;
  final String? timezoneAtSelection;

  const DailyDeliveryRecordModel({
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

  factory DailyDeliveryRecordModel.fromJson(Map<String, dynamic> json) =>
      _$DailyDeliveryRecordModelFromJson(json);

  Map<String, dynamic> toJson() => _$DailyDeliveryRecordModelToJson(this);
}

extension DailyDeliveryRecordModelMapper on DailyDeliveryRecordModel {
  DailyDeliveryRecord toEntity() {
    return DailyDeliveryRecord(
      localDate: localDate,
      itemId: itemId,
      itemRevision: itemRevision,
      scheduledAt: scheduledAt,
      deliveredAt: deliveredAt,
      openedAt: openedAt,
      deliveryStatus: deliveryStatus,
      selectionReason: selectionReason,
      timezoneAtSelection: timezoneAtSelection,
    );
  }
}

extension DailyDeliveryRecordMapper on DailyDeliveryRecord {
  DailyDeliveryRecordModel toModel() {
    return DailyDeliveryRecordModel(
      localDate: localDate,
      itemId: itemId,
      itemRevision: itemRevision,
      scheduledAt: scheduledAt,
      deliveredAt: deliveredAt,
      openedAt: openedAt,
      deliveryStatus: deliveryStatus,
      selectionReason: selectionReason,
      timezoneAtSelection: timezoneAtSelection,
    );
  }
}
