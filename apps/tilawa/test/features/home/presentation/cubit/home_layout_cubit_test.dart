import 'package:flutter_test/flutter_test.dart';
import 'package:tilawa/features/home/domain/entities/home_layout_mode.dart';
import 'package:tilawa/features/home/domain/repositories/home_layout_preference_repository.dart';
import 'package:tilawa/features/home/domain/usecases/get_home_layout_mode_use_case.dart';
import 'package:tilawa/features/home/domain/usecases/set_home_layout_mode_use_case.dart';
import 'package:tilawa/features/home/presentation/cubit/home_layout_cubit.dart';

class _FakeHomeLayoutPreferenceRepository
    implements HomeLayoutPreferenceRepository {
  HomeLayoutMode mode = HomeLayoutMode.grid;

  @override
  Future<HomeLayoutMode> getLayoutMode() async => mode;

  @override
  Future<void> setLayoutMode(HomeLayoutMode mode) async {
    this.mode = mode;
  }
}

void main() {
  group('HomeLayoutCubit', () {
    late _FakeHomeLayoutPreferenceRepository repository;

    HomeLayoutCubit buildCubit() {
      return HomeLayoutCubit(
        GetHomeLayoutModeUseCase(repository),
        SetHomeLayoutModeUseCase(repository),
      );
    }

    setUp(() {
      repository = _FakeHomeLayoutPreferenceRepository();
    });

    test('load restores persisted layout mode', () async {
      repository.mode = HomeLayoutMode.grid;
      final cubit = buildCubit();

      await pumpEventQueue();

      expect(cubit.state.mode, HomeLayoutMode.grid);
      await cubit.close();
    });

    test('toggleLayoutMode switches between list and grid', () async {
      final cubit = buildCubit();
      await pumpEventQueue();

      expect(cubit.state.mode, HomeLayoutMode.grid);

      await cubit.toggleLayoutMode();
      expect(cubit.state.mode, HomeLayoutMode.list);
      expect(repository.mode, HomeLayoutMode.list);

      await cubit.toggleLayoutMode();
      expect(cubit.state.mode, HomeLayoutMode.grid);

      await cubit.close();
    });
  });
}
