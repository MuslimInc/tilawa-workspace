import 'package:flutter/material.dart';
import 'package:quran_image/core/di/dependency_injection.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:quran_image/core/utils/quran_image_utils.dart';
import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/page_mapping.dart';
import 'package:quran_image/presentation/widgets/premium_bottom_bar.dart';
import 'package:quran_image/presentation/widgets/widgets.dart';
import 'package:quran_qcf/quran_qcf.dart'
    hide CalibratedSurahHeaderBannerLayoutPolicy, SurahHeaderBannerLayoutPolicy;
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import 'core/constants/surah_header_constants.dart';
import 'core/constants/surah_names.dart';

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
  final ColorFilter? headerImageFilter;

  const QuranImagePage({
    super.key,
    required this.pageNumber,
    this.surahHeaderLayoutPolicy =
        const CalibratedSurahHeaderBannerLayoutPolicy(),
    this.headerImageFilter,
  });

  @override
  State<QuranImagePage> createState() => _QuranImagePageState();
}

class _QuranImagePageState extends State<QuranImagePage> {
  late final VerseMarkerRepository _markerRepository;
  late final SurahHeaderRepository _headerRepository;
  late final QuranImageCacheRepository _imageCacheRepository;

  int _cacheWidth = 0;
  double _devicePixelRatio = 1.0;
  double _pageWidth = 0;
  double _pageHeight = 0;
  double _lineHeight = 0;
  bool _isLandscape = false;

  List<VerseMarkerData> _markers = const <VerseMarkerData>[];
  List<SurahHeaderData> _headers = const <SurahHeaderData>[];
  List<ImageProvider<Object>?> _lineProviders =
      List<ImageProvider<Object>?>.filled(SurahHeaderConstants.lineCount, null);

  @override
  void initState() {
    super.initState();
    _markerRepository = sl<VerseMarkerRepository>();
    _headerRepository = sl<SurahHeaderRepository>();
    _imageCacheRepository = sl<QuranImageCacheRepository>();
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
      _rebuildLineProviders();
    }

    if (_pageWidth > 0) {
      _lineHeight = widget.surahHeaderLayoutPolicy.lineHeightForPageWidth(
        _pageWidth,
      );
    }

    PerfLogger.log(
      widgetName: 'QuranImagePage',
      message:
          'didUpdateWidget page=${widget.pageNumber} '
          'pageChanged=$pageChanged '
          'policyChanged=$layoutPolicyChanged',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final view = View.of(context);
    final dpr = view.devicePixelRatio;
    final screenWidth = view.physicalSize.width / dpr;
    final screenHeight = view.physicalSize.height / dpr;
    final portraitPhysicalWidth =
        view.physicalSize.width < view.physicalSize.height
        ? view.physicalSize.width.round()
        : view.physicalSize.height.round();
    final newCacheWidth = portraitPhysicalWidth;

    final padding = context.contentSafePadding;
    final availableWidth = screenWidth - padding.left - padding.right;
    final availableHeight = screenHeight - padding.top - padding.bottom;
    final newIsLandscape = availableWidth > availableHeight;

    if (_cacheWidth == newCacheWidth &&
        _pageWidth == availableWidth &&
        _pageHeight == availableHeight &&
        _devicePixelRatio == dpr) {
      return;
    }

    final cacheWidthChanged = _cacheWidth != newCacheWidth;

    final sw = PerfLogger.startTimer();
    _cacheWidth = newCacheWidth;
    _devicePixelRatio = dpr;
    _pageWidth = availableWidth;
    _pageHeight = availableHeight;
    _isLandscape = newIsLandscape;
    _lineHeight = widget.surahHeaderLayoutPolicy.lineHeightForPageWidth(
      _pageWidth,
    );

    if (cacheWidthChanged) {
      _rebuildLineProviders();
    }
    PerfLogger.logElapsed(
      sw,
      widgetName: 'QuranImagePage',
      message:
          'didChangeDependencies page=${widget.pageNumber} '
          'landscape=$_isLandscape '
          'rebuildProviders=$cacheWidthChanged '
          'pageWidth=${availableWidth.toStringAsFixed(1)} '
          'cacheWidth=$newCacheWidth',
    );
  }

  void _refreshPageData() {
    _markers = _markerRepository.getMarkersForPage(widget.pageNumber);
    _headers = _headerRepository.getHeadersForPage(widget.pageNumber);
  }

  ({double layoutHeight, List<double> yOffsets}) _calculateLayoutMetrics(
    double availableHeight,
  ) {
    final layoutHeight = _isLandscape
        ? _lineHeight * SurahHeaderConstants.lineCount
        : availableHeight;

    final lastLineIndex = SurahHeaderConstants.lastLineIndex.toDouble();
    final yOffsets = List<double>.generate(
      SurahHeaderConstants.lineCount,
      (index) => (layoutHeight - _lineHeight) / lastLineIndex * index,
      growable: false,
    );
    return (layoutHeight: layoutHeight, yOffsets: yOffsets);
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

  @override
  Widget build(BuildContext context) {
    if (_pageWidth <= 0) {
      return const SizedBox.shrink();
    }

    final pageInfo = QuranPageMapping.getPageInfo(widget.pageNumber);
    final pageState = PageState.initial().copyWith(
      currentPage: widget.pageNumber,
      juzNumber: pageInfo.juzNumber,
      hizbNumber: pageInfo.hizbNumber,
    );

    return Column(
      children: [
        QuranAppBar(pageNumber: widget.pageNumber),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final (:layoutHeight, :yOffsets) = _calculateLayoutMetrics(
                constraints.maxHeight,
              );

              return QuranImageContent(
                pageNumber: widget.pageNumber,
                pageWidth: _pageWidth,
                pageHeight: _pageHeight,
                lineHeight: _lineHeight,
                yOffsets: yOffsets,
                headers: _headers,
                markers: _markers,
                lineProviders: _lineProviders,
                surahHeaderLayoutPolicy: widget.surahHeaderLayoutPolicy,
                imageCacheRepository: _imageCacheRepository,
                devicePixelRatio: _devicePixelRatio,
                isLandscape: _isLandscape,
                headerImageFilter: widget.headerImageFilter,
              );
            },
          ),
        ),
        PremiumBottomBar(state: pageState),
      ],
    );
  }
}

class QuranAppBar extends StatelessWidget {
  final int pageNumber;

  const QuranAppBar({super.key, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    final pageInfo = QuranPageMapping.getPageInfo(pageNumber);

    final pageData = getPageData(pageNumber);
    final surahNumbers = pageData.map((e) => e.surah).toSet().toList();
    final surahNames = surahNumbers
        .map((s) => SurahNames.getSurahName(s, 'ar'))
        .join(' ');
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final textStyle = theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: tokens.spaceTiny,
      ),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          Expanded(
            child: Text(
              _arabicJuzLabel(pageInfo.juzNumber),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: textStyle,
            ),
          ),
          Text(surahNames, overflow: TextOverflow.ellipsis, style: textStyle),
        ],
      ),
    );
  }
}

String _arabicJuzLabel(int juzNumber) {
  const labels = [
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
    'السابع',
    'الثامن',
    'التاسع',
    'العاشر',
    'الحادي عشر',
    'الثاني عشر',
    'الثالث عشر',
    'الرابع عشر',
    'الخامس عشر',
    'السادس عشر',
    'السابع عشر',
    'الثامن عشر',
    'التاسع عشر',
    'العشرون',
    'الحادي والعشرون',
    'الثاني والعشرون',
    'الثالث والعشرون',
    'الرابع والعشرون',
    'الخامس والعشرون',
    'السادس والعشرون',
    'السابع والعشرون',
    'الثامن والعشرون',
    'التاسع والعشرون',
    'الثلاثون',
  ];
  final index = juzNumber - 1;
  if (index < 0 || index >= labels.length) {
    return 'الجزء ${_toEasternArabicDigits(juzNumber)}';
  }
  return 'الجزء ${labels[index]}';
}

String _toEasternArabicDigits(int value) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return value
      .toString()
      .split('')
      .map((character) => digits[int.parse(character)])
      .join();
}
