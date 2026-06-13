import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:tilawa/features/athkar/data/datasources/tasbeeh_local_datasource.dart';
import 'package:tilawa/features/athkar/data/models/tasbeeh_dhikr_model.dart';
import 'package:tilawa/features/athkar/data/repositories/tasbeeh_repository_impl.dart';
import 'package:tilawa/features/athkar/domain/constants/tasbeeh_constants.dart';

import '../../../../core/helpers/fake_hive_readiness.dart';

TasbeehDhikrModel _model({
  required String id,
  required String text,
  int count = 0,
  DateTime? updatedAt,
}) {
  final DateTime timestamp = updatedAt ?? DateTime(2026, 6, 10);
  return TasbeehDhikrModel(
    id: id,
    text: text,
    count: count,
    targetCount: 10,
    targetReachedNotified: false,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

void main() {
  late TasbeehLocalDataSourceImpl dataSource;
  late FakeHiveReadiness hiveReadiness;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => '.',
        );
    Hive.init('.');
  });

  setUp(() {
    hiveReadiness = FakeHiveReadiness()..release();
    dataSource = TasbeehLocalDataSourceImpl(Hive, hiveReadiness);
  });

  tearDown(() async {
    if (Hive.isBoxOpen(TasbeehConstants.storageBoxName)) {
      await Hive.box(TasbeehConstants.storageBoxName).clear();
      await Hive.box(TasbeehConstants.storageBoxName).close();
    }
  });

  group('hive readiness gate', () {
    test('waits for hive readiness before reading saved dhikr', () async {
      final box = await Hive.openBox(TasbeehConstants.storageBoxName);
      await box.put('abc', jsonEncode(_model(id: 'abc', text: 'abc').toJson()));
      await box.close();

      hiveReadiness = FakeHiveReadiness();
      dataSource = TasbeehLocalDataSourceImpl(Hive, hiveReadiness);

      final Future<List<TasbeehDhikrModel>> loadFuture = dataSource
          .getAllDhikr();
      await Future<void>.delayed(Duration.zero);

      expect(hiveReadiness.ensureReadyCallCount, 1);

      var completed = false;
      loadFuture.then((_) => completed = true);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(completed, isFalse);

      hiveReadiness.release();
      final items = await loadFuture;

      expect(items, hasLength(1));
      expect(items.single.text, 'abc');
    });

    test('calls ensureReady on every box access', () async {
      final immediate = ImmediateHiveReadiness();
      dataSource = TasbeehLocalDataSourceImpl(Hive, immediate);

      await dataSource.saveDhikr(_model(id: '1', text: 'one'));
      await dataSource.getDhikrById('1');
      await dataSource.deleteDhikr('1');

      expect(immediate.ensureReadyCallCount, greaterThanOrEqualTo(3));
    });
  });

  group('CRUD', () {
    test('getAllDhikr returns items sorted by updatedAt descending', () async {
      await dataSource.saveDhikr(
        _model(
          id: 'older',
          text: 'older',
          updatedAt: DateTime(2026, 1, 1),
        ),
      );
      await dataSource.saveDhikr(
        _model(
          id: 'newer',
          text: 'newer',
          updatedAt: DateTime(2026, 6, 10),
        ),
      );

      final items = await dataSource.getAllDhikr();

      expect(items.map((e) => e.id).toList(), <String>['newer', 'older']);
    });

    test('getDhikrById returns null when missing', () async {
      expect(await dataSource.getDhikrById('missing'), isNull);
    });

    test('saveDhikr persists and getDhikrById reads back', () async {
      final model = _model(id: 'saved', text: 'Subhan Allah', count: 2);
      await dataSource.saveDhikr(model);

      final loaded = await dataSource.getDhikrById('saved');
      expect(loaded?.text, 'Subhan Allah');
      expect(loaded?.count, 2);
    });

    test('deleteDhikr removes a single item', () async {
      await dataSource.saveDhikr(_model(id: 'keep', text: 'keep'));
      await dataSource.saveDhikr(_model(id: 'drop', text: 'drop'));

      await dataSource.deleteDhikr('drop');

      final items = await dataSource.getAllDhikr();
      expect(items.map((e) => e.id), <String>['keep']);
    });

    test('deleteAllDhikr clears the box', () async {
      await dataSource.saveDhikr(_model(id: '1', text: 'one'));
      await dataSource.saveDhikr(_model(id: '2', text: 'two'));

      await dataSource.deleteAllDhikr();

      expect(await dataSource.getAllDhikr(), isEmpty);
    });

    test('reuses an already open box', () async {
      await dataSource.saveDhikr(_model(id: 'open', text: 'open'));
      expect(Hive.isBoxOpen(TasbeehConstants.storageBoxName), isTrue);

      final loaded = await dataSource.getDhikrById('open');
      expect(loaded?.text, 'open');
    });
  });

  group('cold start integration', () {
    test(
      'repository returns saved dhikr after hive readiness is released',
      () async {
        final writer = TasbeehLocalDataSourceImpl(
          Hive,
          ImmediateHiveReadiness(),
        );
        await writer.saveDhikr(_model(id: 'abc', text: 'abc', count: 1));

        final delayedReadiness = FakeHiveReadiness();
        final repository = TasbeehRepositoryImpl(
          TasbeehLocalDataSourceImpl(Hive, delayedReadiness),
        );

        final Future<dynamic> loadFuture = repository.getSavedDhikr();
        await Future<void>.delayed(Duration.zero);
        expect(delayedReadiness.ensureReadyCallCount, 1);

        delayedReadiness.release();
        final result = await loadFuture;

        expect(result.isRight, isTrue);
        result.fold(
          (_) => fail('expected saved dhikr'),
          (items) {
            expect(items, hasLength(1));
            expect(items.single.text, 'abc');
            expect(items.single.count, 1);
          },
        );
      },
    );
  });
}
