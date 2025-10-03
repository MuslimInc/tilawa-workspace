import 'package:equatable/equatable.dart';

// Model for Mosahf
class Mosahf extends Equatable {
  final int id;
  final String name;
  final String server;
  final int surahTotal;
  final int moshafType;
  final String surahList;

  const Mosahf({
    required this.id,
    required this.name,
    required this.server,
    required this.surahTotal,
    required this.moshafType,
    required this.surahList,
  });

  factory Mosahf.fromJson(Map<String, dynamic> json) {
    return Mosahf(
      id: json['id'],
      name: json['name'],
      server: json['server'],
      surahTotal: json['surah_total'],
      moshafType: json['moshaf_type'],
      surahList: json['surah_list'],
    );
  }

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

// Model for Reciter
class Reciter extends Equatable {
  final int id;
  final String name;
  final String letter;
  final String date;
  final List<Mosahf> moshaf;

  const Reciter({
    required this.id,
    required this.name,
    required this.letter,
    required this.date,
    required this.moshaf,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    var moshafList = (json['moshaf'] as List)
        .map((moshafJson) => Mosahf.fromJson(moshafJson))
        .toList();

    return Reciter(
      id: json['id'],
      name: json['name'],
      letter: json['letter'],
      date: json['date'],
      moshaf: moshafList,
    );
  }

  @override
  List<Object?> get props => [id, name, letter, date, moshaf];
}

// Main Model for Reciters
class RecitersModel extends Equatable {
  final List<Reciter> reciters;

  const RecitersModel({required this.reciters});

  factory RecitersModel.fromJson(Map<String, dynamic> json) {
    var recitersList = (json['reciters'] as List)
        .map((reciterJson) => Reciter.fromJson(reciterJson))
        .toList();

    return RecitersModel(reciters: recitersList);
  }

  @override
  List<Object?> get props => [reciters];
}
