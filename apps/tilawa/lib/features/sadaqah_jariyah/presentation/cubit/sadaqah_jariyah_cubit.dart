import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa_core/constants/analytics_constants.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:tilawa_core/services/analytics_service.dart';

import '../../domain/entities/dedication.dart';
import '../../domain/entities/sadaqah_jariyah_page_data.dart';
import '../../domain/services/dedication_photo_url_resolver.dart';
import '../../domain/usecases/get_sadaqah_jariyah_page_use_case.dart';
import 'sadaqah_jariyah_state.dart';

class SadaqahJariyahCubit extends Cubit<SadaqahJariyahState> {
  SadaqahJariyahCubit(
    this._getPage,
    this._photoUrlResolver,
    this._analytics,
  ) : super(const SadaqahJariyahInitial());

  final GetSadaqahJariyahPageUseCase _getPage;
  final DedicationPhotoUrlResolver _photoUrlResolver;
  final AnalyticsService _analytics;
  int _loadGeneration = 0;

  static const Duration _photoResolutionTimeout = Duration(seconds: 5);

  Future<void> load() async {
    final int generation = ++_loadGeneration;
    emit(const SadaqahJariyahLoading());
    final result = await _getPage(const GetSadaqahJariyahPageParams());
    await result.foldAsync(
      (Failure failure) async {
        emit(SadaqahJariyahError(failure));
      },
      (SadaqahJariyahPageData pageData) async {
        emit(
          SadaqahJariyahLoaded(
            pageData: pageData,
            photoUrls: const <String, String?>{},
          ),
        );
        if (pageData.config.featureEnabled) {
          unawaited(_resolvePhotoUrls(pageData, generation));
        }
        await _analytics.logEvent(AnalyticsEvents.sadaqahJariyahScreenViewed);
      },
    );
  }

  Future<void> _resolvePhotoUrls(
    SadaqahJariyahPageData pageData,
    int generation,
  ) async {
    final List<MapEntry<String, String?>> resolved = await Future.wait(
      pageData.dedications.map((Dedication dedication) async {
        final String? url = await _photoUrlResolver
            .resolveDownloadUrl(dedication.photoStoragePath)
            .timeout(_photoResolutionTimeout, onTimeout: () => null);
        return MapEntry<String, String?>(dedication.id, url);
      }),
    );
    if (isClosed || generation != _loadGeneration) {
      return;
    }
    emit(
      SadaqahJariyahLoaded(
        pageData: pageData,
        photoUrls: Map<String, String?>.fromEntries(resolved),
      ),
    );
  }
}
