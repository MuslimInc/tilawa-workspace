import 'package:flutter/material.dart';
import 'package:tilawa/l10n/generated/app_localizations.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import '../../domain/entities/daily_guidance_enums.dart';
import '../../domain/entities/daily_guidance_item.dart';

class DailyGuidanceCard extends StatelessWidget {
  final DailyGuidanceItem item;

  const DailyGuidanceCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return TilawaCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  item.type == DailyGuidanceItemType.quran
                      ? Icons.menu_book
                      : Icons.library_books,
                  color: context.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  item.type == DailyGuidanceItemType.quran
                      ? AppLocalizations.of(context).dailyGuidanceTypeQuran
                      : AppLocalizations.of(context).dailyGuidanceTypeHadith,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              item.originalArabicText,
              style: context.textTheme.headlineSmall?.copyWith(
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            if (item.translation case final translation?) ...[
              const SizedBox(height: 16),
              Text(
                translation.text,
                style: context.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
            if (item.shortExplanation case final explanation?) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                explanation.text,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _buildSourceText(context),
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSourceText(BuildContext context) {
    if (item.type == DailyGuidanceItemType.quran && item.quranSource != null) {
      return AppLocalizations.of(context).dailyGuidanceQuranSource(
        item.quranSource!.surahNameArabic,
        item.quranSource!.ayahStart,
      );
    } else if (item.type == DailyGuidanceItemType.hadith &&
        item.hadithSource != null) {
      return AppLocalizations.of(context).dailyGuidanceHadithSource(
        item.hadithSource!.collection,
        item.hadithSource!.referenceNumber,
      );
    }
    return '';
  }
}
