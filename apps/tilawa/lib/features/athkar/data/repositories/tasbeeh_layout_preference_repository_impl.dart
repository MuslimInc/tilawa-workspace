import 'package:injectable/injectable.dart';

import '../../domain/entities/tasbeeh_layout_mode.dart';
import '../../domain/repositories/tasbeeh_layout_preference_repository.dart';
import '../datasources/tasbeeh_layout_preference_local_datasource.dart';

@LazySingleton(as: TasbeehLayoutPreferenceRepository)
class TasbeehLayoutPreferenceRepositoryImpl
    implements TasbeehLayoutPreferenceRepository {
  TasbeehLayoutPreferenceRepositoryImpl(this._local);

  final TasbeehLayoutPreferenceLocalDataSource _local;

  @override
  Future<TasbeehLayoutMode> getLayoutMode() => _local.readLayoutMode();

  @override
  Future<void> setLayoutMode(TasbeehLayoutMode mode) =>
      _local.writeLayoutMode(mode);
}
