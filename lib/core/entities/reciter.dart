import 'package:equatable/equatable.dart';

class ReciterEntity extends Equatable {
  const ReciterEntity({
    required this.id,
    required this.name,
    required this.letter,
    required this.date,
    required this.moshaf,
  });

  final int id;
  final String name;
  final String letter;
  final String date;
  final List<MoshafEntity> moshaf;

  @override
  List<Object?> get props => [id, name, letter, date, moshaf];
}

class MoshafEntity extends Equatable {
  const MoshafEntity({
    required this.id,
    required this.name,
    required this.server,
    required this.surahTotal,
    required this.moshafType,
    required this.surahList,
  });

  final int id;
  final String name;
  final String server;
  final int surahTotal;
  final int moshafType;
  final String surahList;

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
