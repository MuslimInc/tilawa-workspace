import 'package:equatable/equatable.dart';

/// A single ayah selected for voice recitation practice.
class RecitationTarget extends Equatable {
  const RecitationTarget({
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageNumber,
    required this.displayText,
    required this.normalText,
  });

  final int surahNumber;
  final int ayahNumber;
  final int pageNumber;

  /// Uthmani verse text shown in the practice panel.
  final String displayText;

  /// Diacritic-stripped text used for speech comparison.
  final String normalText;

  @override
  List<Object?> get props => [
    surahNumber,
    ayahNumber,
    pageNumber,
    displayText,
    normalText,
  ];
}
