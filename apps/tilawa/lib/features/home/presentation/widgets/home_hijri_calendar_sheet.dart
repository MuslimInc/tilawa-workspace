import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/features/home/domain/home_hijri_date_formatter.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Opens a month-view Hijri calendar sheet from the Home hero date lines.
Future<void> showHomeHijriCalendarSheet(BuildContext context) {
  final ColorScheme colorScheme = Theme.of(context).colorScheme;
  return showTilawaModalBottomSheet<void>(
    context: context,
    // Root navigator so sheet covers [TilawaAdaptiveShell] bottom nav.
    useRootNavigator: true,
    backgroundColor: colorScheme.surface,
    shape: TilawaBottomSheetScaffold.modalShape(context),
    sheetSemanticsLabel: context.l10n.hijriCalendarTitle,
    builder: (context) => const HomeHijriCalendarSheet(),
  );
}

/// Month grid for the Umm al-Qura Hijri calendar.
class HomeHijriCalendarSheet extends StatefulWidget {
  const HomeHijriCalendarSheet({super.key});

  @override
  State<HomeHijriCalendarSheet> createState() => _HomeHijriCalendarSheetState();
}

class _HomeHijriCalendarSheetState extends State<HomeHijriCalendarSheet> {
  late int _year;
  late int _month;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    final HijriCalendar today = _calendarFor(DateTime.now());
    _year = today.hYear;
    _month = today.hMonth;
  }

  String _localeCode(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar' ? 'ar' : 'en';
  }

  HijriCalendar _calendarFor(DateTime date) {
    HijriCalendar.setLocal(_localeCode(context));
    return HijriCalendar.fromDate(date);
  }

  HijriCalendar _monthAnchor(BuildContext context) {
    HijriCalendar.setLocal(_localeCode(context));
    return HijriCalendar.addMonth(_year, _month);
  }

  void _shiftMonth(int delta) {
    var month = _month + delta;
    var year = _year;
    while (month < 1) {
      month += 12;
      year -= 1;
    }
    while (month > 12) {
      month -= 12;
      year += 1;
    }
    setState(() {
      _year = year;
      _month = month;
    });
  }

  bool _isSaturdayFirstWeek(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar';
  }

  List<int> _weekdayHeaderOrder(BuildContext context) {
    if (_isSaturdayFirstWeek(context)) {
      return const <int>[6, 7, 1, 2, 3, 4, 5];
    }
    return const <int>[7, 1, 2, 3, 4, 5, 6];
  }

  int _leadingEmptyCells(BuildContext context, DateTime firstDay) {
    if (_isSaturdayFirstWeek(context)) {
      return (firstDay.weekday + 1) % 7;
    }
    return firstDay.weekday % 7;
  }

  String _shortWeekdayLabel(BuildContext context, int dartWeekday) {
    final DateTime date = DateTime(2024, 1, 7).add(
      Duration(days: dartWeekday % 7),
    );
    final HijriCalendar calendar = _calendarFor(date);
    return calendar.format(
      calendar.hYear,
      calendar.hMonth,
      calendar.hDay,
      'DD',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final tokens = theme.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final HijriCalendar month = _monthAnchor(context);
    final HijriCalendar today = _calendarFor(DateTime.now());
    final int daysInMonth = month.getDaysInMonth(_year, _month);
    final DateTime firstGregorian = month.hijriToGregorian(_year, _month, 1);
    final int leading = _leadingEmptyCells(context, firstGregorian);
    final int cellCount = leading + daysInMonth;
    final int rowCount = (cellCount / 7).ceil();
    final List<int> weekdayOrder = _weekdayHeaderOrder(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          bottom: tokens.spaceLarge + context.keyboardInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TilawaSheetHandle(),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                tokens.spaceLarge,
                tokens.spaceMedium,
                tokens.spaceLarge,
                tokens.spaceSmall,
              ),
              child: Row(
                children: [
                  TilawaIconActionButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: context.l10n.hijriCalendarPreviousMonth,
                    onTap: () => _shiftMonth(-1),
                  ),
                  Expanded(
                    child: Text(
                      month.toFormat('MMMM yyyy'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TilawaIconActionButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: context.l10n.hijriCalendarNextMonth,
                    onTap: () => _shiftMonth(1),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: tokens.spaceLarge,
              ),
              child: Row(
                children: [
                  for (final int weekday in weekdayOrder)
                    Expanded(
                      child: Text(
                        _shortWeekdayLabel(context, weekday),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: tokens.spaceSmall),
            Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: tokens.spaceLarge,
              ),
              child: Column(
                children: [
                  for (int row = 0; row < rowCount; row++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: tokens.spaceExtraSmall,
                      ),
                      child: Row(
                        children: [
                          for (int col = 0; col < 7; col++)
                            Expanded(
                              child: _buildDayCell(
                                context,
                                row: row,
                                col: col,
                                leading: leading,
                                daysInMonth: daysInMonth,
                                today: today,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                tokens.spaceLarge,
                tokens.spaceSmall,
                tokens.spaceLarge,
                0,
              ),
              child: Text(
                formatHomeHijriDate(
                  date: DateTime.now(),
                  languageCode: _localeCode(context),
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context, {
    required int row,
    required int col,
    required int leading,
    required int daysInMonth,
    required HijriCalendar today,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final tokens = theme.tokens;
    final int index = row * 7 + col;
    final int day = index - leading + 1;

    if (day < 1 || day > daysInMonth) {
      return const SizedBox(height: 40);
    }

    final bool isToday =
        today.hYear == _year && today.hMonth == _month && today.hDay == day;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color? todayFill = isToday
        ? colorScheme.primary.withValues(alpha: isDark ? 0.28 : 0.14)
        : null;

    return SizedBox(
      height: 40,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: todayFill,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceExtraSmall),
            child: Text(
              '$day',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
