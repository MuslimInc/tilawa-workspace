abstract class QuranImagePrewarmer {
  void startInitialPrewarm({
    required int currentPageNumber,
    required int cacheWidth,
  });

  void prewarmCurrentTarget({required int pageNumber, required int cacheWidth});

  void prewarmPreviewTarget({required int pageNumber, required int cacheWidth});

  void prewarmJumpTarget({required int pageNumber, required int cacheWidth});

  /// Starts decoding all 15 line images for [pageNumber] immediately, then
  /// returns a [Future] that completes once every image is confirmed decoded
  /// in Flutter's image cache — or when [timeout] elapses, whichever is first.
  ///
  /// If called again before the previous future completes, the previous wait
  /// is abandoned (generation token incremented) and only the new target is
  /// awaited. The caller should then commit the navigation (`jumpToPage`) in
  /// the `.then()` callback so the page appears with all images already decoded
  /// on the first rendered frame.
  Future<void> prewarmJumpTargetAndWait({
    required int pageNumber,
    required int cacheWidth,
    required Duration timeout,
  });

  void prewarmSettledWindow({required int pageNumber, required int cacheWidth});

  void cancel();

  void dispose();
}
