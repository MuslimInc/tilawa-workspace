import 'package:injectable/injectable.dart';

import '../../domain/entities/home_layout_mode.dart';
import '../../domain/repositories/home_layout_preference_repository.dart';
import '../datasources/home_layout_preference_local_datasource.dart';

@LazySingleton(as: HomeLayoutPreferenceRepository)
class HomeLayoutPreferenceRepositoryImpl
    implements HomeLayoutPreferenceRepository {
  HomeLayoutPreferenceRepositoryImpl(this._local);

  final HomeLayoutPreferenceLocalDataSource _local;

  @override
  Future<HomeLayoutMode> getLayoutMode() => _local.readLayoutMode();

  @override
  Future<void> setLayoutMode(HomeLayoutMode mode) =>
      _local.writeLayoutMode(mode);
}
