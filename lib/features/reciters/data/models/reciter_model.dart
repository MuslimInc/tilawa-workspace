import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/entities/reciter.dart';

part 'reciter_model.freezed.dart';
part 'reciter_model.g.dart';

@freezed
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

extension ReciterModelX on ReciterModel {
  ReciterEntity toEntity() {
    return ReciterEntity(
      id: id,
      name: name,
      letter: letter,
      date: date,
      moshaf: moshaf.map((m) => m.toEntity()).toList(),
    );
  }
}

extension MoshafModelX on MoshafModel {
  MoshafEntity toEntity() {
    return MoshafEntity(
      id: id,
      name: name,
      server: server,
      surahTotal: surahTotal,
      moshafType: moshafType,
      surahList: surahList,
    );
  }
}
