import 'package:equatable/equatable.dart';

import 'moshaf_entity.dart';

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
