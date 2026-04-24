/// Maps mp3quran.net reciter server paths to everyayah.com verse audio folders.
///
/// The everyayah.com CDN serves per-verse audio at:
///   https://everyayah.com/data/{reciterFolder}/{surah:03d}{ayah:03d}.mp3
///
/// This mapping covers the most popular reciters. For unmapped reciters,
/// [defaultReciterFolder] is used as a fallback.
class ReciterAudioMapping {
  ReciterAudioMapping._();

  static const String defaultReciterFolder = 'Alafasy_128kbps';

  /// everyayah.com serves per-verse MP3s at /data/{folder}/{surah}{ayah}.mp3.
  /// verses.quran.com uses the same path format but returns 404 for all files.
  static const String _cdnBase = 'https://everyayah.com/data';

  /// Maps server URL segments (from mp3quran.net moshaf.server) to
  /// everyayah.com reciter folder names.
  ///
  /// Key: a recognizable substring from the mp3quran.net server URL
  /// (e.g., "afs" from "https://server8.mp3quran.net/afs/").
  /// Value: everyayah.com CDN folder name.
  ///
  /// Reciters not listed here fall back to [defaultReciterFolder].
  static const Map<String, String> _serverToFolder = {
    // Mishary Rashid Al-Afasy
    'afs': 'Alafasy_128kbps',
    'Alafasy': 'Alafasy_128kbps',

    // Abdul-Basit Abdul-Samad (Murattal)
    'basit/Mujawwad': 'Abdul_Basit_Murattal_192kbps',
    'basit': 'Abdul_Basit_Murattal_192kbps',
    'AbdulSamworthy': 'Abdul_Basit_Murattal_192kbps',

    // Mahmoud Khalil Al-Husary
    'husary': 'Husary_128kbps',
    'Husary': 'Husary_128kbps',

    // Mohamed Siddiq El-Minshawi (Murattal)
    'minsh': 'Minshawi_Murattal_128kbps',
    'Minshawi': 'Minshawi_Murattal_128kbps',

    // Abdur-Rahman as-Sudais — folder differs from other CDNs
    'sds': 'Abdurrahmaan_As-Sudais_192kbps',
    'Sudais': 'Abdurrahmaan_As-Sudais_192kbps',

    // Saad Al-Ghamdi
    'ghamdi': 'Ghamadi_40kbps',
    'Ghamdi': 'Ghamadi_40kbps',

    // Abu Bakr Al-Shatri
    'shatri': 'Abu_Bakr_Ash-Shaatree_128kbps',
    'Shatri': 'Abu_Bakr_Ash-Shaatree_128kbps',

    // Ahmad ibn Ali Al-Ajamy
    'ajm': 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net',
    'Ajamy': 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net',

    // Ali Al-Hudhaify
    'hudhify': 'Hudhaify_128kbps',
    'Hudhaify': 'Hudhaify_128kbps',

    // Mohammad Al-Tablawi
    'tblawi': 'Mohammad_al_Tablaway_128kbps',
    'Tablawi': 'Mohammad_al_Tablaway_128kbps',

    // Nasser Al-Qatami
    'qtm': 'Nasser_Alqatami_128kbps',
    'Qatami': 'Nasser_Alqatami_128kbps',

    // Yasser Al-Dosari
    'yasser': 'Yasser_Ad-Dussary_128kbps',
    'Dosari': 'Yasser_Ad-Dussary_128kbps',

    // Fares Abbad
    'frs_a': 'Fares_Abbad_64kbps',
    'Abbad': 'Fares_Abbad_64kbps',

    // Ibrahim Al-Akhdar
    'akdr': 'Ibrahim_Akhdar_32kbps',
    'Akhdar': 'Ibrahim_Akhdar_32kbps',

    // Ali Jaber
    'a_jbr': 'Ali_Jaber_64kbps',
    'Jaber': 'Ali_Jaber_64kbps',
  };

  /// Maps server URL segments to Quran.com recitation IDs.
  static const Map<String, int> _serverToRecitationId = {
    'afs': 7,
    'Alafasy': 7,
    'basit/Mujawwad': 1,
    'basit': 1,
    'AbdulSamworthy': 1,
    'husary': 5,
    'Husary': 5,
    'minsh': 8,
    'Minshawi': 8,
    'sds': 3,
    'Sudais': 3,
    'ghamdi': 4,
    'shatri': 10,
    'yasser': 12,
  };

  /// Resolves a Quran.com reciter folder from the mp3quran.net server URL.
  ///
  /// Tries to match any key in [_serverToFolder] as a substring of [serverUrl].
  /// Returns [defaultReciterFolder] if no match is found.
  static String resolveFolder(String serverUrl) {
    for (final entry in _serverToFolder.entries) {
      if (serverUrl.contains(entry.key)) {
        return entry.value;
      }
    }
    return defaultReciterFolder;
  }

  /// Builds the full URL for a specific verse audio file on the Quran.com CDN.
  static String buildVerseAudioUrl({
    required String reciterFolder,
    required int surahNumber,
    required int ayahNumber,
  }) {
    final surah = surahNumber.toString().padLeft(3, '0');
    final ayah = ayahNumber.toString().padLeft(3, '0');
    return '$_cdnBase/$reciterFolder/$surah$ayah.mp3';
  }

  /// Returns the Quran.com recitation ID for the given mp3quran server URL.
  static int? resolveRecitationId(String serverUrl) {
    for (final entry in _serverToRecitationId.entries) {
      if (serverUrl.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Whether [serverUrl] maps to a known Quran.com reciter.
  static bool isReciterMapped(String serverUrl) {
    return _serverToFolder.entries.any(
      (entry) => serverUrl.contains(entry.key),
    );
  }
}
