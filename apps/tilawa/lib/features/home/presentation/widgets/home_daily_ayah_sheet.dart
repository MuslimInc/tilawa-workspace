import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilawa/core/di/injection.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/home_daily_inspiration_catalog.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

Future<void> showHomeDailyAyahSheet(
  BuildContext context, {
  required int catalogIndex,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _HomeDailyAyahSheet(catalogIndex: catalogIndex),
  );
}

class _HomeDailyAyahSheet extends StatefulWidget {
  const _HomeDailyAyahSheet({required this.catalogIndex});

  final int catalogIndex;

  @override
  State<_HomeDailyAyahSheet> createState() => _HomeDailyAyahSheetState();
}

class _HomeDailyAyahSheetState extends State<_HomeDailyAyahSheet> {
  static const String _bookmarkStorageKey = 'home_daily_ayah_bookmarks';

  bool _isBookmarked = false;
  bool _loadedBookmark = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarkState();
  }

  Future<void> _loadBookmarkState() async {
    final prefs = getIt<SharedPreferencesAsync>();
    final Set<String> bookmarks =
        (await prefs.getStringList(_bookmarkStorageKey))?.toSet() ?? {};
    if (!mounted) {
      return;
    }
    setState(() {
      _isBookmarked = bookmarks.contains(_bookmarkKey);
      _loadedBookmark = true;
    });
  }

  String get _bookmarkKey {
    final verse = homeDailyAyahCatalogVerses[widget.catalogIndex];
    return '${verse.surahNumber}:${verse.ayahNumber}';
  }

  _DailyAyahSheetCopy _copy(AppLocalizations l10n) {
    return switch (widget.catalogIndex) {
      1 => _DailyAyahSheetCopy(
        body: l10n.homeDailyAyahBody1,
        reference: l10n.homeDailyAyahReference1,
      ),
      2 => _DailyAyahSheetCopy(
        body: l10n.homeDailyAyahBody2,
        reference: l10n.homeDailyAyahReference2,
      ),
      _ => _DailyAyahSheetCopy(
        body: l10n.homeDailyAyahBody,
        reference: l10n.homeDailyAyahReference,
      ),
    };
  }

  Future<void> _toggleBookmark() async {
    final prefs = getIt<SharedPreferencesAsync>();
    final Set<String> bookmarks =
        (await prefs.getStringList(_bookmarkStorageKey))?.toSet() ?? {};
    if (_isBookmarked) {
      bookmarks.remove(_bookmarkKey);
    } else {
      bookmarks.add(_bookmarkKey);
    }
    await prefs.setStringList(_bookmarkStorageKey, bookmarks.toList());
    if (!mounted) {
      return;
    }
    setState(() => _isBookmarked = !_isBookmarked);
  }

  Future<void> _shareAyah(_DailyAyahSheetCopy copy) async {
    await SharePlus.instance.share(
      ShareParams(
        text: '${copy.body}\n\n${copy.reference}',
        subject: context.l10n.homeDailyAyahLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final copy = _copy(context.l10n);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceMedium,
        tokens.spaceMedium,
        tokens.spaceMedium,
        tokens.spaceMedium + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.homeDailyAyahLabel,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.spaceMedium),
          Text(
            copy.body,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: context.isArabic
                  ? tokens.textHeightLoose
                  : theme.textTheme.bodyLarge?.height,
            ),
          ),
          SizedBox(height: tokens.spaceSmall),
          Text(
            copy.reference,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.spaceLarge),
          Row(
            children: [
              Expanded(
                child: TilawaButton(
                  text: context.l10n.homeDailyAyahBookmark,
                  variant: TilawaButtonVariant.secondary,
                  onPressed: _loadedBookmark ? _toggleBookmark : null,
                  leadingIcon: Icon(
                    _isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                  ),
                ),
              ),
              SizedBox(width: tokens.spaceSmall),
              Expanded(
                child: TilawaButton(
                  text: context.l10n.homeDailyAyahShare,
                  onPressed: () => _shareAyah(copy),
                  leadingIcon: const Icon(Icons.ios_share_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _DailyAyahSheetCopy {
  const _DailyAyahSheetCopy({required this.body, required this.reference});

  final String body;
  final String reference;
}
