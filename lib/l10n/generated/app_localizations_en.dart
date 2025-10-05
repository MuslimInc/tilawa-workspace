// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Muzakri';

  @override
  String get reciters => 'Reciters';

  @override
  String get searchReciters => 'Search reciters...';

  @override
  String get loadingReciters => 'Loading reciters...';

  @override
  String get noRecitersFound => 'No reciters found';

  @override
  String get noRecitersMatchSearch => 'No reciters match your search';

  @override
  String get retry => 'Retry';

  @override
  String get error => 'Error';

  @override
  String get filteredByLetter => 'Filtered by letter:';

  @override
  String get selectRecitation => 'Select Recitation';

  @override
  String get loadingSurahList => 'Loading surah list...';

  @override
  String get noSurahsAvailable => 'No surahs available';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get currentPlaying => 'Now Playing';

  @override
  String get duration => 'Duration';

  @override
  String get position => 'Position';
}
