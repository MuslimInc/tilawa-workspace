import '../entities/tasbeeh_layout_mode.dart';

abstract class TasbeehLayoutPreferenceRepository {
  Future<TasbeehLayoutMode> getLayoutMode();

  Future<void> setLayoutMode(TasbeehLayoutMode mode);
}
