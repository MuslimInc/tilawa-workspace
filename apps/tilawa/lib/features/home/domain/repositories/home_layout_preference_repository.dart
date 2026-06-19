import '../entities/home_layout_mode.dart';

abstract class HomeLayoutPreferenceRepository {
  Future<HomeLayoutMode> getLayoutMode();

  Future<void> setLayoutMode(HomeLayoutMode mode);
}
