import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa_core/entities/moshaf_entity.dart';
import 'package:tilawa_core/entities/reciter_entity.dart';
import 'package:tilawa/features/reciters/presentation/bloc/reciters_bloc.dart';
import 'package:tilawa_core/errors/failures.dart';

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
        selectedLetter: 'A',
      );
      expect(state.props, [
        testReciters,
        testReciters,
        'A',
        false,
        const <int>[],
      ]);
    });

    test('default selectedLetter should be null', () {
      final state = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
      );
      expect(state.selectedLetter, isNull);
    });

    test('default showFavoritesOnly should be false', () {
      final state = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
      );
      expect(state.showFavoritesOnly, isFalse);
    });

    test('default favoriteIds should be empty', () {
      final state = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
      );
      expect(state.favoriteIds, isEmpty);
    });

    test('two instances with same values should be equal', () {
      final state1 = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
        selectedLetter: 'A',
      );
      final state2 = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
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

    test(
      'two instances with different showFavoritesOnly should not be equal',
      () {
        final state1 = RecitersLoaded(
          reciters: testReciters,
          filteredReciters: testReciters,
          showFavoritesOnly: true,
        );
        final state2 = RecitersLoaded(
          reciters: testReciters,
          filteredReciters: testReciters,
        );
        expect(state1, isNot(equals(state2)));
      },
    );

    test('two instances with different favoriteIds should not be equal', () {
      final state1 = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
        favoriteIds: const {1, 2},
      );
      final state2 = RecitersLoaded(
        reciters: testReciters,
        filteredReciters: testReciters,
        favoriteIds: const {1},
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

      test('should return new instance with updated selectedLetter', () {
        final state = RecitersLoaded(
          reciters: testReciters,
          filteredReciters: testReciters,
          selectedLetter: 'A',
        );
        final RecitersLoaded newState = state.copyWith(selectedLetter: 'B');
        expect(newState.selectedLetter, 'B');
      });

      test('should return new instance with updated showFavoritesOnly', () {
        final state = RecitersLoaded(
          reciters: testReciters,
          filteredReciters: testReciters,
        );
        final RecitersLoaded newState = state.copyWith(showFavoritesOnly: true);
        expect(newState.showFavoritesOnly, isTrue);
      });

      test('should return new instance with updated favoriteIds', () {
        final state = RecitersLoaded(
          reciters: testReciters,
          filteredReciters: testReciters,
        );
        final RecitersLoaded newState = state.copyWith(
          favoriteIds: const {1, 3},
        );
        expect(newState.favoriteIds, const {1, 3});
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
          selectedLetter: 'A',
          showFavoritesOnly: true,
          favoriteIds: const {1, 3},
        );
        final RecitersLoaded newState = state.copyWith();
        expect(newState.reciters, testReciters);
        expect(newState.filteredReciters, testReciters);
        expect(newState.selectedLetter, 'A');
        expect(newState.showFavoritesOnly, isTrue);
        expect(newState.favoriteIds, const {1, 3});
      });

      test('should update multiple properties at once', () {
        final state = RecitersLoaded(
          reciters: testReciters,
          filteredReciters: testReciters,
        );
        final RecitersLoaded newState = state.copyWith(
          filteredReciters: [testReciter1],
          selectedLetter: 'A',
          showFavoritesOnly: true,
          favoriteIds: const {1},
        );
        expect(newState.reciters, testReciters);
        expect(newState.filteredReciters, [testReciter1]);
        expect(newState.selectedLetter, 'A');
        expect(newState.showFavoritesOnly, isTrue);
        expect(newState.favoriteIds, const {1});
      });
    });
  });

  group('RecitersError', () {
    test('should be a subclass of RecitersState', () {
      final state = RecitersError(UnexpectedFailure('Error message'));
      expect(state, isA<RecitersState>());
    });

    test('props should contain failure', () {
      final failure = UnexpectedFailure('Error message');
      final state = RecitersError(failure);
      expect(state.props, [failure]);
    });

    test('two instances with same failure should be equal', () {
      final state1 = RecitersError(UnexpectedFailure('Error message'));
      final state2 = RecitersError(UnexpectedFailure('Error message'));
      expect(state1, equals(state2));
    });

    test('two instances with different failure should not be equal', () {
      final state1 = RecitersError(UnexpectedFailure('Error 1'));
      final state2 = RecitersError(UnexpectedFailure('Error 2'));
      expect(state1, isNot(equals(state2)));
    });

    test('failure should be accessible', () {
      final failure = UnexpectedFailure('Test error');
      final state = RecitersError(failure);
      expect(state.failure, failure);
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
      final error = RecitersError(UnexpectedFailure('Error'));

      expect(initial, isNot(equals(loading)));
      expect(initial, isNot(equals(loaded)));
      expect(initial, isNot(equals(error)));
      expect(loading, isNot(equals(loaded)));
      expect(loading, isNot(equals(error)));
      expect(loaded, isNot(equals(error)));
    });
  });
}
