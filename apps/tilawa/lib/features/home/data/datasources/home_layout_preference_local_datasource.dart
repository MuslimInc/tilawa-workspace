import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/constants/home_layout_constants.dart';
import '../../domain/entities/home_layout_mode.dart';

abstract class HomeLayoutPreferenceLocalDataSource {
  Future<HomeLayoutMode> readLayoutMode();

  Future<void> writeLayoutMode(HomeLayoutMode mode);
}

@LazySingleton(as: HomeLayoutPreferenceLocalDataSource)
class HomeLayoutPreferenceLocalDataSourceImpl
    implements HomeLayoutPreferenceLocalDataSource {
  HomeLayoutPreferenceLocalDataSourceImpl(this._prefs);

  final SharedPreferencesAsync _prefs;

  @override
  Future<HomeLayoutMode> readLayoutMode() async {
    final String? raw = await _prefs.getString(
      HomeLayoutConstants.layoutPreferenceKey,
    );
    return HomeLayoutMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => HomeLayoutMode.list,
    );
  }

  @override
  Future<void> writeLayoutMode(HomeLayoutMode mode) {
    return _prefs.setString(HomeLayoutConstants.layoutPreferenceKey, mode.name);
  }
}
