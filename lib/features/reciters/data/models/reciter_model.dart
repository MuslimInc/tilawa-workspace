import 'package:dartz_plus/dartz_plus.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/entities/moshaf_entity.dart';
import '../../../../core/entities/reciter_entity.dart';

part 'reciter_model.freezed.dart';
part 'reciter_model.g.dart';

@freezed
@Mapper(ReciterEntity)
abstract class ReciterModel with _$ReciterModel {
  const factory ReciterModel({
    required int id,
    required String name,
    required String letter,
    required String date,
    required List<MoshafModel> moshaf,
  }) = _ReciterModel;

  factory ReciterModel.fromJson(Map<String, dynamic> json) =>
      _$ReciterModelFromJson(json);
}

@freezed
@Mapper(MoshafEntity)
abstract class MoshafModel with _$MoshafModel {
  const factory MoshafModel({
    required int id,
    required String name,
    required String server,
    @JsonKey(name: 'surah_total') required int surahTotal,
    @JsonKey(name: 'moshaf_type') required int moshafType,
    @JsonKey(name: 'surah_list') required String surahList,
  }) = _MoshafModel;

  factory MoshafModel.fromJson(Map<String, dynamic> json) =>
      _$MoshafModelFromJson(json);
}
