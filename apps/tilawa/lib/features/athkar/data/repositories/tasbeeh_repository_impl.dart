import 'package:dartz_plus/dartz_plus.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../../domain/constants/tasbeeh_constants.dart';
import '../../domain/entities/tasbeeh_dhikr.dart';
import '../../domain/repositories/tasbeeh_repository.dart';
import '../datasources/tasbeeh_local_datasource.dart';
import '../models/tasbeeh_dhikr_model.dart';

class TasbeehRepositoryImpl implements TasbeehRepository {
  TasbeehRepositoryImpl(this._localDataSource);

  final TasbeehLocalDataSource _localDataSource;

  @override
  ResultFuture<List<TasbeehDhikr>> getSavedDhikr() async {
    try {
      final items = await _localDataSource.getAllDhikr();
      return Right(items);
    } catch (e) {
      return Left(PersistenceFailure(e.toString()));
    }
  }

  @override
  ResultFuture<TasbeehDhikr> saveCustomDhikr({
    required String text,
    required int targetCount,
  }) async {
    final normalized = text.trim();
    if (normalized.length < TasbeehConstants.minTextLength) {
      return const Left(ValidationFailure('Tasbeeh text is required'));
    }
    if (normalized.length > TasbeehConstants.maxTextLength) {
      return const Left(ValidationFailure('Tasbeeh text is too long'));
    }
    if (targetCount < TasbeehConstants.minTargetCount ||
        targetCount > TasbeehConstants.maxTargetCount) {
      return const Left(ValidationFailure('Tasbeeh target is out of range'));
    }

    try {
      final existing = await _localDataSource.getAllDhikr();
      final duplicated = existing.where(
        (item) => item.text.toLowerCase() == normalized.toLowerCase(),
      );

      if (duplicated.isNotEmpty) {
        return Right(duplicated.first);
      }

      final now = DateTime.now();
      final model = TasbeehDhikrModel(
        id: now.microsecondsSinceEpoch.toString(),
        text: normalized,
        count: 0,
        targetCount: targetCount,
        targetReachedNotified: false,
        createdAt: now,
        updatedAt: now,
      );
      await _localDataSource.saveDhikr(model);
      return Right(model);
    } catch (e) {
      return Left(PersistenceFailure(e.toString()));
    }
  }

  @override
  ResultFuture<TasbeehDhikr> incrementCount(String dhikrId) async {
    try {
      final existing = await _localDataSource.getDhikrById(dhikrId);
      if (existing == null) {
        return const Left(CacheFailure('Tasbeeh item was not found'));
      }

      final updated = existing.copyWith(
        count: existing.count + 1,
        targetReachedNotified:
            existing.targetReachedNotified ||
            (!existing.targetReachedNotified &&
                existing.count < existing.targetCount &&
                (existing.count + 1) >= existing.targetCount),
        updatedAt: DateTime.now(),
      );
      await _localDataSource.saveDhikr(updated);
      return Right(updated);
    } catch (e) {
      return Left(PersistenceFailure(e.toString()));
    }
  }

  @override
  ResultFuture<TasbeehDhikr> resetCount(String dhikrId) async {
    try {
      final existing = await _localDataSource.getDhikrById(dhikrId);
      if (existing == null) {
        return const Left(CacheFailure('Tasbeeh item was not found'));
      }

      final updated = existing.copyWith(count: 0, updatedAt: DateTime.now());
      final reset = updated.copyWith(targetReachedNotified: false);
      await _localDataSource.saveDhikr(reset);
      return Right(reset);
    } catch (e) {
      return Left(PersistenceFailure(e.toString()));
    }
  }

  @override
  ResultFuture<TasbeehDhikr> setTargetCount({
    required String dhikrId,
    required int targetCount,
  }) async {
    if (targetCount < TasbeehConstants.minTargetCount ||
        targetCount > TasbeehConstants.maxTargetCount) {
      return const Left(ValidationFailure('Tasbeeh target is out of range'));
    }

    try {
      final existing = await _localDataSource.getDhikrById(dhikrId);
      if (existing == null) {
        return const Left(CacheFailure('Tasbeeh item was not found'));
      }

      final bool alreadyReached = existing.count >= targetCount;
      final updated = existing.copyWith(
        targetCount: targetCount,
        targetReachedNotified: alreadyReached,
        updatedAt: DateTime.now(),
      );
      await _localDataSource.saveDhikr(updated);
      return Right(updated);
    } catch (e) {
      return Left(PersistenceFailure(e.toString()));
    }
  }

  @override
  ResultVoid deleteDhikr(String dhikrId) async {
    try {
      final existing = await _localDataSource.getDhikrById(dhikrId);
      if (existing == null) {
        return const Left(CacheFailure('Tasbeeh item was not found'));
      }
      await _localDataSource.deleteDhikr(dhikrId);
      return const Right(null);
    } catch (e) {
      return Left(PersistenceFailure(e.toString()));
    }
  }
}
