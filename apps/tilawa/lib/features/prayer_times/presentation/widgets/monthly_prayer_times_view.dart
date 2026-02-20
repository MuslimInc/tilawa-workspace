import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tilawa/core/extensions.dart';

import '../../domain/entities/entities.dart';
import '../bloc/prayer_times_bloc.dart';

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
    final ThemeData theme = Theme.of(context);

    return Column(
      children: [
        // Month selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _goToPreviousMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${_getMonthName(_currentMonth)} $_currentYear',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _goToNextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),

        // Table header
        Container(
          color: theme.colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              _buildHeaderCell(context.l10n.day),
              _buildHeaderCell(context.l10n.fajr, flex: 2),
              _buildHeaderCell(context.l10n.dhuhr, flex: 2),
              _buildHeaderCell(context.l10n.asr, flex: 2),
              _buildHeaderCell(context.l10n.maghrib, flex: 2),
              _buildHeaderCell(context.l10n.isha, flex: 2),
            ],
          ),
        ),

        // Prayer times list
        Expanded(
          child: BlocBuilder<PrayerTimesBloc, PrayerTimesState>(
            builder: (context, state) {
              if (state.monthlyPrayerTimes.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                itemCount: state.monthlyPrayerTimes.length,
                itemBuilder: (context, index) {
                  final PrayerTimeEntity prayerTimes =
                      state.monthlyPrayerTimes[index];
                  final bool isToday = _isToday(prayerTimes.date);
                  final isArabic =
                      Localizations.localeOf(context).languageCode == 'ar';

                  return Container(
                    color: isToday
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          )
                        : (index.isEven
                              ? theme.colorScheme.surface
                              : theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        _buildDataCell(
                          prayerTimes.date.day.toString(),
                          isToday: isToday,
                        ),
                        _buildDataCell(
                          widget.settings.use24HourFormat
                              ? _formatTime(prayerTimes.fajr)
                              : _formatTime12Hour(prayerTimes.fajr, isArabic),
                          flex: 2,
                        ),
                        _buildDataCell(
                          widget.settings.use24HourFormat
                              ? _formatTime(prayerTimes.dhuhr)
                              : _formatTime12Hour(prayerTimes.dhuhr, isArabic),
                          flex: 2,
                        ),
                        _buildDataCell(
                          widget.settings.use24HourFormat
                              ? _formatTime(prayerTimes.asr)
                              : _formatTime12Hour(prayerTimes.asr, isArabic),
                          flex: 2,
                        ),
                        _buildDataCell(
                          widget.settings.use24HourFormat
                              ? _formatTime(prayerTimes.maghrib)
                              : _formatTime12Hour(
                                  prayerTimes.maghrib,
                                  isArabic,
                                ),
                          flex: 2,
                        ),
                        _buildDataCell(
                          widget.settings.use24HourFormat
                              ? _formatTime(prayerTimes.isha)
                              : _formatTime12Hour(prayerTimes.isha, isArabic),
                          flex: 2,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text, {bool isToday = false, int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: isToday ? FontWeight.bold : null,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime12Hour(DateTime time, bool isArabic) {
    final int hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12
        ? (isArabic ? 'م' : 'PM')
        : (isArabic ? 'ص' : 'AM');
    return '${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String _getMonthName(int month) {
    final DateTime date = DateTime(DateTime.now().year, month, 1);
    final String languageCode = Localizations.localeOf(context).languageCode;
    return DateFormat.MMMM(languageCode).format(date);
  }
}
