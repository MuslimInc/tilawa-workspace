import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:quran_image/domain/repositories/quran_image_cache_repository.dart';
import 'package:quran_image/domain/usecases/prepare_quran_image_cache.dart';
import 'package:quran_qcf/quran_qcf.dart';

import '../logging/app_logger.dart';
import 'quran_assets_prefetch_policy_service.dart';

enum _QuranAssetKind { images, fonts }

/// Best-effort background preparation for large Quran asset bundles.
class QuranAssetsPrefetchService {
  QuranAssetsPrefetchService({
    required Connectivity connectivity,
    required PrepareQuranImageCacheUseCase prepareQuranImageCacheUseCase,
    required QuranImageCacheRepository imageCacheRepository,
    required QuranFontService quranFontService,
    required QuranAssetsPrefetchPolicyService policyService,
  }) : _connectivity = connectivity,
       _prepareQuranImageCacheUseCase = prepareQuranImageCacheUseCase,
       _imageCacheRepository = imageCacheRepository,
       _quranFontService = quranFontService,
       _policyService = policyService;

  final Connectivity _connectivity;
  final PrepareQuranImageCacheUseCase _prepareQuranImageCacheUseCase;
  final QuranImageCacheRepository _imageCacheRepository;
  final QuranFontService _quranFontService;
  final QuranAssetsPrefetchPolicyService _policyService;

  final Set<_QuranAssetKind> _completedAssets = <_QuranAssetKind>{};
  Future<void>? _inFlightPrefetch;

  Future<void> prefetchInBackground() {
    final Future<void>? inFlight = _inFlightPrefetch;
    if (inFlight != null) return inFlight;

    final Future<void> prefetchFuture = _prefetchEligibleAssets().whenComplete(
      () => _inFlightPrefetch = null,
    );
    _inFlightPrefetch = prefetchFuture;
    return prefetchFuture;
  }

  Future<void> _prefetchEligibleAssets() async {
    final List<ConnectivityResult> connectivityResults = await _connectivity
        .checkConnectivity();

    if (!_hasAnyNetworkConnection(connectivityResults)) {
      logger.d('[QuranAssetsPrefetch] skipped reason=offline');
      return;
    }

    if (!await _allowsCurrentConnection(connectivityResults)) {
      logger.d('[QuranAssetsPrefetch] skipped reason=wifi-only-policy');
      return;
    }

    await _prefetchImagesIfNeeded();
    await _prefetchFontsIfNeeded();
  }

  bool _hasAnyNetworkConnection(List<ConnectivityResult> connectivityResults) {
    return !connectivityResults.contains(ConnectivityResult.none);
  }

  Future<bool> _allowsCurrentConnection(
    List<ConnectivityResult> connectivityResults,
  ) async {
    final bool wifiOnlyEnabled = await _policyService.isWifiOnlyEnabled();
    if (!wifiOnlyEnabled) return true;

    final Set<ConnectivityResult> connectionSet = connectivityResults.toSet();
    return connectionSet.contains(ConnectivityResult.wifi) ||
        connectionSet.contains(ConnectivityResult.ethernet);
  }

  Future<void> _prefetchImagesIfNeeded() async {
    if (_completedAssets.contains(_QuranAssetKind.images)) return;

    if (_imageCacheRepository.status.isReady) {
      _completedAssets.add(_QuranAssetKind.images);
      logger.d('[QuranAssetsPrefetch] images already ready');
      return;
    }

    logger.d('[QuranAssetsPrefetch] images prepare started');
    final status = await _prepareQuranImageCacheUseCase();
    if (status.isReady) {
      _completedAssets.add(_QuranAssetKind.images);
      logger.d('[QuranAssetsPrefetch] images prepare completed');
    } else {
      logger.d(
        '[QuranAssetsPrefetch] images prepare incomplete '
        'phase=${status.phase.name} error=${status.errorMessage}',
      );
    }
  }

  Future<void> _prefetchFontsIfNeeded() async {
    if (_completedAssets.contains(_QuranAssetKind.fonts)) return;

    if (await _quranFontService.areFontsDownloaded()) {
      _completedAssets.add(_QuranAssetKind.fonts);
      logger.d('[QuranAssetsPrefetch] fonts already ready');
      return;
    }

    logger.d('[QuranAssetsPrefetch] fonts download started');
    await _quranFontService.downloadFonts();

    if (await _quranFontService.areFontsDownloaded()) {
      _completedAssets.add(_QuranAssetKind.fonts);
      logger.d('[QuranAssetsPrefetch] fonts download completed');
    } else {
      logger.d('[QuranAssetsPrefetch] fonts download incomplete');
    }
  }
}
