import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:quran_qcf/quran_qcf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/entities/ayah_widget_payload.dart';
import '../domain/entities/curated_ayah.dart';
import '../domain/entities/widget_snapshot_envelope.dart';
import '../domain/services/daily_ayah_selector.dart';
import 'widget_snapshot_bridge.dart';

/// Composes and publishes the Ayah of the Day widget snapshot (spec 041,
/// T016): loads the curated pool, picks today's verse deterministically,
/// renders it to light/dark QCF PNG artifacts, and dispatches the versioned
/// envelope to the native store.
///
/// Rendering happens here — while the app runs and fonts are loadable — so
/// the widget itself never needs a Dart isolate (FR-004/FR-005/FR-010).
class DailyAyahWidgetRepository {
  DailyAyahWidgetRepository({
    required this._fontService,
    required this._bridge,
    required this._prefs,
    this._selector = const DailyAyahSelector(),
    WidgetAyahArtifactRenderer? renderer,
    Future<String> Function(String key)? loadAsset,
    Future<Directory> Function()? artifactDirectory,
  }) : _renderer = renderer ?? WidgetAyahArtifactRenderer(),
       _loadAsset = loadAsset ?? rootBundle.loadString,
       _artifactDirectory = artifactDirectory ?? _defaultArtifactDirectory;

  static const String catalogAssetKey = 'assets/data/widget_daily_ayahs.json';
  static const String _seedPrefsKey = 'islamic_widget_ayah_rotation_seed';

  /// Rendered artifact bounds (logical px). Wide enough for a 4x2 widget at
  /// xxhdpi without exceeding RemoteViews bitmap budgets.
  static const double artifactWidth = 840;
  static const double artifactHeight = 400;

  static const Color _lightThemeTextColor = Color(0xDE000000);
  static const Color _darkThemeTextColor = Color(0xF2FFFFFF);

  final QuranFontService _fontService;
  final WidgetSnapshotBridge _bridge;
  final SharedPreferencesAsync _prefs;
  final DailyAyahSelector _selector;
  final WidgetAyahArtifactRenderer _renderer;
  final Future<String> Function(String key) _loadAsset;
  final Future<Directory> Function() _artifactDirectory;

  static Future<Directory> _defaultArtifactDirectory() async {
    final Directory support = await getApplicationSupportDirectory();
    return Directory('${support.path}/islamic_widgets');
  }

  /// Renders and publishes the snapshot for [now]'s local calendar day.
  Future<AyahWidgetPayload> publishFor(DateTime now) async {
    final List<CuratedAyah> catalog = await _loadCatalog();
    final int seed = await _installationSeed();
    final CuratedAyah ayah = _selector.select(
      localDate: now,
      seed: seed,
      catalog: catalog,
    );

    await _fontService.ensureSingleFontLoaded(ayah.pageNumber);
    final String qcfText =
        getVerseQCF(
          ayah.surahNumber,
          ayah.ayahNumber,
          verseEndSymbol: false,
        ) +
        getVerseNumberQCF(ayah.surahNumber, ayah.ayahNumber);
    final String fontFamily =
        'QCF_P${ayah.pageNumber.toString().padLeft(3, '0')}';

    final Directory dir = await _artifactDirectory();
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final String lightPath = '${dir.path}/ayah_light.png';
    final String darkPath = '${dir.path}/ayah_dark.png';
    await _renderArtifact(qcfText, fontFamily, _lightThemeTextColor, lightPath);
    await _renderArtifact(qcfText, fontFamily, _darkThemeTextColor, darkPath);

    final String dateKey = _dateKey(now);
    final AyahWidgetPayload payload = AyahWidgetPayload(
      dateKey: dateKey,
      surahNumber: ayah.surahNumber,
      ayahNumber: ayah.ayahNumber,
      pageNumber: ayah.pageNumber,
      caption:
          '${getSurahNameArabic(ayah.surahNumber)} · '
          '${_arabicDigits(ayah.ayahNumber)}',
      imagePathLight: lightPath,
      imagePathDark: darkPath,
    );

    final DateTime midnight = DateTime(now.year, now.month, now.day + 1);
    await _bridge.dispatchSnapshot(
      WidgetSnapshotEnvelope<AyahWidgetPayload>(
        schemaVersion: 1,
        widgetType: IslamicWidgetType.ayah,
        generatedAt: now,
        validUntil: midnight,
        payload: payload,
      ),
    );
    logger.d(
      '[DailyAyahWidgetRepository] Published $dateKey → '
      '${ayah.surahNumber}:${ayah.ayahNumber} (page ${ayah.pageNumber})',
    );
    return payload;
  }

  Future<void> _renderArtifact(
    String qcfText,
    String fontFamily,
    Color color,
    String path,
  ) async {
    final List<int> bytes = await _renderer.renderAyahToPng(
      qcfText: qcfText,
      fontFamily: fontFamily,
      width: artifactWidth,
      height: artifactHeight,
      textColor: color,
    );
    if (bytes.isEmpty) {
      throw StateError('QCF artifact render produced no bytes');
    }
    // Write-then-rename so the provider never decodes a half-written file.
    final File tmp = File('$path.tmp');
    tmp.writeAsBytesSync(bytes, flush: true);
    tmp.renameSync(path);
  }

  Future<List<CuratedAyah>> _loadCatalog() async {
    final String raw = await _loadAsset(catalogAssetKey);
    final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
    final List<CuratedAyah> catalog = <CuratedAyah>[
      for (final dynamic item in data)
        CuratedAyah(
          surahNumber: (item as Map<String, dynamic>)['surahNumber'] as int,
          ayahNumber: item['ayahNumber'] as int,
          pageNumber: getPageNumber(
            item['surahNumber'] as int,
            item['ayahNumber'] as int,
          ),
        ),
    ];
    if (catalog.isEmpty) {
      throw StateError('widget_daily_ayahs.json is empty');
    }
    return catalog;
  }

  /// Stable per-installation rotation offset so different users see
  /// different verses on the same day (spec FR-005).
  Future<int> _installationSeed() async {
    final int? stored = await _prefs.getInt(_seedPrefsKey);
    if (stored != null) return stored;
    final int seed = Random().nextInt(1 << 20);
    await _prefs.setInt(_seedPrefsKey, seed);
    return seed;
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _arabicDigits(int value) {
    const List<String> digits = <String>[
      '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩', //
    ];
    return value
        .toString()
        .split('')
        .map((String c) => digits[int.parse(c)])
        .join();
  }
}
