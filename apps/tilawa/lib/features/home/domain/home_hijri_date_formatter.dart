import 'package:hijri/hijri_calendar.dart';

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
