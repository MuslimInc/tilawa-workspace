import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';

void main() {
  // Test data
  const testMoshaf = MoshafEntity(
    id: 1,
    name: "Rewayat Hafs A'n Assem",
    server: 'https://server.example.com/',
    surahTotal: 114,
    moshafType: 1,
    surahList: '1,2,3',
  );

  const testReciter1 = ReciterEntity(
    id: 1,
    name: 'Abdul Basit Abdul Samad',
    letter: 'A',
    date: '2024-01-01',
    moshaf: [testMoshaf],
  );

  const testReciter2 = ReciterEntity(
    id: 2,
    name: 'Mishary Rashid Alafasy',
    letter: 'M',
    date: '2024-01-02',
    moshaf: [testMoshaf],
  );

  const testReciter3 = ReciterEntity(
    id: 3,
    name: 'Ahmad Al-Ajmi',
    letter: 'A',
    date: '2024-01-03',
    moshaf: [testMoshaf],
  );

  final testReciters = [testReciter1, testReciter2, testReciter3];

  group('RecitersInitial', () {
    test('should be a subclass of RecitersState', () {
      const state = RecitersInitial();
      expect(state, isA<RecitersState>());
    });

    test('props should be empty', () {
      const state = RecitersInitial();
      expect(state.props, isEmpty);
    });

    test('two instances should be equal', () {
      const state1 = RecitersInitial();
      const state2 = RecitersInitial();
      expect(state1, equals(state2));
    });
  });

  group('RecitersLoading', () {
    test('should be a subclass of RecitersState', () {
      const state = RecitersLoading();
      expect(state, isA<RecitersState>());
    });

    test('props should be empty', () {
      const state = RecitersLoading();
      expect(state.props, isEmpty);
    });

    test('two instances should be equal', () {
      const state1 = RecitersLoading();
      const state2 = RecitersLoading();
      expect(state1, equals(state2));
    });
  });

  group('RecitersLoaded', () {
    test('should be a subclass of RecitersState', () {
      final state = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
      );
      expect(state, isA<RecitersState>());
    });

    test('props should contain all properties', () {
      final state = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
        searchQuery: 'test',
        selectedLetter: 'A',
      );
      expect(state.props, [testReciters, testReciters, 'test', 'A']);
    });

    test('default searchQuery should be empty string', () {
      final state = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
      );
      expect(state.searchQuery, '');
    });

    test('default selectedLetter should be null', () {
      final state = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
      );
      expect(state.selectedLetter, isNull);
    });

    test('two instances with same values should be equal', () {
      final state1 = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
        searchQuery: 'test',
        selectedLetter: 'A',
      );
      final state2 = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
        searchQuery: 'test',
        selectedLetter: 'A',
      );
      expect(state1, equals(state2));
    });

    test('two instances with different reciters should not be equal', () {
      final state1 = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
      );
      const state2 = RecitersLoaded(
        reciters: [testReciter1],
        filteredReciters: [testReciter1],
      );
      expect(state1, isNot(equals(state2)));
    });

    test('two instances with different searchQuery should not be equal', () {
      final state1 = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
        searchQuery: 'test1',
      );
      final state2 = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
        searchQuery: 'test2',
      );
      expect(state1, isNot(equals(state2)));
    });

    test('two instances with different selectedLetter should not be equal', () {
      final state1 = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
        selectedLetter: 'A',
      );
      final state2 = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
        selectedLetter: 'B',
      );
      expect(state1, isNot(equals(state2)));
    });

    group('copyWith', () {
      test('should return new instance with updated reciters', () {
        final state = RecitersLoaded(
          reciters: testReciters,
          filteredReciters: testReciters,
        );
        final RecitersLoaded newState = state.copyWith(
          reciters: [testReciter1],
        );
        expect(newState.reciters, [testReciter1]);
        expect(newState.filteredReciters, testReciters);
      });

      test('should return new instance with updated filteredReciters', () {
        final state = RecitersLoaded(
          reciters: testReciters,
          filteredReciters: testReciters,
        );
        final RecitersLoaded newState = state.copyWith(
          filteredReciters: [testReciter2],
        );
        expect(newState.reciters, testReciters);
        expect(newState.filteredReciters, [testReciter2]);
      });

      test('should return new instance with updated searchQuery', () {
        final state = RecitersLoaded(
          reciters: testReciters,
          filteredReciters: testReciters,
          searchQuery: 'old',
        );
        final RecitersLoaded newState = state.copyWith(searchQuery: 'new');
        expect(newState.searchQuery, 'new');
      });

      test('should return new instance with updated selectedLetter', () {
        final state = RecitersLoaded(
          reciters: testReciters,
          filteredReciters: testReciters,
          selectedLetter: 'A',
        );
        final RecitersLoaded newState = state.copyWith(selectedLetter: 'B');
        expect(newState.selectedLetter, 'B');
      });

      test('should clear selectedLetter when clearSelectedLetter is true', () {
        final state = RecitersLoaded(
          reciters: testReciters,
          filteredReciters: testReciters,
          selectedLetter: 'A',
        );
        final RecitersLoaded newState = state.copyWith(
          clearSelectedLetter: true,
        );
        expect(newState.selectedLetter, isNull);
      });

      test(
        'should ignore selectedLetter param when clearSelectedLetter is true',
        () {
          final state = RecitersLoaded(
            reciters: testReciters,
            filteredReciters: testReciters,
            selectedLetter: 'A',
          );
          final RecitersLoaded newState = state.copyWith(
            selectedLetter: 'B',
            clearSelectedLetter: true,
          );
          expect(newState.selectedLetter, isNull);
        },
      );

      test('should preserve original values when no params provided', () {
        final state = RecitersLoaded(
          reciters: testReciters,
          filteredReciters: testReciters,
          searchQuery: 'test',
          selectedLetter: 'A',
        );
        final RecitersLoaded newState = state.copyWith();
        expect(newState.reciters, testReciters);
        expect(newState.filteredReciters, testReciters);
        expect(newState.searchQuery, 'test');
        expect(newState.selectedLetter, 'A');
      });

      test('should update multiple properties at once', () {
        final state = RecitersLoaded(
          reciters: testReciters,
          filteredReciters: testReciters,
        );
        final RecitersLoaded newState = state.copyWith(
          filteredReciters: [testReciter1],
          searchQuery: 'Abdul',
          selectedLetter: 'A',
        );
        expect(newState.reciters, testReciters);
        expect(newState.filteredReciters, [testReciter1]);
        expect(newState.searchQuery, 'Abdul');
        expect(newState.selectedLetter, 'A');
      });
    });
  });

  group('RecitersError', () {
    test('should be a subclass of RecitersState', () {
      const state = RecitersError('Error message');
      expect(state, isA<RecitersState>());
    });

    test('props should contain message', () {
      const state = RecitersError('Error message');
      expect(state.props, ['Error message']);
    });

    test('two instances with same message should be equal', () {
      const state1 = RecitersError('Error message');
      const state2 = RecitersError('Error message');
      expect(state1, equals(state2));
    });

    test('two instances with different message should not be equal', () {
      const state1 = RecitersError('Error 1');
      const state2 = RecitersError('Error 2');
      expect(state1, isNot(equals(state2)));
    });

    test('message should be accessible', () {
      const state = RecitersError('Test error');
      expect(state.message, 'Test error');
    });
  });

  group('RecitersState equality', () {
    test('different state types should not be equal', () {
      const initial = RecitersInitial();
      const loading = RecitersLoading();
      final loaded = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
      );
      const error = RecitersError('Error');

      expect(initial, isNot(equals(loading)));
      expect(initial, isNot(equals(loaded)));
      expect(initial, isNot(equals(error)));
      expect(loading, isNot(equals(loaded)));
      expect(loading, isNot(equals(error)));
      expect(loaded, isNot(equals(error)));
    });
  });
}
