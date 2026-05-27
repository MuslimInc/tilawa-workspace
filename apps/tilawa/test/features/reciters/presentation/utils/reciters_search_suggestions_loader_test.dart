import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/reciters/presentation/utils/reciters_search_suggestions_loader.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';

void main() {
  const reciters = <ReciterEntity>[
    ReciterEntity(id: 1, name: 'Alpha', letter: 'A', date: '', moshaf: []),
    ReciterEntity(id: 2, name: 'Beta', letter: 'B', date: '', moshaf: []),
    ReciterEntity(id: 3, name: 'Gamma', letter: 'G', date: '', moshaf: []),
  ];

  test('prioritizes favorites then fills from catalog', () async {
    final List<ReciterEntity> suggested = await loadRecitersSearchSuggestions(
      allReciters: reciters,
      favoriteIds: const <int>{2},
      historyUseCase: null,
      maxCount: 3,
    );

    expect(suggested.first.id, 2);
    expect(suggested.length, 3);
  });
}
