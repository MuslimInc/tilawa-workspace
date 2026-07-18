import 'dart:io';

import 'package:dartz_plus/dartz_plus.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/utils/typedefs.dart';

import '../../domain/entities/reel.dart';
import '../../domain/entities/reel_category.dart';
import '../../domain/entities/reel_engagement.dart';
import '../../domain/entities/reel_reaction.dart';
import '../../domain/repositories/reels_repository.dart';
import '../datasources/reels_local_datasource.dart';
import '../datasources/reels_remote_datasource.dart';
import '../models/reel_video_dto_mapper.dart';
import '../services/reels_analytics.dart';

@LazySingleton(as: ReelsRepository)
class ReelsRepositoryImpl implements ReelsRepository {
  ReelsRepositoryImpl(
    this._remote,
    this._local,
    this._dio,
    this._analytics,
  );

  final ReelsRemoteDataSource _remote;
  final ReelsLocalDataSource _local;
  final Dio _dio;
  final ReelsAnalytics _analytics;

  /// Known mp3quran video_type ids (API returns Arabic even for eng).
  static const Set<int> knownCategoryIds = {2, 3, 4};

  @override
  ResultFuture<List<Reel>> getReels({required String language}) async {
    try {
      final sheikhs = await _remote.fetchVideos(language: language);
      final savedIds = await _local.getSavedIds();
      final reactions = await _local.getReactions();
      final reels = sheikhs
          .expand((s) => s.toReels())
          .map(
            (r) => r.copyWith(
              isSaved: savedIds.contains(r.id),
              reaction: reactions[r.id],
            ),
          )
          .toList();
      return Right(reels);
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<ReelCategory>> getCategories({
    required String language,
  }) async {
    try {
      final types = await _remote.fetchVideoTypes(language: language);
      // Prefer known ids; ignore unknown. Labels filled by presentation l10n.
      final categories = <ReelCategory>[
        for (final t in types)
          if (knownCategoryIds.contains(t.id))
            ReelCategory(id: t.id, label: t.videoType),
      ];
      // Ensure all known ids exist even if API omits one.
      for (final id in knownCategoryIds) {
        if (!categories.any((c) => c.id == id)) {
          categories.add(ReelCategory(id: id, label: ''));
        }
      }
      categories.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
      return Right(categories);
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<Reel>> getSavedReels() async {
    try {
      final list = await _local.getSavedReels();
      return Right(list);
    } on Object catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> saveReel(Reel reel) async {
    try {
      await _local.saveReel(reel);
      final engagement =
          (await _local.getEngagementMap())[reel.id] ?? const ReelEngagement();
      await _local.saveEngagement(
        reel.id,
        engagement.copyWith(saves: engagement.saves + 1),
      );
      await _analytics.save(reel.id, saved: true);
      return const Right(null);
    } on Object catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> removeSavedReel(int reelId) async {
    try {
      await _local.removeSavedReel(reelId);
      await _analytics.save(reelId, saved: false);
      return const Right(null);
    } on Object catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<ReelReaction?> reactToReel(
    int reelId,
    ReelReaction reaction,
  ) async {
    try {
      final current = (await _local.getReactions())[reelId];
      final ReelReaction? next = current == reaction ? null : reaction;
      await _local.setReaction(reelId, next);

      if (next != null) {
        final engagement =
            (await _local.getEngagementMap())[reelId] ?? const ReelEngagement();
        final counts = Map<ReelReaction, int>.of(engagement.reactionCounts);
        counts[next] = (counts[next] ?? 0) + 1;
        await _local.saveEngagement(
          reelId,
          engagement.copyWith(reactionCounts: counts),
        );
        await _analytics.reaction(reelId, next);
      }
      return Right(next);
    } on Object catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> shareReel(
    Reel reel, {
    required ReelShareMode mode,
  }) async {
    try {
      final text =
          '${reel.sheikhName}\n${reel.videoUrl}\n\nShared via MeMuslim';
      switch (mode) {
        case ReelShareMode.link:
        case ReelShareMode.text:
          await SharePlus.instance.share(ShareParams(text: text));
        case ReelShareMode.file:
          final file = await _downloadTemp(reel);
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path, mimeType: 'video/mp4')],
              text: text,
            ),
          );
          try {
            await file.delete();
          } catch (_) {}
      }
      final engagement =
          (await _local.getEngagementMap())[reel.id] ?? const ReelEngagement();
      await _local.saveEngagement(
        reel.id,
        engagement.copyWith(shares: engagement.shares + 1),
      );
      await _analytics.share(reel.id, mode);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } on Object catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> recordView(int reelId, ReelViewKind kind) async {
    try {
      final engagement =
          (await _local.getEngagementMap())[reelId] ?? const ReelEngagement();
      switch (kind) {
        case ReelViewKind.started:
          await _local.saveEngagement(
            reelId,
            engagement.copyWith(viewsStarted: engagement.viewsStarted + 1),
          );
          await _analytics.viewStarted(reelId);
        case ReelViewKind.completed:
          await _local.saveEngagement(
            reelId,
            engagement.copyWith(
              viewsCompleted: engagement.viewsCompleted + 1,
            ),
          );
          await _analytics.viewCompleted(reelId);
      }
      return const Right(null);
    } on Object catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Map<int, ReelEngagement>> getEngagementMap() async {
    try {
      return Right(await _local.getEngagementMap());
    } on Object catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  ResultFuture<Map<int, ReelReaction>> getReactions() async {
    try {
      return Right(await _local.getReactions());
    } on Object catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<File> _downloadTemp(Reel reel) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'reel_${reel.id}.mp4'));
    await _dio.download(reel.videoUrl, file.path);
    return file;
  }

  Failure _mapDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkFailure('timeout');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure('offline');
    }
    return ServerFailure(e.message);
  }
}
