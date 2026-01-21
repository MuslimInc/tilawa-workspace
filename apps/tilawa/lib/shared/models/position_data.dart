import 'package:freezed_annotation/freezed_annotation.dart';

part 'position_data.freezed.dart';
part 'position_data.g.dart';

@freezed
abstract class PositionData with _$PositionData {
  const factory PositionData({
    required Duration position,
    required Duration bufferedPosition,
    required Duration duration,
  }) = _PositionData;

  factory PositionData.fromJson(Map<String, dynamic> json) =>
      _$PositionDataFromJson(json);
}
