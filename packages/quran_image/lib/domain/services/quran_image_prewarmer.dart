abstract class QuranImagePrewarmer {
  void startInitialPrewarm({
    required int currentPageNumber,
    required int cacheWidth,
  });

  void prewarmCurrentTarget({required int pageNumber, required int cacheWidth});

  void prewarmPreviewTarget({required int pageNumber, required int cacheWidth});

  void prewarmJumpTarget({required int pageNumber, required int cacheWidth});

  Future<void> ensurePageReady({
    required int pageNumber,
    required int cacheWidth,
  });

  void prewarmSettledWindow({
    required int pageNumber,
    required int cacheWidth,
    int radius = 1,
  });

  void handleMemoryPressure();

  void cancel();

  void dispose();
}
