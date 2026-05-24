/// Maps mp3quran.net reciter server paths to everyayah.com verse audio folders.
///
/// The everyayah.com CDN serves per-verse audio at:
///   https://everyayah.com/data/{reciterFolder}/{surah:03d}{ayah:03d}.mp3
abstract final class ReciterAudioCatalog {
  ReciterAudioCatalog._();

  static const String defaultReciterFolder = 'Alafasy_128kbps';

  static const String _cdnBase = 'https://everyayah.com/data';

  static const Map<String, String> _serverToFolder = {
    'afs': 'Alafasy_128kbps',
    'Alafasy': 'Alafasy_128kbps',
    'basit/Mujawwad': 'Abdul_Basit_Murattal_192kbps',
    'basit': 'Abdul_Basit_Murattal_192kbps',
    'AbdulSamworthy': 'Abdul_Basit_Murattal_192kbps',
    'husary': 'Husary_128kbps',
    'Husary': 'Husary_128kbps',
    'minsh': 'Minshawi_Murattal_128kbps',
    'Minshawi': 'Minshawi_Murattal_128kbps',
    'sds': 'Abdurrahmaan_As-Sudais_192kbps',
    'Sudais': 'Abdurrahmaan_As-Sudais_192kbps',
    'ghamdi': 'Ghamadi_40kbps',
    'Ghamdi': 'Ghamadi_40kbps',
    'shatri': 'Abu_Bakr_Ash-Shaatree_128kbps',
    'Shatri': 'Abu_Bakr_Ash-Shaatree_128kbps',
    'ajm': 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net',
    'Ajamy': 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net',
    'hudhify': 'Hudhaify_128kbps',
    'Hudhaify': 'Hudhaify_128kbps',
    'tblawi': 'Mohammad_al_Tablaway_128kbps',
    'Tablawi': 'Mohammad_al_Tablaway_128kbps',
    'qtm': 'Nasser_Alqatami_128kbps',
    'Qatami': 'Nasser_Alqatami_128kbps',
    'yasser': 'Yasser_Ad-Dussary_128kbps',
    'Dosari': 'Yasser_Ad-Dussary_128kbps',
    'frs_a': 'Fares_Abbad_64kbps',
    'Abbad': 'Fares_Abbad_64kbps',
    'akdr': 'Ibrahim_Akhdar_32kbps',
    'Akhdar': 'Ibrahim_Akhdar_32kbps',
    'a_jbr': 'Ali_Jaber_64kbps',
    'Jaber': 'Ali_Jaber_64kbps',
  };

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

  static String resolveFolder(String serverUrl) {
    for (final MapEntry<String, String> entry in _serverToFolder.entries) {
      if (serverUrl.contains(entry.key)) {
        return entry.value;
      }
    }
    return defaultReciterFolder;
  }

  static String buildVerseAudioUrl({
    required String reciterFolder,
    required int surahNumber,
    required int ayahNumber,
  }) {
    final String surah = surahNumber.toString().padLeft(3, '0');
    final String ayah = ayahNumber.toString().padLeft(3, '0');
    return '$_cdnBase/$reciterFolder/$surah$ayah.mp3';
  }

  static int? resolveRecitationId(String serverUrl) {
    for (final MapEntry<String, int> entry in _serverToRecitationId.entries) {
      if (serverUrl.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static bool isReciterMapped(String serverUrl) {
    return _serverToFolder.entries.any(
      (MapEntry<String, String> entry) => serverUrl.contains(entry.key),
    );
  }
}
