import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

import '../data/datasources/daily_guidance_local_data_source.dart';

@module
abstract class DailyGuidanceModule {
  @Named(DailyGuidanceLocalDataSource.itemsBoxName)
  @preResolve
  @lazySingleton
  Future<Box<String>> get itemsBox =>
      Hive.openBox<String>(DailyGuidanceLocalDataSource.itemsBoxName);

  @Named(DailyGuidanceLocalDataSource.recordsBoxName)
  @preResolve
  @lazySingleton
  Future<Box<String>> get recordsBox =>
      Hive.openBox<String>(DailyGuidanceLocalDataSource.recordsBoxName);
}
