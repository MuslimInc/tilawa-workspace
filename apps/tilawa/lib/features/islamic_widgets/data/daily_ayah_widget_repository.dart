import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show FontLoader, rootBundle;
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
    required this._bridge,
    required this._prefs,
    this._selector = const DailyAyahSelector(),
    WidgetAyahArtifactRenderer? renderer,
    Future<String> Function(String key)? loadAsset,
    Future<Directory> Function()? artifactDirectory,
    Future<Directory> Function()? documentsDirectory,
  }) : _renderer = renderer ?? WidgetAyahArtifactRenderer(),
       _loadAsset = loadAsset ?? rootBundle.loadString,
       _artifactDirectory = artifactDirectory ?? _defaultArtifactDirectory,
       _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory;

  static const String catalogAssetKey = 'assets/data/widget_daily_ayahs.json';
  static const String _seedPrefsKey = 'islamic_widget_ayah_rotation_seed';

  /// Rendered artifact bounds (logical px). Wide enough for a 4x2 widget at
  /// xxhdpi without exceeding RemoteViews bitmap budgets.
  static const double artifactWidth = 840;
  static const double artifactHeight = 400;

  static const Color _lightThemeTextColor = Color(0xDE000000);
  static const Color _darkThemeTextColor = Color(0xF2FFFFFF);

  final WidgetSnapshotBridge _bridge;
  final SharedPreferencesAsync _prefs;
  final DailyAyahSelector _selector;
  final WidgetAyahArtifactRenderer _renderer;
  final Future<String> Function(String key) _loadAsset;
  final Future<Directory> Function() _artifactDirectory;
  final Future<Directory> Function() _documentsDirectory;

  /// Families registered by this repository in the current process.
  static final Set<String> _registeredFontFamilies = <String>{};

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

    final String pageFamily =
        'QCF_P${ayah.pageNumber.toString().padLeft(3, '0')}';
    await _ensureFontRegistered(pageFamily);
    final String qcfText =
        getVerseQCF(
          ayah.surahNumber,
          ayah.ayahNumber,
          verseEndSymbol: false,
        ) +
        getVerseNumberQCF(ayah.surahNumber, ayah.ayahNumber);
    final String fontFamily = pageFamily;

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

  /// Registers the page font directly from the downloaded QCF bundle.
  ///
  /// Deliberately bypasses `QuranFontService.ensureSingleFontLoaded`: awaiting
  /// it from the deferred startup context never resumed (its internal load
  /// completed and logged, but the caller-facing future stayed pending —
  /// deadlocking the publish until its 45s timeout). Direct [FontLoader]
  /// registration is self-contained and idempotent per process.
  ///
  /// File-name resolution mirrors `QuranFontService._resolvePageFontFamily`
  /// (QCF4001_X-Regular.woff, QCF4_163.woff, 163.woff, p001.ttf …).
  Future<void> _ensureFontRegistered(String family) async {
    if (_registeredFontFamilies.contains(family)) return;
    final Directory docs = await _documentsDirectory();
    final Directory fontsDir = Directory('${docs.path}/qcf4_fonts');
    if (!fontsDir.existsSync()) {
      throw StateError('QCF fonts are not downloaded yet');
    }
    File? fontFile;
    for (final FileSystemEntity entity in fontsDir.listSync()) {
      if (entity is File && _familyForFontFile(entity.path) == family) {
        fontFile = entity;
        break;
      }
    }
    if (fontFile == null) {
      throw StateError('No downloaded font file resolves to $family');
    }
    final Uint8List bytes = fontFile.readAsBytesSync();
    final FontLoader loader = FontLoader(family)
      ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    await loader.load();
    _registeredFontFamilies.add(family);
  }

  static String? _familyForFontFile(String path) {
    final String filename = path.split('/').last;
    final RegExpMatch? qcfMatch = RegExp(
      r'QCF[34]_?(\d+)',
    ).firstMatch(filename);
    String? pageNumStr = qcfMatch?.group(1);
    pageNumStr ??= RegExp(r'(\d+)\.[^.]+$').firstMatch(filename)?.group(1);
    if (pageNumStr == null) return null;
    if (pageNumStr.length > 3) {
      pageNumStr = pageNumStr.substring(pageNumStr.length - 3);
    }
    return 'QCF_P${pageNumStr.padLeft(3, '0')}';
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
