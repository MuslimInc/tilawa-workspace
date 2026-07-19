import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/home_hijri_date_formatter.dart';
import 'package:tilawa/features/home/presentation/widgets/home_hijri_calendar_sheet.dart';
import 'package:tilawa/features/prayer_times/presentation/formatters/prayer_location_label_formatter.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Figma `date-location-row` — padding bottom 12, width stretch inside 20px inset.
class HomePrayerHeroContextRow extends StatelessWidget {
  const HomePrayerHeroContextRow({
    super.key,
    required this.locationName,
    required this.isRefreshingLocation,
    required this.onRefreshLocation,
    this.ink,
    this.muted,
    this.chipBackground,
    this.chipBorder,
  });

  final String? locationName;
  final bool isRefreshingLocation;
  final VoidCallback? onRefreshLocation;
  final Color? ink;
  final Color? muted;
  final Color? chipBackground;
  final Color? chipBorder;

  /// Figma hijri / subcopy: rgba(255,255,255,0.698039)
  static const Color figmaMuted = Color.fromRGBO(255, 255, 255, 0.698);

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = context.tokens;
    final String locationLabel =
        PrayerLocationLabelFormatter.abbreviatedLocationLabel(
          locationName: locationName,
          l10n: context.l10n,
        );
    final String dateLine = formatHomeHeaderDateLine(
      date: DateTime.now(),
      languageCode: Localizations.localeOf(context).languageCode,
    );
    final Color dateColor = muted ?? figmaMuted;
    final Color cityColor = (ink ?? Colors.white).withValues(alpha: 0.8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 17,
        child: Row(
          children: [
            Expanded(
              child: TilawaInteractiveSurface(
                onTap: () => showHomeHijriCalendarSheet(context),
                borderRadius: BorderRadius.circular(tokens.radiusSmall),
                enableInk: false,
                enableStateLayer: false,
                semanticLabel: context.l10n.hijriCalendarOpenLabel,
                child: Text(
                  dateLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: dateColor,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                    fontSize: 11,
                    height: 16 / 11,
                  ),
                ),
              ),
            ),
            TilawaInteractiveSurface(
              onTap: isRefreshingLocation ? null : onRefreshLocation,
              borderRadius: BorderRadius.circular(tokens.radiusSmall),
              enableInk: false,
              enableStateLayer: false,
              semanticLabel: locationLabel,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Icon(
                    FluentIcons.location_24_filled,
                    size: 12,
                    color: dateColor,
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.28,
                    ),
                    child: Text(
                      locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cityColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        height: 16 / 11,
                      ),
                    ),
                  ),
                  if (isRefreshingLocation)
                    SizedBox(
                      width: tokens.iconSizeExtraSmall,
                      height: tokens.iconSizeExtraSmall,
                      child: TilawaLoadingIndicator(
                        centered: false,
                        strokeWidth: 1.5,
                        color: cityColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
