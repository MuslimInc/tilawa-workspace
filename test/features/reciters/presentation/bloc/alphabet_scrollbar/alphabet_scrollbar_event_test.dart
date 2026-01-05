import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/reciters/presentation/bloc/alphabet_scrollbar/alphabet_scrollbar_bloc.dart';

void main() {
  group('AlphabetScrollbarEvent', () {
    group('SelectLetter', () {
      test('supports value equality', () {
        expect(const SelectLetter('A'), equals(const SelectLetter('A')));
      });

      test('props are correct', () {
        expect(const SelectLetter('A').props, equals(['A']));
      });
    });

    group('ClearSelection', () {
      test('supports value equality', () {
        expect(const ClearSelection(), equals(const ClearSelection()));
      });

      test('props are correct', () {
        expect(const ClearSelection().props, equals([]));
      });
    });

    group('StartDragging', () {
      test('supports value equality', () {
        expect(const StartDragging(), equals(const StartDragging()));
      });

      test('props are correct', () {
        expect(const StartDragging().props, equals([]));
      });
    });

    group('UpdateDragLetter', () {
      test('supports value equality', () {
        expect(
          const UpdateDragLetter('B'),
          equals(const UpdateDragLetter('B')),
        );
      });

      test('props are correct', () {
        expect(const UpdateDragLetter('B').props, equals(['B']));
      });
    });

    group('EndDragging', () {
      test('supports value equality', () {
        expect(const EndDragging(), equals(const EndDragging()));
      });

      test('props are correct', () {
        expect(const EndDragging().props, equals([]));
      });
    });
  });
}
