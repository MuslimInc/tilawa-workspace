import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

/// Formats a Gregorian [date] as a Hijri calendar line for Home hero chrome.
///
/// Uses Umm al-Qura conversion via [HijriCalendar]. Month names follow the
/// active app locale (`ar` vs default English).
String formatHomeHijriDate({
  required DateTime date,
  required String languageCode,
}) {
  final String locale = languageCode == 'ar' ? 'ar' : 'en';
  HijriCalendar.setLocal(locale);
  return HijriCalendar.fromDate(date).toFormat('d MMMM yyyy');
}

/// Weekday + Hijri line for the immersive header zone (Figma date row).
///
/// Example (en): `Wednesday, 16 Ramadan 1446`.
String formatHomeHeaderDateLine({
  required DateTime date,
  required String languageCode,
}) {
  final String locale = languageCode == 'ar' ? 'ar' : 'en';
  final String weekday = DateFormat.EEEE(locale).format(date);
  final String hijri = formatHomeHijriDate(
    date: date,
    languageCode: languageCode,
  );
  return '$weekday, $hijri';
}
