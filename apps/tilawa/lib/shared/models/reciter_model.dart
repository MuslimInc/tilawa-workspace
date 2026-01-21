import 'package:freezed_annotation/freezed_annotation.dart';

part 'reciter_model.freezed.dart';
part 'reciter_model.g.dart';

// Model for Mosahf
@freezed
abstract class Mosahf with _$Mosahf {
  const factory Mosahf({
    required int id,
    required String name,
    required String server,
    @JsonKey(name: 'surah_total') required int surahTotal,
    @JsonKey(name: 'moshaf_type') required int moshafType,
    @JsonKey(name: 'surah_list') required String surahList,
  }) = _Mosahf;

  factory Mosahf.fromJson(Map<String, dynamic> json) => _$MosahfFromJson(json);
}

// Model for Reciter
@freezed
abstract class Reciter with _$Reciter {
  const factory Reciter({
    required int id,
    required String name,
    required String letter,
    required String date,
    required List<Mosahf> moshaf,
  }) = _Reciter;

  factory Reciter.fromJson(Map<String, dynamic> json) =>
      _$ReciterFromJson(json);
}

// Main Model for Reciters
@freezed
abstract class RecitersModel with _$RecitersModel {
  const factory RecitersModel({required List<Reciter> reciters}) =
      _RecitersModel;

  factory RecitersModel.fromJson(Map<String, dynamic> json) =>
      _$RecitersModelFromJson(json);
}
