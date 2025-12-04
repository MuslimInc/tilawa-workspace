import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muzakri/features/alphabet_scrollbar/presentation/bloc/alphabet_scrollbar_bloc.dart';
import '../../../../helpers/hydrated_bloc_test_helper.dart';

void main() {
  setUpAll(() async {
    await initializeHydratedStorageForTest();
  });

  tearDownAll(() async {
    await clearHydratedStorageForTest();
  });

  group('AlphabetScrollbarBloc', () {
    late AlphabetScrollbarBloc bloc;

    setUp(() {
      bloc = AlphabetScrollbarBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is AlphabetScrollbarInitial', () {
      expect(bloc.state, equals(const AlphabetScrollbarState()));
    });

    group('SelectLetter', () {
      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'emits AlphabetScrollbarState with selected letter when state is initial',
        build: () => bloc,
        act: (bloc) => bloc.add(const SelectLetter('أ')),
        expect: () => [const AlphabetScrollbarState(selectedLetter: 'أ')],
      );

      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'emits AlphabetScrollbarState with updated letter when state is loaded',
        build: () => bloc,
        seed: () => const AlphabetScrollbarState(selectedLetter: 'أ'),
        act: (bloc) => bloc.add(const SelectLetter('ب')),
        expect: () => [const AlphabetScrollbarState(selectedLetter: 'ب')],
      );

      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'preserves isDragging state when updating selected letter',
        build: () => bloc,
        seed: () =>
            const AlphabetScrollbarState(selectedLetter: 'أ', isDragging: true),
        act: (bloc) => bloc.add(const SelectLetter('ب')),
        expect: () => [
          const AlphabetScrollbarState(selectedLetter: 'ب', isDragging: true),
        ],
      );

      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'handles empty string letter',
        build: () => bloc,
        act: (bloc) => bloc.add(const SelectLetter('')),
        expect: () => [const AlphabetScrollbarState(selectedLetter: '')],
      );
    });

    group('ClearSelection', () {
      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'emits AlphabetScrollbarState with null selectedLetter when state is loaded',
        build: () => bloc,
        seed: () => const AlphabetScrollbarState(selectedLetter: 'أ'),
        act: (bloc) => bloc.add(const ClearSelection()),
        expect: () => [const AlphabetScrollbarState()],
      );

      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'preserves isDragging state when clearing selection',
        build: () => bloc,
        seed: () =>
            const AlphabetScrollbarState(selectedLetter: 'أ', isDragging: true),
        act: (bloc) => bloc.add(const ClearSelection()),
        expect: () => [const AlphabetScrollbarState(isDragging: true)],
      );

      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'does not emit when state is AlphabetScrollbarState',
        build: () => bloc,
        act: (bloc) => bloc.add(const ClearSelection()),
        expect: () => [const AlphabetScrollbarState()],
      );
    });

    group('StartDragging', () {
      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'emits AlphabetScrollbarState with isDragging true when state is initial',
        build: () => bloc,
        act: (bloc) => bloc.add(const StartDragging()),
        expect: () => [const AlphabetScrollbarState(isDragging: true)],
      );

      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'emits AlphabetScrollbarState with isDragging true when state is loaded',
        build: () => bloc,
        seed: () => const AlphabetScrollbarState(selectedLetter: 'أ'),
        act: (bloc) => bloc.add(const StartDragging()),
        expect: () => [
          const AlphabetScrollbarState(selectedLetter: 'أ', isDragging: true),
        ],
      );

      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'maintains isDragging true when already dragging',
        build: () => bloc,
        seed: () =>
            const AlphabetScrollbarState(selectedLetter: 'أ', isDragging: true),
        act: (bloc) => bloc.add(const StartDragging()),
        expect: () => [],
      );
    });

    group('UpdateDragLetter', () {
      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'emits AlphabetScrollbarState with updated letter when state is loaded',
        build: () => bloc,
        seed: () =>
            const AlphabetScrollbarState(selectedLetter: 'أ', isDragging: true),
        act: (bloc) => bloc.add(const UpdateDragLetter('ب')),
        expect: () => [
          const AlphabetScrollbarState(selectedLetter: 'ب', isDragging: true),
        ],
      );

      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'preserves isDragging state when updating drag letter',
        build: () => bloc,
        seed: () => const AlphabetScrollbarState(selectedLetter: 'أ'),
        act: (bloc) => bloc.add(const UpdateDragLetter('ب')),
        expect: () => [const AlphabetScrollbarState(selectedLetter: 'ب')],
      );

      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'emits when state is initial',
        build: () => bloc,
        act: (bloc) => bloc.add(const UpdateDragLetter('أ')),
        expect: () => [const AlphabetScrollbarState(selectedLetter: 'أ')],
      );
    });

    group('EndDragging', () {
      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'emits AlphabetScrollbarState with isDragging false when state is loaded',
        build: () => bloc,
        seed: () =>
            const AlphabetScrollbarState(selectedLetter: 'أ', isDragging: true),
        act: (bloc) => bloc.add(const EndDragging()),
        expect: () => [const AlphabetScrollbarState(selectedLetter: 'أ')],
      );

      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'maintains isDragging false when already not dragging',
        build: () => bloc,
        seed: () => const AlphabetScrollbarState(selectedLetter: 'أ'),
        act: (bloc) => bloc.add(const EndDragging()),
        expect: () => [],
      );

      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'emits when state is initial',
        build: () => bloc,
        act: (bloc) => bloc.add(const EndDragging()),
        expect: () => [const AlphabetScrollbarState()],
      );
    });

    group('Complex scenarios', () {
      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'handles complete drag sequence',
        build: () => bloc,
        act: (bloc) {
          bloc.add(const SelectLetter('أ'));
          bloc.add(const StartDragging());
          bloc.add(const UpdateDragLetter('ب'));
          bloc.add(const UpdateDragLetter('ت'));
          bloc.add(const EndDragging());
        },
        expect: () => [
          const AlphabetScrollbarState(selectedLetter: 'أ'),
          const AlphabetScrollbarState(selectedLetter: 'أ', isDragging: true),
          const AlphabetScrollbarState(selectedLetter: 'ب', isDragging: true),
          const AlphabetScrollbarState(selectedLetter: 'ت', isDragging: true),
          const AlphabetScrollbarState(selectedLetter: 'ت'),
        ],
      );

      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'handles multiple select operations',
        build: () => bloc,
        act: (bloc) {
          bloc.add(const SelectLetter('أ'));
          bloc.add(const SelectLetter('ب'));
          bloc.add(const SelectLetter('ت'));
          bloc.add(const ClearSelection());
          bloc.add(const SelectLetter('ث'));
        },
        expect: () => [
          const AlphabetScrollbarState(selectedLetter: 'أ'),
          const AlphabetScrollbarState(selectedLetter: 'ب'),
          const AlphabetScrollbarState(selectedLetter: 'ت'),
          const AlphabetScrollbarState(),
          const AlphabetScrollbarState(selectedLetter: 'ث'),
        ],
      );

      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'handles rapid state changes',
        build: () => bloc,
        act: (bloc) {
          bloc.add(const StartDragging());
          bloc.add(const SelectLetter('أ'));
          bloc.add(const UpdateDragLetter('ب'));
          bloc.add(const EndDragging());
          bloc.add(const ClearSelection());
        },
        expect: () => [
          const AlphabetScrollbarState(isDragging: true),
          const AlphabetScrollbarState(selectedLetter: 'أ', isDragging: true),
          const AlphabetScrollbarState(selectedLetter: 'ب', isDragging: true),
          const AlphabetScrollbarState(selectedLetter: 'ب'),
          const AlphabetScrollbarState(),
        ],
      );
    });

    group('Edge cases', () {
      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'handles null selectedLetter in loaded state',
        build: () => bloc,
        seed: () => const AlphabetScrollbarState(),
        act: (bloc) => bloc.add(const SelectLetter('أ')),
        expect: () => [const AlphabetScrollbarState(selectedLetter: 'أ')],
      );

      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'handles same letter selection',
        build: () => bloc,
        seed: () => const AlphabetScrollbarState(selectedLetter: 'أ'),
        act: (bloc) => bloc.add(const SelectLetter('أ')),
        expect: () => [],
      );

      blocTest<AlphabetScrollbarBloc, AlphabetScrollbarState>(
        'handles clear selection when already null',
        build: () => bloc,
        seed: () => const AlphabetScrollbarState(),
        act: (bloc) => bloc.add(const ClearSelection()),
        expect: () => [],
      );
    });
  });
}
