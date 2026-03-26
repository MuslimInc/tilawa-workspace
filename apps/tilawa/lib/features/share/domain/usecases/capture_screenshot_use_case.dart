import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../entities/share_content.dart';
import '../repositories/share_repository.dart';

@injectable
class CaptureScreenshotUseCase {
  CaptureScreenshotUseCase(this._repository);
  final ShareRepository _repository;

  Future<ShareContent> call({
    required GlobalKey boundaryKey,
    required String surahName,
    required int pageNumber,
    required String appName,
    required String sharedViaLabel,
  }) {
    return _repository.captureScreenshot(
      boundaryKey: boundaryKey,
      surahName: surahName,
      pageNumber: pageNumber,
      appName: appName,
      sharedViaLabel: sharedViaLabel,
    );
  }
}
