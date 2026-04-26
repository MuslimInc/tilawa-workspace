import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/entities.dart';
import '../bloc/prayer_times_bloc.dart';

/// A view displaying prayer times for an entire month in a table format.
class MonthlyPrayerTimesView extends StatefulWidget {
  const MonthlyPrayerTimesView({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.settings,
  });

  final double latitude;
  final double longitude;
  final PrayerSettingsEntity settings;

  @override
  State<MonthlyPrayerTimesView> createState() => _MonthlyPrayerTimesViewState();
}

class _MonthlyPrayerTimesViewState extends State<MonthlyPrayerTimesView> {
  late int _currentYear;
  late int _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;
    _loadMonthlyPrayerTimes();
  }

  void _loadMonthlyPrayerTimes() {
    context.read<PrayerTimesBloc>().add(
      PrayerTimesEvent.loadMonthlyPrayerTimes(
        year: _currentYear,
        month: _currentMonth,
      ),
    );
  }

  void _goToPreviousMonth() {
    setState(() {
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
    });
    _loadMonthlyPrayerTimes();
  }

  void _goToNextMonth() {
    setState(() {
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
    });
    _loadMonthlyPrayerTimes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;

    return Column(
      children: [
        _MonthSelector(
          year: _currentYear,
          month: _currentMonth,
          onPrevious: _goToPreviousMonth,
          onNext: _goToNextMonth,
        ),
        SizedBox(height: tokens.spaceSmall),
        const _TableHeader(),
        Expanded(
          child: BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
            buildWhen: (previous, current) =>
                previous.monthlyPrayerTimes != current.monthlyPrayerTimes,
            builder: (context, state) {
              if (state.monthlyPrayerTimes.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                itemCount: state.monthlyPrayerTimes.length,
                padding: EdgeInsets.only(
                  top: tokens.spaceExtraSmall,
                  bottom: tokens.spaceLarge,
                ),
                itemBuilder: (context, index) {
                  final prayerTimes = state.monthlyPrayerTimes[index];
                  final bool isToday = _isToday(prayerTimes.date);

                  return _TableRow(
                    prayerTimes: prayerTimes,
                    isToday: isToday,
                    index: index,
                    use24HourFormat: widget.settings.use24HourFormat,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.year,
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final int year;
  final int month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    final String monthName = _getMonthName(context, month);

    return Container(
      margin: EdgeInsets.all(tokens.spaceLarge),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSmall,
        vertical: tokens.spaceExtraSmall,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLarge),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: tokens.opacityMedium,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            color: colorScheme.primary,
          ),
          Text(
            '$monthName $year',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  String _getMonthName(BuildContext context, int month) {
    final DateTime date = DateTime(DateTime.now().year, month, 1);
    final String languageCode = Localizations.localeOf(context).languageCode;
    return DateFormat.MMMM(languageCode).format(date);
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      padding: EdgeInsets.symmetric(
        vertical: tokens.spaceSmall,
        horizontal: tokens.spaceExtraSmall,
      ),
      child: Row(
        children: [
          _buildHeaderCell(context, context.l10n.day),
          _buildHeaderCell(context, context.l10n.fajr, flex: 2),
          _buildHeaderCell(context, context.l10n.dhuhr, flex: 2),
          _buildHeaderCell(context, context.l10n.asr, flex: 2),
          _buildHeaderCell(context, context.l10n.maghrib, flex: 2),
          _buildHeaderCell(context, context.l10n.isha, flex: 2),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.prayerTimes,
    required this.isToday,
    required this.index,
    required this.use24HourFormat,
  });

  final PrayerTimeEntity prayerTimes;
  final bool isToday;
  final int index;
  final bool use24HourFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.tokens;
    final colorScheme = theme.colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      color: isToday
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : (index.isEven
                ? Colors.transparent
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)),
      padding: EdgeInsets.symmetric(
        vertical: tokens.spaceSmall,
        horizontal: tokens.spaceExtraSmall,
      ),
      child: Row(
        children: [
          _buildDataCell(
            context,
            prayerTimes.date.day.toString(),
            isToday: isToday,
          ),
          _buildDataCell(
            context,
            use24HourFormat
                ? _formatTime(prayerTimes.fajr)
                : _formatTime12Hour(prayerTimes.fajr, isArabic),
            flex: 2,
            isToday: isToday,
          ),
          _buildDataCell(
            context,
            use24HourFormat
                ? _formatTime(prayerTimes.dhuhr)
                : _formatTime12Hour(prayerTimes.dhuhr, isArabic),
            flex: 2,
            isToday: isToday,
          ),
          _buildDataCell(
            context,
            use24HourFormat
                ? _formatTime(prayerTimes.asr)
                : _formatTime12Hour(prayerTimes.asr, isArabic),
            flex: 2,
            isToday: isToday,
          ),
          _buildDataCell(
            context,
            use24HourFormat
                ? _formatTime(prayerTimes.maghrib)
                : _formatTime12Hour(prayerTimes.maghrib, isArabic),
            flex: 2,
            isToday: isToday,
          ),
          _buildDataCell(
            context,
            use24HourFormat
                ? _formatTime(prayerTimes.isha)
                : _formatTime12Hour(prayerTimes.isha, isArabic),
            flex: 2,
            isToday: isToday,
          ),
        ],
      ),
    );
  }

  Widget _buildDataCell(
    BuildContext context,
    String text, {
    bool isToday = false,
    int flex = 1,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
          color: isToday
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime12Hour(DateTime time, bool isArabic) {
    final int hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12
        ? (isArabic ? 'م' : 'PM')
        : (isArabic ? 'ص' : 'AM');
    final String formattedHour = hour == 0 ? '12' : hour.toString();
    return '$formattedHour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
