import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:tilawa/core/services/hive_readiness.dart';
import 'package:tilawa/features/daily_guidance/data/datasources/daily_guidance_local_data_source.dart';
import 'package:tilawa/features/daily_guidance/data/datasources/daily_guidance_seed_data_source.dart';
import 'package:tilawa/features/daily_guidance/data/repositories/daily_guidance_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('corrupt cached content fails with a typed parsing exception', () async {
    final directory = await Directory.systemTemp.createTemp('daily_guidance_');
    Hive.init(directory.path);
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    final box = await Hive.openBox<String>(
      DailyGuidanceLocalDataSource.itemsBoxName,
    );
    await box.put('corrupt', '{not-json');
    final dataSource = DailyGuidanceLocalDataSource(
      Hive,
      const _ReadyHive(),
    );

    await check(dataSource.getItems()).throws<DailyGuidanceParsingException>();
  });

  test('refresh replaces corrupt cache with trusted seed content', () async {
    final directory = await Directory.systemTemp.createTemp('daily_guidance_');
    Hive.init(directory.path);
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    final box = await Hive.openBox<String>(
      DailyGuidanceLocalDataSource.itemsBoxName,
    );
    await box.put('corrupt', '{not-json');
    final dataSource = DailyGuidanceLocalDataSource(
      Hive,
      const _ReadyHive(),
    );
    final repository = DailyGuidanceRepositoryImpl(
      dataSource,
      DailyGuidanceSeedDataSource(),
    );

    check(await repository.refreshContent()).equals(6);
    check(await dataSource.getItems()).length.equals(6);
  });
}

class _ReadyHive implements HiveReadiness {
  const _ReadyHive();

  @override
  Future<void> ensureReady() async {}
}
