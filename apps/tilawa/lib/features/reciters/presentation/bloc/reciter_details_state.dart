part of 'reciter_details_bloc.dart';

enum ReciterDetailsStatus { initial, loading, loaded, error }

enum ReciterViewMode { list, grid }

class ReciterDetailsState extends Equatable {
  const ReciterDetailsState({
    this.status = ReciterDetailsStatus.initial,
    this.surahList = const [],
    this.selectedMoshaf,
    this.selectedSurahId,
    this.errorMessage,
    this.searchQuery = '',
    this.playCommand,
    this.listeningHistory = const [],
    this.viewMode = ReciterViewMode.list,
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
      searchQuery: json['searchQuery'] as String? ?? '',
      listeningHistory:
          (json['listeningHistory'] as List<dynamic>?)
              ?.map((x) => HistoryEntity.fromJson(x as Map<String, dynamic>))
              .toList() ??
          const [],
      viewMode: json['viewMode'] != null
          ? ReciterViewMode.values.byName(json['viewMode'] as String)
          : ReciterViewMode.list,
    );
  }

  final ReciterDetailsStatus status;
  final List<SurahEntity> surahList;
  final MoshafEntity? selectedMoshaf;
  final String? selectedSurahId;
  final String? errorMessage;
  final String searchQuery;
  final PlaySurahCommand? playCommand;
  final List<HistoryEntity> listeningHistory;
  final ReciterViewMode viewMode;

  @override
  List<Object?> get props => [
    status,
    surahList,
    selectedMoshaf,
    selectedSurahId,
    errorMessage,
    searchQuery,
    playCommand,
    listeningHistory,
    viewMode,
  ];

  ReciterDetailsState copyWith({
    ReciterDetailsStatus? status,
    List<SurahEntity>? surahList,
    MoshafEntity? selectedMoshaf,
    String? selectedSurahId,
    String? errorMessage,
    String? searchQuery,
    PlaySurahCommand? playCommand,
    List<HistoryEntity>? listeningHistory,
    ReciterViewMode? viewMode,
  }) {
    return ReciterDetailsState(
      status: status ?? this.status,
      surahList: surahList ?? this.surahList,
      selectedMoshaf: selectedMoshaf ?? this.selectedMoshaf,
      selectedSurahId: selectedSurahId ?? this.selectedSurahId,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      playCommand: playCommand, // No default, it's transient
      listeningHistory: listeningHistory ?? this.listeningHistory,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  /// Returns filtered surah list based on [searchQuery]
  List<SurahEntity> get filteredSurahs {
    if (searchQuery.isEmpty) {
      return surahList;
    }
    final String query = searchQuery.toLowerCase();
    return surahList.where((surah) {
      // Search by index (padded number)
      final String indexStr = surah.formattedId;
      // Search by English name
      final String nameEn = surah.nameEn.toLowerCase();
      final String nameTitle = surah.name.toLowerCase();
      // Search by Arabic name
      final String nameAr = surah.nameAr.toLowerCase();

      return indexStr.contains(query) ||
          nameEn.contains(query) ||
          nameTitle.contains(query) ||
          nameAr.contains(query);
    }).toList();
  }
}

class PlaySurahCommand extends Equatable {
  const PlaySurahCommand({required this.playlist, required this.initialIndex});
  final List<AudioEntity> playlist;
  final int initialIndex;

  @override
  List<Object?> get props => [playlist, initialIndex];
}
