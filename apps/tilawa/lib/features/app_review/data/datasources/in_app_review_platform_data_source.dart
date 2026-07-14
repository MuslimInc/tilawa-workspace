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
  }) : _launchUrl =
           launchUrlFn ??
           ((Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication));

  final InAppReview _review;
  final Future<bool> Function(Uri uri) _launchUrl;

  static const String _logName = 'tilawa.app_review';

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
  }) async {
    if (kIsWeb) {
      throw const AppReviewFailure.platformUnsupported();
    }

    // in_app_review Android path uses the running applicationId, so flavor
    // suffixes (.dev / .staging) open unpublished listings. Always deep-link
    // the production Play package instead.
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _openAndroidPlayListing(androidPackageId);
      return;
    }

    try {
      await _review.openStoreListing(
        appStoreId: appStoreId,
        microsoftStoreId: microsoftStoreId,
      );
      developer.log('openStoreListing completed', name: _logName);
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

  Future<void> _openAndroidPlayListing(String? androidPackageId) async {
    final Uri uri = AppReviewStoreConfig.playStoreListingUriFor(
      androidPackageId,
    );

    try {
      final bool launched = await _launchUrl(uri);
      if (!launched) {
        throw const AppReviewFailure.storeListingFailed(
          'Could not open Play Store listing',
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
