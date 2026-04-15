import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quran_image_flutter/core/constants/quran_image_asset_constants.dart';
import 'package:quran_image_flutter/core/constants/surah_header_constants.dart';
import 'package:quran_image_flutter/core/design_tokens/design_tokens.dart';
import 'package:quran_image_flutter/core/di/dependency_injection.dart';
import 'package:quran_image_flutter/core/perf_logger.dart';
import 'package:quran_image_flutter/domain/domain.dart';
import 'package:quran_image_flutter/verse_marker.dart';

/// Renders a full Quran page using the same layout algorithm as the Ayah app.
///
/// The Ayah app's `QuranLineLayout` (Kotlin) places each line at:
///   y = floor((pageHeight - lineHeight) / 14 * lineIndex)
/// where:
///   lineHeight is derived from the rendered page width.
///   lineIndex  = 0-based (0–14)
///
/// Each line image is the same 1440×232 aspect ratio -> ratio = 232/1440.
class QuranImagePage extends StatefulWidget {
  final int pageNumber;
  final SurahHeaderBannerLayoutPolicy surahHeaderLayoutPolicy;

  const QuranImagePage({
    super.key,
    required this.pageNumber,
    this.surahHeaderLayoutPolicy =
        const CalibratedSurahHeaderBannerLayoutPolicy(),
  });

  @override
  State<QuranImagePage> createState() => _QuranImagePageState();
}

class _QuranImagePageState extends State<QuranImagePage>
    with AutomaticKeepAliveClientMixin<QuranImagePage> {
  late final VerseMarkerRepository _markerRepository;
  late final SurahHeaderRepository _headerRepository;
  late final QuranImageCacheRepository _imageCacheRepository;
  late final DecodedQuranImageCache _decodedImageCache;

  int _cacheWidth = 0;
  double _devicePixelRatio = 1.0;
  double _pageWidth = 0;
  double _pageHeight = 0;
  double _lineHeight = 0;
  double _layoutHeight = 0;
  bool _isLandscape = false;
  List<double> _yOffsets = const <double>[];

  List<VerseMarkerData> _markers = const <VerseMarkerData>[];
  List<SurahHeaderData> _headers = const <SurahHeaderData>[];
  List<ImageProvider<Object>?> _lineProviders =
      List<ImageProvider<Object>?>.filled(SurahHeaderConstants.lineCount, null);
  bool _isPageContentReady = false;
  int _pageReadinessGeneration = 0;
  Widget _pageContent = const SizedBox.shrink();
  Widget _composedPage = const SizedBox.shrink();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _markerRepository = sl<VerseMarkerRepository>();
    _headerRepository = sl<SurahHeaderRepository>();
    _imageCacheRepository = sl<QuranImageCacheRepository>();
    _decodedImageCache = sl<DecodedQuranImageCache>();
    _refreshPageData();
  }

  @override
  void didUpdateWidget(covariant QuranImagePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final pageChanged = oldWidget.pageNumber != widget.pageNumber;
    final layoutPolicyChanged =
        oldWidget.surahHeaderLayoutPolicy != widget.surahHeaderLayoutPolicy;
    if (!pageChanged && !layoutPolicyChanged) {
      return;
    }

    if (pageChanged) {
      _refreshPageData();
    }

    if (_pageWidth <= 0 || _pageHeight <= 0) {
      _composedPage = const SizedBox.shrink();
      return;
    }

    _lineHeight = widget.surahHeaderLayoutPolicy.lineHeightForPageWidth(
      _pageWidth,
    );
    _layoutHeight = _isLandscape
        ? _lineHeight * SurahHeaderConstants.lineCount
        : _pageHeight;
    _rebuildYOffsets();
    _schedulePageContentRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final view = View.of(context);
    final dpr = view.devicePixelRatio;
    final screenWidth = view.physicalSize.width / dpr;
    final screenHeight = view.physicalSize.height / dpr;
    final newCacheWidth = (screenWidth * dpr).round();

    final padding = MediaQuery.paddingOf(context);
    final availableWidth = screenWidth - padding.left - padding.right;
    final availableHeight = screenHeight - padding.top - padding.bottom;
    final newIsLandscape = availableWidth > availableHeight;

    if (_cacheWidth == newCacheWidth &&
        _pageWidth == availableWidth &&
        _pageHeight == availableHeight &&
        _devicePixelRatio == dpr) {
      return;
    }

    _cacheWidth = newCacheWidth;
    _devicePixelRatio = dpr;
    _pageWidth = availableWidth;
    _pageHeight = availableHeight;
    _isLandscape = newIsLandscape;
    _lineHeight = widget.surahHeaderLayoutPolicy.lineHeightForPageWidth(
      _pageWidth,
    );
    _layoutHeight = _isLandscape
        ? _lineHeight * SurahHeaderConstants.lineCount
        : _pageHeight;
    _rebuildYOffsets();
    _schedulePageContentRefresh();
  }

  void _refreshPageData() {
    _markers = _markerRepository.getMarkersForPage(widget.pageNumber);
    _headers = _headerRepository.getHeadersForPage(widget.pageNumber);
  }

  void _rebuildYOffsets() {
    final lastLineIndex = SurahHeaderConstants.lastLineIndex.toDouble();
    _yOffsets = List<double>.generate(
      SurahHeaderConstants.lineCount,
      (index) => (_layoutHeight - _lineHeight) / lastLineIndex * index,
      growable: false,
    );
  }

  void _rebuildLineProviders() {
    _lineProviders = List<ImageProvider<Object>?>.generate(
      SurahHeaderConstants.lineCount,
      (index) {
        final path = _imageCacheRepository.lineImageFilePath(
          pageNumber: widget.pageNumber,
          oneBasedLineNumber: index + 1,
        );
        if (path == null) {
          return null;
        }
        return buildQuranLineImageProvider(
          imagePath: path,
          cacheWidth: _cacheWidth,
        );
      },
      growable: false,
    );
  }

  void _schedulePageContentRefresh() {
    if (_pageWidth <= 0 || _layoutHeight <= 0 || _cacheWidth <= 0) {
      _isPageContentReady = false;
      _pageContent = const SizedBox.shrink();
      _composedPage = const SizedBox.shrink();
      return;
    }

    final generation = ++_pageReadinessGeneration;
    _isPageContentReady = false;
    _rebuildPageContent();
    _rebuildComposedPage();
    unawaited(_awaitPageContentReady(generation));
  }

  Future<void> _awaitPageContentReady(int generation) async {
    final linePaths = _collectLineImagePaths();
    if (linePaths.isEmpty) {
      _markPageContentReady(generation);
      return;
    }

    for (final path in linePaths) {
      _decodedImageCache.prewarmLineImage(
        imagePath: path,
        cacheWidth: _cacheWidth,
      );
    }

    final bannerPath = _imageCacheRepository.surahHeaderBannerFilePath();
    if (bannerPath != null) {
      _decodedImageCache.prewarmFileImage(bannerPath);
    }

    const pollInterval = Duration(milliseconds: 16);
    const timeout = Duration(milliseconds: 3000);
    final deadline = DateTime.now().add(timeout);

    while (mounted && _pageReadinessGeneration == generation) {
      final statuses = await Future.wait(
        linePaths.map(
          (path) => _decodedImageCache.isLineImageCached(
            imagePath: path,
            cacheWidth: _cacheWidth,
          ),
        ),
      );

      if (statuses.every((isReady) => isReady)) {
        _markPageContentReady(generation);
        return;
      }

      if (DateTime.now().isAfter(deadline)) {
        PerfLogger.log(
          widgetName: 'QuranImagePage',
          message:
              'page=${widget.pageNumber} content wait timeout '
              'cacheWidth=$_cacheWidth',
        );
        _markPageContentReady(generation);
        return;
      }

      await Future<void>.delayed(pollInterval);
    }
  }

  List<String> _collectLineImagePaths() {
    final paths = <String>[];
    for (var index = 0; index < SurahHeaderConstants.lineCount; index++) {
      final path = _imageCacheRepository.lineImageFilePath(
        pageNumber: widget.pageNumber,
        oneBasedLineNumber: index + 1,
      );
      if (path != null) {
        paths.add(path);
      }
    }
    return paths;
  }

  void _markPageContentReady(int generation) {
    if (!mounted || _pageReadinessGeneration != generation) {
      return;
    }

    setState(() {
      _isPageContentReady = true;
      _rebuildComposedPage();
    });
  }

  void _rebuildPageContent() {
    if (_pageWidth <= 0 || _layoutHeight <= 0) {
      _pageContent = const SizedBox.shrink();
      return;
    }

    _rebuildLineProviders();

    final children = <Widget>[
      for (final header in _headers)
        Positioned(
          left: 0,
          right: 0,
          top: _yOffsets[header.lineIndex],
          height: _lineHeight,
          child: _buildSurahHeaderBanner(header),
        ),
      for (var index = 0; index < SurahHeaderConstants.lineCount; index++)
        Positioned(
          left: 0,
          right: 0,
          top: _yOffsets[index],
          height: _lineHeight,
          child: _buildLineImage(_lineProviders[index]),
        ),
      if (_markers.isNotEmpty)
        Positioned.fill(
          child: RepaintBoundary(
            child: VerseMarkersOverlay(
              markers: _markers,
              pageWidth: _pageWidth,
              lineHeight: _lineHeight,
              yOffsets: _yOffsets,
            ),
          ),
        ),
    ];

    final content = SizedBox(
      width: _pageWidth,
      height: _layoutHeight,
      child: Stack(clipBehavior: Clip.none, children: children),
    );

    _pageContent = content;
  }

  void _rebuildComposedPage() {
    if (_pageWidth <= 0 || _layoutHeight <= 0) {
      _composedPage = const SizedBox.shrink();
      return;
    }

    final layeredPage = SizedBox(
      width: _pageWidth,
      height: _layoutHeight,
      child: Stack(
        children: [
          _pageContent,
          if (!_isPageContentReady)
            const Positioned.fill(
              child: ColoredBox(
                key: ValueKey<String>('quran-image-page-loading-surface'),
                color: AppColors.pageBackground,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    _composedPage = RepaintBoundary(
      child: _isLandscape
          ? SingleChildScrollView(child: layeredPage)
          : layeredPage,
    );
  }

  Widget _buildSurahHeaderBanner(SurahHeaderData header) {
    final metrics = widget.surahHeaderLayoutPolicy.calculate(
      SurahHeaderBannerLayoutInput(
        pageWidth: _pageWidth,
        pageHeight: _pageHeight,
        lineHeight: _lineHeight,
        inkCenterYFraction: header.inkCenterYFraction,
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
      child: Center(
        child: Transform.translate(
          offset: Offset(0, metrics.verticalOffset),
          child: SizedBox(
            width: metrics.bannerWidth,
            height: metrics.bannerHeight,
            child: buildCachedOrRemoteImage(
              localPath: _imageCacheRepository.surahHeaderBannerFilePath(),
              remoteUrl: QuranImageAssetConstants.remoteSurahHeaderBannerUrl,
              fit: BoxFit.fill,
              gaplessPlayback: true,
              cacheWidth: (metrics.bannerWidth * _devicePixelRatio).round(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final sw = PerfLogger.startTimer();
    final page = _composedPage;
    PerfLogger.logElapsed(
      sw,
      widgetName: 'QuranImagePage',
      message:
          'page=${widget.pageNumber} build '
          'cacheWidth=$_cacheWidth '
          '${_isLandscape ? "landscape" : "portrait"} '
          'headers=${_headers.length} '
          'markers=${_markers.length}',
    );
    return page;
  }
}

Widget _buildLineImage(ImageProvider<Object>? provider) {
  if (provider == null) {
    return const SizedBox.shrink();
  }

  return Image(
    image: provider,
    fit: BoxFit.fill,
    gaplessPlayback: true,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}

ImageProvider<Object> buildQuranLineImageProvider({
  required String imagePath,
  required int cacheWidth,
}) {
  return _cachedFileImageProvider(imagePath: imagePath, cacheWidth: cacheWidth);
}

Widget buildCachedOrRemoteImage({
  required String? localPath,
  required String remoteUrl,
  required BoxFit fit,
  required bool gaplessPlayback,
  int? cacheWidth,
}) {
  final path = localPath;
  if (path != null) {
    return Image(
      image: _cachedFileImageProvider(imagePath: path, cacheWidth: cacheWidth),
      fit: fit,
      gaplessPlayback: gaplessPlayback,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }

  return Image.network(
    remoteUrl,
    fit: fit,
    gaplessPlayback: gaplessPlayback,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}

const int _maxFileImageProviderEntries = 1024;
final LinkedHashMap<String, ImageProvider<Object>> _fileImageProviderCache =
    LinkedHashMap<String, ImageProvider<Object>>();

ImageProvider<Object> _cachedFileImageProvider({
  required String imagePath,
  int? cacheWidth,
}) {
  final key = cacheWidth == null ? 'file:$imagePath' : '$cacheWidth:$imagePath';
  final cached = _fileImageProviderCache.remove(key);
  if (cached != null) {
    _fileImageProviderCache[key] = cached;
    return cached;
  }

  final provider = cacheWidth == null
      ? FileImage(File(imagePath)) as ImageProvider<Object>
      : ResizeImage.resizeIfNeeded(
          cacheWidth,
          null,
          FileImage(File(imagePath)),
        );
  _fileImageProviderCache[key] = provider;
  while (_fileImageProviderCache.length > _maxFileImageProviderEntries) {
    _fileImageProviderCache.remove(_fileImageProviderCache.keys.first);
  }
  return provider;
}
