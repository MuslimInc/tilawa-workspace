import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/daily_guidance_item.dart';

part 'quran_source_metadata_model.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class QuranSourceMetadataModel extends Equatable {
  final int surahNumber;
  final String surahNameArabic;
  final Map<String, String>? surahNameLocalized;
  final int ayahStart;
  final int? ayahEnd;
  final String quranTextSourceId;
  final Map<String, String>? translationSourceIds;
  final String? tafsirSourceId;

  const QuranSourceMetadataModel({
    required this.surahNumber,
    required this.surahNameArabic,
    this.surahNameLocalized,
    required this.ayahStart,
    this.ayahEnd,
    required this.quranTextSourceId,
    this.translationSourceIds,
    this.tafsirSourceId,
  });

  @override
  List<Object?> get props => [
    surahNumber,
    surahNameArabic,
    surahNameLocalized,
    ayahStart,
    ayahEnd,
    quranTextSourceId,
    translationSourceIds,
    tafsirSourceId,
  ];

  factory QuranSourceMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$QuranSourceMetadataModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuranSourceMetadataModelToJson(this);
}

extension QuranSourceMetadataModelMapper on QuranSourceMetadataModel {
  QuranSourceMetadata toEntity() {
    return QuranSourceMetadata(
      surahNumber: surahNumber,
      surahNameArabic: surahNameArabic,
      surahNameLocalized: surahNameLocalized,
      ayahStart: ayahStart,
      ayahEnd: ayahEnd,
      quranTextSourceId: quranTextSourceId,
      translationSourceIds: translationSourceIds,
      tafsirSourceId: tafsirSourceId,
    );
  }
}

extension QuranSourceMetadataMapper on QuranSourceMetadata {
  QuranSourceMetadataModel toModel() {
    return QuranSourceMetadataModel(
      surahNumber: surahNumber,
      surahNameArabic: surahNameArabic,
      surahNameLocalized: surahNameLocalized,
      ayahStart: ayahStart,
      ayahEnd: ayahEnd,
      quranTextSourceId: quranTextSourceId,
      translationSourceIds: translationSourceIds,
      tafsirSourceId: tafsirSourceId,
    );
  }
}
