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

  @override
  String get downloads => 'Downloads';

  @override
  String get playlists => 'Playlists';

  @override
  String get noDownloadsYet => 'No downloads yet';

  @override
  String get downloading => 'Downloading';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get download => 'Download';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAll => 'Delete All';

  @override
  String get clearAllDownloads => 'Clear All Downloads';

  @override
  String get clearAllDownloadsMessage =>
      'Are you sure you want to delete all downloaded surahs? This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get playAll => 'Play All';

  @override
  String get pauseAll => 'Pause All';

  @override
  String get playing => 'Playing';

  @override
  String get pending => 'Pending';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get completed => 'Completed';

  @override
  String get downloadProgress => 'Download Progress';

  @override
  String get fileSize => 'File Size';

  @override
  String get downloadedSize => 'Downloaded Size';

  @override
  String get playlistsScreen => 'Playlists Screen';

  @override
  String get back => 'Back';

  @override
  String get noPlaylistsYet => 'No playlists yet';

  @override
  String get createPlaylist => 'Create Playlist';

  @override
  String get retry => 'Retry';

  @override
  String get downloadStatusChecked => 'Download status checked';

  @override
  String get fileValidationCompleted => 'File validation completed';

  @override
  String get validDownloadsLoaded => 'Valid downloads loaded';

  @override
  String get playbackInitiated => 'Playback initiated';

  @override
  String get error => 'Error';

  @override
  String get settings => 'Settings';

  @override
  String get retryDownload => 'Retry Download';

  @override
  String get retryDownloadTooltip => 'Retry Download';

  @override
  String get viewDownloads => 'View Downloads';

  @override
  String get premium => 'Premium';

  @override
  String get premiumFeatures => 'Premium Features';

  @override
  String get unlimitedDownloads => 'Unlimited Downloads';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get highQualityAudio => 'High Quality Audio';

  @override
  String get adFreeExperience => 'Ad-Free Experience';

  @override
  String get prioritySupport => 'Priority Support';

  @override
  String get exclusiveContent => 'Exclusive Content';

  @override
  String get chooseYourPlan => 'Choose Your Plan';

  @override
  String get maybeLater => 'Maybe Later';

  @override
  String get upgradeNow => 'Upgrade Now';

  @override
  String get continueButton => 'Continue';

  @override
  String get premiumRequired => 'Premium Required';

  @override
  String get premiumRequiredMessage =>
      'This feature requires a premium subscription. Upgrade to unlock unlimited downloads and more!';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get refreshDownloads => 'Refresh Downloads';

  @override
  String downloadingSurah(String surahTitle, String reciterName) {
    return 'Downloading $surahTitle by $reciterName...';
  }

  @override
  String get deleteDownload => 'Delete Download';

  @override
  String deleteDownloadConfirmation(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String deleteAllDownloadsConfirmation(String reciterName) {
    return 'Are you sure you want to delete all downloads for $reciterName?';
  }

  @override
  String get surahs => 'surahs';

  @override
  String get signIn => 'Sign in';

  @override
  String get welcomeToMuzakri => 'Welcome to Muzakri';

  @override
  String get signInWithGoogleDescription =>
      'Sign in with your Google account to continue';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get googleSignInNotConfigured =>
      'Google Sign-In not configured. Please contact support.';

  @override
  String get networkError => 'Network error. Please check your connection.';

  @override
  String recitationsAvailable(int count) {
    return '$count recitation(s) available';
  }

  @override
  String loadingReciterSurahs(String reciterName) {
    return 'Loading $reciterName surahs...';
  }
}
