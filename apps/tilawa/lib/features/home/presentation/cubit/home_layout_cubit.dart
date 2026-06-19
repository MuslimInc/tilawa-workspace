import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/usecases/usecase.dart';

import '../../domain/entities/home_layout_mode.dart';
import '../../domain/usecases/get_home_layout_mode_use_case.dart';
import '../../domain/usecases/set_home_layout_mode_use_case.dart';
import 'home_layout_state.dart';

@injectable
class HomeLayoutCubit extends Cubit<HomeLayoutState> {
  HomeLayoutCubit(this._getLayoutMode, this._setLayoutMode)
    : super(const HomeLayoutState()) {
    load();
  }

  final GetHomeLayoutModeUseCase _getLayoutMode;
  final SetHomeLayoutModeUseCase _setLayoutMode;

  Future<void> load() async {
    final result = await _getLayoutMode(const NoParams());
    emit(
      state.copyWith(
        mode: result.getOrElse(() => HomeLayoutMode.list),
      ),
    );
  }

  Future<void> toggleLayoutMode() async {
    final HomeLayoutMode next = state.mode == HomeLayoutMode.list
        ? HomeLayoutMode.grid
        : HomeLayoutMode.list;
    final result = await _setLayoutMode(next);
    result.fold((_) {}, (_) => emit(state.copyWith(mode: next)));
  }
}
