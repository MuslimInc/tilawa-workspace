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

  factory ReciterDetailsState.fromJson(Map<String, dynamic> json) {
    return ReciterDetailsState(
      status: ReciterDetailsStatus.values.byName(json['status'] as String),
      surahList:
          (json['surahList'] as List<dynamic>?)
              ?.map((x) => SurahEntity.fromJson(x as Map<String, dynamic>))
              .toList() ??
          const [],
      selectedMoshaf: json['selectedMoshaf'] != null
          ? MoshafEntity.fromJson(
              json['selectedMoshaf'] as Map<String, dynamic>,
            )
          : null,
      selectedSurahId: json['selectedSurahId'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  final ReciterDetailsStatus status;
  final List<SurahEntity> surahList;
  final MoshafEntity? selectedMoshaf;
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
    MoshafEntity? selectedMoshaf,
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
