import 'package:flutter/material.dart';
import 'package:quran_image/core/di/dependency_injection.dart';
import 'package:quran_image/core/perf_logger.dart';
import 'package:quran_image/core/utils/quran_image_utils.dart';
import 'package:quran_image/domain/domain.dart';
import 'package:quran_image/l10n/quran_image_localizations.dart';
import 'package:quran_image/page_mapping.dart';
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
  final VoidCallback? onShowIndex;

  const QuranImagePage({
    super.key,
    required this.pageNumber,
    this.onShowIndex,
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

    if (cacheWidthChanged) {
      _rebuildLineProviders();
    }
    PerfLogger.logElapsed(
      sw,
      widgetName: 'QuranImagePage',
      message:
          'didChangeDependencies page=${widget.pageNumber} '
          'landscape=$newIsLandscape '
          'rebuildProviders=$cacheWidthChanged '
          'pageWidth=${availableWidth.toStringAsFixed(1)} '
          'cacheWidth=$newCacheWidth',
    );
  }

  void _refreshPageData() {
    _markers = _markerRepository.getMarkersForPage(widget.pageNumber);
    _headers = _headerRepository.getHeadersForPage(widget.pageNumber);
  }

  ({double layoutHeight, List<double> yOffsets}) _calculateLayoutMetrics({
    required double availableHeight,
    required double lineHeight,
    required bool isLandscape,
  }) {
    final layoutHeight = isLandscape
        ? lineHeight * SurahHeaderConstants.lineCount
        : availableHeight;

    final lastLineIndex = SurahHeaderConstants.lastLineIndex.toDouble();
    final yOffsets = List<double>.generate(
      SurahHeaderConstants.lineCount,
      (index) => (layoutHeight - lineHeight) / lastLineIndex * index,
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
    PerfLogger.markBuild('QuranImagePage');

    return Column(
      children: [
        QuranAppBar(
          pageNumber: widget.pageNumber,
          onShowIndex: widget.onShowIndex,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
                return const SizedBox.shrink();
              }

              final layoutPageWidth = constraints.maxWidth;
              final layoutPageHeight = constraints.maxHeight;
              final layoutIsLandscape = layoutPageWidth > layoutPageHeight;
              final layoutLineHeight = widget.surahHeaderLayoutPolicy
                  .lineHeightForPageWidth(layoutPageWidth);
              final (:layoutHeight, :yOffsets) = _calculateLayoutMetrics(
                availableHeight: constraints.maxHeight,
                lineHeight: layoutLineHeight,
                isLandscape: layoutIsLandscape,
              );

              // Isolates line stack + markers from app bar / footer repaint
              // boundaries so compositor can cache this subtree when possible.
              return RepaintBoundary(
                child: QuranImageContent(
                  pageNumber: widget.pageNumber,
                  pageWidth: layoutPageWidth,
                  // Header layout policy was tuned with full-viewport height; the
                  // line stack width/height still come from this frame's layout.
                  pageHeight: _pageHeight > 0 ? _pageHeight : layoutPageHeight,
                  lineHeight: layoutLineHeight,
                  yOffsets: yOffsets,
                  headers: _headers,
                  markers: _markers,
                  lineProviders: _lineProviders,
                  surahHeaderLayoutPolicy: widget.surahHeaderLayoutPolicy,
                  imageCacheRepository: _imageCacheRepository,
                  devicePixelRatio: _devicePixelRatio,
                  isLandscape: layoutIsLandscape,
                  headerImageFilter: widget.headerImageFilter,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class QuranAppBar extends StatelessWidget {
  final int pageNumber;
  final VoidCallback? onShowIndex;

  const QuranAppBar({super.key, required this.pageNumber, this.onShowIndex});

  @override
  Widget build(BuildContext context) {
    final pageInfo = QuranPageMapping.getPageInfo(pageNumber);
    final pageData = getPageData(pageNumber);
    final surahNumbers = pageData.map((e) => e.surah).toSet().toList();
    final surahNames = surahNumbers
        .map((s) => SurahNames.getSurahName(s, 'ar'))
        .join('  ');
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final primaryColor = theme.colorScheme.primary;
    final textStyle = theme.textTheme.labelMedium?.copyWith(
      color: primaryColor,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
    final indexLabel = QuranImageLocalizations.of(context).surahIndex;

    return Padding(
      padding: EdgeInsets.only(
        left: tokens.spaceSmall,
        right: tokens.spaceSmall,
        top: tokens.spaceExtraSmall,
        bottom: tokens.spaceTiny,
      ),
      child: Row(
        children: [
          // Juz label (start / left in RTL = right side of page)
          Expanded(
            child: Text(
              _arabicJuzLabel(pageInfo.juzNumber),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: textStyle,
            ),
          ),
          // Index button in the center
          if (onShowIndex != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
              child: TilawaIconActionButton(
                icon: Icons.format_list_bulleted_rounded,
                tooltip: indexLabel,
                semanticLabel: indexLabel,
                onTap: onShowIndex!,
              ),
            ),
          // Surah names (end / right in RTL = left side of page)
          Expanded(
            child: Text(
              surahNames,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: textStyle,
            ),
          ),
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
