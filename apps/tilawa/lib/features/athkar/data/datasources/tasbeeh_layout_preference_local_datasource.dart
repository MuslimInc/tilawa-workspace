import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/constants/tasbeeh_constants.dart';
import '../../domain/entities/tasbeeh_layout_mode.dart';

abstract class TasbeehLayoutPreferenceLocalDataSource {
  Future<TasbeehLayoutMode> readLayoutMode();

  Future<void> writeLayoutMode(TasbeehLayoutMode mode);
}

@LazySingleton(as: TasbeehLayoutPreferenceLocalDataSource)
class TasbeehLayoutPreferenceLocalDataSourceImpl
    implements TasbeehLayoutPreferenceLocalDataSource {
  TasbeehLayoutPreferenceLocalDataSourceImpl(this._prefs);

  final SharedPreferencesAsync _prefs;

  @override
  Future<TasbeehLayoutMode> readLayoutMode() async {
    final String? raw = await _prefs.getString(TasbeehConstants.layoutPreferenceKey);
    return TasbeehLayoutMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => TasbeehLayoutMode.list,
    );
  }

  @override
  Future<void> writeLayoutMode(TasbeehLayoutMode mode) {
    return _prefs.setString(TasbeehConstants.layoutPreferenceKey, mode.name);
  }
}
