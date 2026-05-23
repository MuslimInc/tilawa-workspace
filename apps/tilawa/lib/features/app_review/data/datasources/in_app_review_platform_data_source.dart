import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:injectable/injectable.dart';
import 'package:tilawa_core/errors/failures.dart';

import 'app_review_platform_data_source.dart';

/// Default provider using [`in_app_review`](https://pub.dev/packages/in_app_review).
///
/// Alternative: implement [AppReviewPlatformDataSource] with
/// [`app_review`](https://pub.dev/packages/app_review) and rebind in DI.
@LazySingleton(as: AppReviewPlatformDataSource)
class InAppReviewPlatformDataSource implements AppReviewPlatformDataSource {
  InAppReviewPlatformDataSource(this._review);

  final InAppReview _review;

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
  }) async {
    if (kIsWeb) {
      throw const AppReviewFailure.platformUnsupported();
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
}
