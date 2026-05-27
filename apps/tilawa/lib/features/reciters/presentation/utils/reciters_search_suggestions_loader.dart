import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa/features/history/domain/entities/history_entity.dart';
import 'package:tilawa/features/history/domain/usecases/get_recent_history_use_case.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa_core/errors/failures.dart';

/// Builds a short suggestion list for the focused, empty reciter search field.
Future<List<ReciterEntity>> loadRecitersSearchSuggestions({
  required List<ReciterEntity> allReciters,
  required Set<int> favoriteIds,
  GetRecentHistoryUseCase? historyUseCase,
  int maxCount = 6,
}) async {
  if (allReciters.isEmpty || maxCount <= 0) {
    return const <ReciterEntity>[];
  }

  final Map<int, ReciterEntity> recitersById = <int, ReciterEntity>{
    for (final ReciterEntity reciter in allReciters) reciter.id: reciter,
  };

  final Set<int> seen = <int>{};
  final List<ReciterEntity> suggested = <ReciterEntity>[];

  void addReciter(ReciterEntity reciter) {
    if (!seen.add(reciter.id)) {
      return;
    }
    suggested.add(reciter);
  }

  for (final int id in favoriteIds) {
    final ReciterEntity? reciter = recitersById[id];
    if (reciter != null) {
      addReciter(reciter);
    }
    if (suggested.length >= maxCount) {
      return suggested;
    }
  }

  if (suggested.length < maxCount && historyUseCase != null) {
    final Either<Failure, List<HistoryEntity>> result =
        await historyUseCase.call(limit: 12);
    result.fold((_) {}, (List<HistoryEntity> history) {
      for (final HistoryEntity entry in history) {
        final int? reciterId = int.tryParse(entry.reciterId);
        if (reciterId == null) {
          continue;
        }
        final ReciterEntity? reciter = recitersById[reciterId];
        if (reciter != null) {
          addReciter(reciter);
        }
        if (suggested.length >= maxCount) {
          break;
        }
      }
    });
  }

  if (suggested.length < maxCount) {
    for (final ReciterEntity reciter in allReciters) {
      addReciter(reciter);
      if (suggested.length >= maxCount) {
        break;
      }
    }
  }

  return suggested.take(maxCount).toList(growable: false);
}
