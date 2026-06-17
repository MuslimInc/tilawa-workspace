import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/entities/home_prayer_slot.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_bloc.dart';
import 'package:tilawa/features/home/presentation/bloc/home_dashboard_state.dart';
import 'package:tilawa/features/prayer_times/domain/entities/prayer_time_entity.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Compact horizontal glance at today's main prayer times.
class HomePrayerDayStrip extends StatelessWidget {
  const HomePrayerDayStrip({super.key, required this.onOpenPrayer});

  final VoidCallback onOpenPrayer;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeDashboardBloc, HomeDashboardState>(
      builder: (context, state) {
        final List<HomePrayerSlot> slots = switch (state) {
          HomeDashboardLoaded(:final dashboard) => dashboard.todayPrayers,
          _ => const [],
        };
        if (slots.isEmpty) {
          return const SizedBox.shrink();
        }

        final tokens = context.tokens;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceSmall,
          children: [
            Row(
              children: [
                Expanded(
                  child: TilawaSectionTitle.overline(
                    title: context.l10n.homePrayerStripTitle,
                  ),
                ),
                _PrayerStripViewAllLink(onPressed: onOpenPrayer),
              ],
            ),
            Semantics(
              label: context.l10n.homePrayerStripTitle,
              child: ExcludeSemantics(
                child: TilawaQuickFilterBar(
                  children: [
                    for (final HomePrayerSlot slot in slots)
                      TilawaSelectionPill(
                        label: _slotLabel(context, slot),
                        selected: slot.isNext,
                        style: TilawaSelectionPillStyle.catalog,
                        elevatedWhenSelected: false,
                        unselectedForegroundColor: slot.hasPassed
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : null,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _slotLabel(BuildContext context, HomePrayerSlot slot) {
    final String name = _localizedPrayerName(context, slot.type);
    final String time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(slot.time));
    return '$name · $time';
  }
}

String _localizedPrayerName(BuildContext context, PrayerType type) {
  return switch (type) {
    PrayerType.fajr => context.l10n.fajr,
    PrayerType.sunrise => context.l10n.sunrise,
    PrayerType.dhuhr => context.l10n.dhuhr,
    PrayerType.asr => context.l10n.asr,
    PrayerType.maghrib => context.l10n.maghrib,
    PrayerType.isha => context.l10n.isha,
    PrayerType.midnight => context.l10n.midnight,
    PrayerType.lastThird => context.l10n.lastThird,
  };
}

class _PrayerStripViewAllLink extends StatelessWidget {
  const _PrayerStripViewAllLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.onSurfaceVariant,
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
        minimumSize: Size(
          tokens.minInteractiveDimension,
          tokens.minInteractiveDimension,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        context.l10n.homePrayerStripViewAll,
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
