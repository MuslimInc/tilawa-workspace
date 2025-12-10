part of 'reciter_details_bloc.dart';

enum ReciterDetailsStatus { initial, loading, loaded, error }

class ReciterDetailsState extends Equatable {
  const ReciterDetailsState({
    this.status = ReciterDetailsStatus.initial,
    this.surahList = const [],
    this.selectedMoshaf,
    this.selectedSurahId,
    this.errorMessage,
  });

  final ReciterDetailsStatus status;
  final List<SurahEntity> surahList;
  final Mosahf? selectedMoshaf;
  final String? selectedSurahId;
  final String? errorMessage;

  @override
  List<Object?> get props => [
    status,
    surahList,
    selectedMoshaf,
    selectedSurahId,
    errorMessage,
  ];

  ReciterDetailsState copyWith({
    ReciterDetailsStatus? status,
    List<SurahEntity>? surahList,
    Mosahf? selectedMoshaf,
    String? selectedSurahId,
    String? errorMessage,
  }) {
    return ReciterDetailsState(
      status: status ?? this.status,
      surahList: surahList ?? this.surahList,
      selectedMoshaf: selectedMoshaf ?? this.selectedMoshaf,
      selectedSurahId: selectedSurahId ?? this.selectedSurahId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
