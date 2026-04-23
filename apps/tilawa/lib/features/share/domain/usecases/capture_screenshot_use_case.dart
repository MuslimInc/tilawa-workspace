import 'package:injectable/injectable.dart';

import '../entities/share_content.dart';
import '../entities/widget_capture_handle.dart';
import '../repositories/share_repository.dart';

@injectable
class CaptureScreenshotUseCase {
  CaptureScreenshotUseCase(this._repository);
  final ShareRepository _repository;

  Future<ShareContent> call({
    required WidgetCaptureHandle handle,
    required String surahName,
    required int pageNumber,
    required String appName,
    required String sharedViaLabel,
    bool brandCapture = true,
  }) {
    return _repository.captureScreenshot(
      handle: handle,
      surahName: surahName,
      pageNumber: pageNumber,
      appName: appName,
      sharedViaLabel: sharedViaLabel,
      brandCapture: brandCapture,
    );
  }
}
