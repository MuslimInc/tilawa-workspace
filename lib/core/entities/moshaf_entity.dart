import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'moshaf_entity.g.dart';

@JsonSerializable()
class MoshafEntity extends Equatable {
  const MoshafEntity({
    required this.id,
    required this.name,
    required this.server,
    required this.surahTotal,
    required this.moshafType,
    required this.surahList,
  });

  factory MoshafEntity.fromJson(Map<String, dynamic> json) =>
      _$MoshafEntityFromJson(json);

  final int id;
  final String name;
  final String server;
  final int surahTotal;
  final int moshafType;
  final String surahList;

  Map<String, dynamic> toJson() => _$MoshafEntityToJson(this);

  @override
  List<Object?> get props => [
    id,
    name,
    server,
    surahTotal,
    moshafType,
    surahList,
  ];
}
