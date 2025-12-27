import 'package:freezed_annotation/freezed_annotation.dart';

import 'moshaf_entity.dart';

part 'reciter_entity.freezed.dart';
part 'reciter_entity.g.dart';

@freezed
abstract class ReciterEntity with _$ReciterEntity {
  const factory ReciterEntity({
    required int id,
    required String name,
    required String letter,
    required String date,
    required List<MoshafEntity> moshaf,
  }) = _ReciterEntity;

  factory ReciterEntity.fromJson(Map<String, dynamic> json) =>
      _$ReciterEntityFromJson(json);
}
