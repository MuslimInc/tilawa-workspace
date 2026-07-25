import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa/features/app_review/data/config/app_review_store_config.dart';
import 'package:tilawa_core/errors/failures.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_review_platform_data_source.dart';

/// Default provider using [`in_app_review`](https://pub.dev/packages/in_app_review).
///
/// Alternative: implement [AppReviewPlatformDataSource] with
/// [`app_review`](https://pub.dev/packages/app_review) and rebind in DI.
@LazySingleton(as: AppReviewPlatformDataSource)
class InAppReviewPlatformDataSource implements AppReviewPlatformDataSource {
  InAppReviewPlatformDataSource(
    this._review, {
    @ignoreParam Future<bool> Function(Uri uri)? launchUrlFn,
  }) : _launchUrl = launchUrlFn ?? _launchStoreUrlPreferNative;

  final InAppReview _review;
  final Future<bool> Function(Uri uri) _launchUrl;

  static const String _logName = 'tilawa.app_review';

  /// Prefer the native store app; fall back to the browser / generic handler.
  static Future<bool> _launchStoreUrlPreferNative(Uri uri) async {
    try {
      if (await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      )) {
        return true;
      }
    } on Object {
      // Native store unavailable; try browser / external handler.
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final bool available = await _review.isAvailable();
      developer.log(
        'isAvailable=$available',
        name: _logName,
      );
      return available;
    } on Object catch (e, stackTrace) {
      developer.log(
        'isAvailable check failed',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
        level: 900,
      );
      return false;
    }
  }

  @override
  Future<void> requestReview() async {
    try {
      await _review.requestReview();
      developer.log('requestReview completed', name: _logName);
    } on Object catch (e, stackTrace) {
      developer.log(
        'requestReview failed',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
        level: 900,
      );
      throw AppReviewFailure.requestFailed(e.toString());
    }
  }

  @override
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
    String? androidPackageId,
    bool writeReview = false,
  }) async {
    if (kIsWeb) {
      throw const AppReviewFailure.platformUnsupported();
    }

    // in_app_review Android path uses the running applicationId, so flavor
    // suffixes (.dev / .staging) open unpublished listings. Always deep-link
    // the production Play package instead.
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _openStoreUri(
        AppReviewStoreConfig.playStoreListingUriFor(androidPackageId),
      );
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final Uri uri = writeReview
          ? AppReviewStoreConfig.appStoreWriteReviewUriFor(appStoreId)
          : AppReviewStoreConfig.appStoreListingUriFor(appStoreId);
      await _openStoreUri(uri);
      return;
    }

    throw const AppReviewFailure.platformUnsupported();
  }

  Future<void> _openStoreUri(Uri uri) async {
    try {
      final bool launched = await _launchUrl(uri);
      if (!launched) {
        throw const AppReviewFailure.storeListingFailed(
          'Could not open store listing',
        );
      }
      developer.log(
        'openStoreListing opened $uri',
        name: _logName,
      );
    } on AppReviewFailure {
      rethrow;
    } on Object catch (e, stackTrace) {
      developer.log(
        'openStoreListing failed',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
        level: 900,
      );
      throw AppReviewFailure.storeListingFailed(e.toString());
    }
  }
}
