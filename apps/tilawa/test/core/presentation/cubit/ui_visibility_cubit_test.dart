import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/core/presentation/cubit/ui_visibility_cubit.dart';

void main() {
  group('UiVisibilityCubit', () {
    late UiVisibilityCubit cubit;

    setUp(() {
      cubit = UiVisibilityCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is true', () {
      expect(cubit.state, isTrue);
    });

    blocTest<UiVisibilityCubit, bool>(
      'emits [false] when toggle() is called and initial state is true',
      build: () => cubit,
      act: (cubit) => cubit.toggle(),
      expect: () => [false],
    );

    blocTest<UiVisibilityCubit, bool>(
      'emits [false, true] when toggle() is called twice',
      build: () => cubit,
      act: (cubit) => cubit
        ..toggle()
        ..toggle(),
      expect: () => [false, true],
    );

    blocTest<UiVisibilityCubit, bool>(
      'emits [false] when hide() is called',
      build: () => cubit,
      act: (cubit) => cubit.hide(),
      expect: () => [false],
    );

    blocTest<UiVisibilityCubit, bool>(
      'emits [true] when show() is called after hide()',
      build: () => cubit,
      act: (cubit) => cubit
        ..hide()
        ..show(),
      expect: () => [false, true],
    );
  });
}
