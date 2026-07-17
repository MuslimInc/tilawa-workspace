/// Bilingual Home daily inspiration catalog (30-day rotation).
/// One ayah + dua pair for Home inspiration.
final class HomeDailyInspirationEntry {
  const HomeDailyInspirationEntry({
    required this.surahNumber,
    required this.ayahNumber,
    required this.ayahBodyAr,
    required this.ayahBodyEn,
    required this.ayahReferenceAr,
    required this.ayahReferenceEn,
    required this.duaBodyAr,
    required this.duaBodyEn,
    required this.duaReferenceAr,
    required this.duaReferenceEn,
  });

  final int surahNumber;
  final int ayahNumber;
  final String ayahBodyAr;
  final String ayahBodyEn;
  final String ayahReferenceAr;
  final String ayahReferenceEn;
  final String duaBodyAr;
  final String duaBodyEn;
  final String duaReferenceAr;
  final String duaReferenceEn;

  String ayahBody({required bool arabic}) => arabic ? ayahBodyAr : ayahBodyEn;

  String ayahReference({required bool arabic}) =>
      arabic ? ayahReferenceAr : ayahReferenceEn;

  String duaBody({required bool arabic}) => arabic ? duaBodyAr : duaBodyEn;

  String duaReference({required bool arabic}) =>
      arabic ? duaReferenceAr : duaReferenceEn;
}

/// Number of ayah/dua pairs in the rotation catalog.
final int homeDailyInspirationCatalogLength =
    homeDailyInspirationEntries.length;

/// Catalog index for rotating Home daily inspiration content.
int homeDailyInspirationCatalogIndex(DateTime date) {
  final int dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
  return dayOfYear % homeDailyInspirationCatalogLength;
}

/// Verse coordinates for each catalog entry.
List<({int surahNumber, int ayahNumber})> get homeDailyAyahCatalogVerses =>
    homeDailyInspirationEntries
        .map(
          (e) => (surahNumber: e.surahNumber, ayahNumber: e.ayahNumber),
        )
        .toList(growable: false);

/// Full bilingual catalog — one entry per day in a 30-day cycle.
const List<HomeDailyInspirationEntry> homeDailyInspirationEntries = [
  HomeDailyInspirationEntry(
    surahNumber: 2,
    ayahNumber: 43,
    ayahBodyAr:
        'وَأَقِيمُوا الصَّلَاةَ وَآتُوا الزَّكَاةَ وَارْكَعُوا مَعَ الرَّاكِعِينَ',
    ayahBodyEn:
        'And establish prayer and give zakah and bow with those who bow',
    ayahReferenceAr: 'البقرة: ٤٣',
    ayahReferenceEn: 'Al-Baqarah 2:43',
    duaBodyAr:
        'اللَّهُمَّ اجْعَلْنِي مِنَ الَّذِينَ إِذَا أَحْسَنُوا اسْتَبْشَرُوا، وَإِذَا أَسَاءُوا اسْتَغْفَرُوا',
    duaBodyEn:
        'O Allah, make me among those who rejoice when they do good, and seek forgiveness when they do wrong',
    duaReferenceAr: 'ابن ماجه',
    duaReferenceEn: 'Ibn Majah',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 2,
    ayahNumber: 152,
    ayahBodyAr: 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
    ayahBodyEn:
        'So remember Me; I will remember you. And be grateful to Me and do not deny Me',
    ayahReferenceAr: 'البقرة: ١٥٢',
    ayahReferenceEn: 'Al-Baqarah 2:152',
    duaBodyAr:
        'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ',
    duaBodyEn:
        'My Lord, forgive me and accept my repentance. Indeed, You are the Accepting of repentance, the Merciful',
    duaReferenceAr: 'أبو داود والترمذي',
    duaReferenceEn: 'Abu Dawud & Tirmidhi',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 29,
    ayahNumber: 45,
    ayahBodyAr: 'إِنَّ الصَّلَاةَ تَنْهَىٰ عَنِ الْفَحْشَاءِ وَالْمُنكَرِ',
    ayahBodyEn: 'Indeed, prayer prohibits immorality and wrongdoing',
    ayahReferenceAr: 'العنكبوت: ٤٥',
    ayahReferenceEn: 'Al-‘Ankabut 29:45',
    duaBodyAr:
        'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
    duaBodyEn: 'O Allah, help me remember You, thank You, and worship You well',
    duaReferenceAr: 'أبو داود والنسائي',
    duaReferenceEn: 'Abu Dawud & Nasa’i',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 2,
    ayahNumber: 286,
    ayahBodyAr: 'رَبَّنَا لَا تُؤَاخِذْنَا إِن نَّسِينَا أَوْ أَخْطَأْنَا',
    ayahBodyEn:
        'Our Lord, do not impose blame upon us if we forget or make a mistake',
    ayahReferenceAr: 'البقرة: ٢٨٦',
    ayahReferenceEn: 'Al-Baqarah 2:286',
    duaBodyAr: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ',
    duaBodyEn: 'O Allah, I seek refuge in You from anxiety and sorrow',
    duaReferenceAr: 'البخاري',
    duaReferenceEn: 'Bukhari',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 3,
    ayahNumber: 8,
    ayahBodyAr: 'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا',
    ayahBodyEn: 'Our Lord, let not our hearts deviate after You have guided us',
    ayahReferenceAr: 'آل عمران: ٨',
    ayahReferenceEn: 'Aal ‘Imran 3:8',
    duaBodyAr: 'يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ',
    duaBodyEn: 'O Turner of hearts, keep my heart firm upon Your religion',
    duaReferenceAr: 'الترمذي',
    duaReferenceEn: 'Tirmidhi',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 3,
    ayahNumber: 173,
    ayahBodyAr: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
    ayahBodyEn:
        'Sufficient for us is Allah, and He is the best Disposer of affairs',
    ayahReferenceAr: 'آل عمران: ١٧٣',
    ayahReferenceEn: 'Aal ‘Imran 3:173',
    duaBodyAr:
        'اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ، وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ',
    duaBodyEn:
        'O Allah, suffice me with what is lawful against what is unlawful, and enrich me by Your favor from all others',
    duaReferenceAr: 'الترمذي',
    duaReferenceEn: 'Tirmidhi',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 7,
    ayahNumber: 23,
    ayahBodyAr:
        'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ',
    ayahBodyEn:
        'Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers',
    ayahReferenceAr: 'الأعراف: ٢٣',
    ayahReferenceEn: 'Al-A‘raf 7:23',
    duaBodyAr:
        'أَسْتَغْفِرُ اللَّهَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ',
    duaBodyEn:
        'I seek forgiveness of Allah, there is no god but He, the Living, the Sustainer, and I repent to Him',
    duaReferenceAr: 'أبو داود والترمذي',
    duaReferenceEn: 'Abu Dawud & Tirmidhi',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 14,
    ayahNumber: 40,
    ayahBodyAr: 'رَبِّ اجْعَلْنِي مُقِيمَ الصَّلَاةِ وَمِن ذُرِّيَّتِي',
    ayahBodyEn:
        'My Lord, make me an establisher of prayer, and from my descendants',
    ayahReferenceAr: 'إبراهيم: ٤٠',
    ayahReferenceEn: 'Ibrahim 14:40',
    duaBodyAr: 'اللَّهُمَّ بَارِكْ لِي فِي أَهْلِي، وَبَارِكْ لَهُمْ فِيَّ',
    duaBodyEn: 'O Allah, bless me in my family, and bless them in me',
    duaReferenceAr: 'الطبراني',
    duaReferenceEn: 'Tabarani',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 17,
    ayahNumber: 24,
    ayahBodyAr: 'وَقُل رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
    ayahBodyEn:
        'And say: My Lord, have mercy upon them as they brought me up when I was small',
    ayahReferenceAr: 'الإسراء: ٢٤',
    ayahReferenceEn: 'Al-Isra 17:24',
    duaBodyAr: 'رَبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
    duaBodyEn:
        'My Lord, have mercy upon them as they raised me when I was small',
    duaReferenceAr: 'القرآن',
    duaReferenceEn: 'Qur’an',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 18,
    ayahNumber: 10,
    ayahBodyAr:
        'رَبَّنَا آتِنَا مِن لَّدُنكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا',
    ayahBodyEn:
        'Our Lord, grant us from Yourself mercy and prepare for us from our affair right guidance',
    ayahReferenceAr: 'الكهف: ١٠',
    ayahReferenceEn: 'Al-Kahf 18:10',
    duaBodyAr: 'اللَّهُمَّ اهْدِنِي وَسَدِّدْنِي',
    duaBodyEn: 'O Allah, guide me and set me right',
    duaReferenceAr: 'مسلم',
    duaReferenceEn: 'Muslim',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 20,
    ayahNumber: 114,
    ayahBodyAr: 'وَقُل رَّبِّ زِدْنِي عِلْمًا',
    ayahBodyEn: 'And say: My Lord, increase me in knowledge',
    ayahReferenceAr: 'طه: ١١٤',
    ayahReferenceEn: 'Ta-Ha 20:114',
    duaBodyAr:
        'اللَّهُمَّ انْفَعْنِي بِمَا عَلَّمْتَنِي، وَعَلِّمْنِي مَا يَنْفَعُنِي',
    duaBodyEn:
        'O Allah, benefit me by what You taught me, and teach me what benefits me',
    duaReferenceAr: 'الترمذي وابن ماجه',
    duaReferenceEn: 'Tirmidhi & Ibn Majah',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 21,
    ayahNumber: 87,
    ayahBodyAr:
        'لَا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
    ayahBodyEn:
        'There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers',
    ayahReferenceAr: 'الأنبياء: ٨٧',
    ayahReferenceEn: 'Al-Anbiya 21:87',
    duaBodyAr:
        'لَا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
    duaBodyEn:
        'There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers',
    duaReferenceAr: 'القرآن',
    duaReferenceEn: 'Qur’an',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 23,
    ayahNumber: 118,
    ayahBodyAr: 'وَقُل رَّبِّ اغْفِرْ وَارْحَمْ وَأَنتَ خَيْرُ الرَّاحِمِينَ',
    ayahBodyEn:
        'And say: My Lord, forgive and have mercy, and You are the best of the merciful',
    ayahReferenceAr: 'المؤمنون: ١١٨',
    ayahReferenceEn: 'Al-Mu’minun 23:118',
    duaBodyAr:
        'اللَّهُمَّ اغْفِرْ لِي ذَنْبِي كُلَّهُ، دِقَّهُ وَجِلَّهُ، وَأَوَّلَهُ وَآخِرَهُ',
    duaBodyEn:
        'O Allah, forgive me all my sins, the small and the great, the first and the last',
    duaReferenceAr: 'مسلم',
    duaReferenceEn: 'Muslim',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 25,
    ayahNumber: 74,
    ayahBodyAr:
        'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ',
    ayahBodyEn:
        'Our Lord, grant us from among our wives and offspring comfort to our eyes',
    ayahReferenceAr: 'الفرقان: ٧٤',
    ayahReferenceEn: 'Al-Furqan 25:74',
    duaBodyAr:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
    duaBodyEn:
        'O Allah, I ask You for guidance, piety, chastity, and self-sufficiency',
    duaReferenceAr: 'مسلم',
    duaReferenceEn: 'Muslim',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 26,
    ayahNumber: 83,
    ayahBodyAr: 'رَبِّ هَبْ لِي حُكْمًا وَأَلْحِقْنِي بِالصَّالِحِينَ',
    ayahBodyEn: 'My Lord, grant me authority and join me with the righteous',
    ayahReferenceAr: 'الشعراء: ٨٣',
    ayahReferenceEn: 'Ash-Shu‘ara 26:83',
    duaBodyAr:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنَ الْخَيْرِ كُلِّهِ عَاجِلِهِ وَآجِلِهِ',
    duaBodyEn: 'O Allah, I ask You for all that is good, sooner and later',
    duaReferenceAr: 'ابن ماجه',
    duaReferenceEn: 'Ibn Majah',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 27,
    ayahNumber: 19,
    ayahBodyAr:
        'رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ الَّتِي أَنْعَمْتَ عَلَيَّ',
    ayahBodyEn:
        'My Lord, enable me to be grateful for Your favor which You have bestowed upon me',
    ayahReferenceAr: 'النمل: ١٩',
    ayahReferenceEn: 'An-Naml 27:19',
    duaBodyAr:
        'اللَّهُمَّ مَا أَصْبَحَ بِي مِنْ نِعْمَةٍ فَمِنْكَ وَحْدَكَ لَا شَرِيكَ لَكَ',
    duaBodyEn:
        'O Allah, whatever blessing I have received is from You alone, without partner',
    duaReferenceAr: 'أبو داود والنسائي',
    duaReferenceEn: 'Abu Dawud & Nasa’i',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 28,
    ayahNumber: 24,
    ayahBodyAr: 'رَبِّ إِنِّي لِمَا أَنزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ',
    ayahBodyEn:
        'My Lord, indeed I am, for whatever good You would send down to me, in need',
    ayahReferenceAr: 'القصص: ٢٤',
    ayahReferenceEn: 'Al-Qasas 28:24',
    duaBodyAr:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ وَرَحْمَتِكَ، فَإِنَّهُ لَا يَمْلِكُهُمَا إِلَّا أَنْتَ',
    duaBodyEn:
        'O Allah, I ask You of Your bounty and mercy, for none owns them but You',
    duaReferenceAr: 'الطبراني',
    duaReferenceEn: 'Tabarani',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 33,
    ayahNumber: 41,
    ayahBodyAr:
        'يَا أَيُّهَا الَّذِينَ آمَنُوا اذْكُرُوا اللَّهَ ذِكْرًا كَثِيرًا',
    ayahBodyEn: 'O you who have believed, remember Allah with much remembrance',
    ayahReferenceAr: 'الأحزاب: ٤١',
    ayahReferenceEn: 'Al-Ahzab 33:41',
    duaBodyAr: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
    duaBodyEn:
        'Glory be to Allah and praise be to Him; glory be to Allah, the Magnificent',
    duaReferenceAr: 'البخاري ومسلم',
    duaReferenceEn: 'Bukhari & Muslim',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 39,
    ayahNumber: 53,
    ayahBodyAr:
        'قُلْ يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَىٰ أَنفُسِهِمْ لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ',
    ayahBodyEn:
        'Say: O My servants who have transgressed against themselves, do not despair of the mercy of Allah',
    ayahReferenceAr: 'الزمر: ٥٣',
    ayahReferenceEn: 'Az-Zumar 39:53',
    duaBodyAr:
        'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ',
    duaBodyEn:
        'O Allah, You are my Lord; there is no god but You. You created me and I am Your servant',
    duaReferenceAr: 'البخاري',
    duaReferenceEn: 'Bukhari',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 40,
    ayahNumber: 44,
    ayahBodyAr:
        'وَأُفَوِّضُ أَمْرِي إِلَى اللَّهِ إِنَّ اللَّهَ بَصِيرٌ بِالْعِبَادِ',
    ayahBodyEn:
        'And I entrust my affair to Allah. Indeed, Allah is Seeing of His servants',
    ayahReferenceAr: 'غافر: ٤٤',
    ayahReferenceEn: 'Ghafir 40:44',
    duaBodyAr:
        'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
    duaBodyEn:
        'Allah is sufficient for me; there is no god but He. Upon Him I rely, and He is Lord of the Great Throne',
    duaReferenceAr: 'أبو داود',
    duaReferenceEn: 'Abu Dawud',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 46,
    ayahNumber: 15,
    ayahBodyAr:
        'رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ الَّتِي أَنْعَمْتَ عَلَيَّ وَعَلَىٰ وَالِدَيَّ وَأَنْ أَعْمَلَ صَالِحًا تَرْضَاهُ',
    ayahBodyEn:
        'My Lord, enable me to be grateful for Your favor which You have bestowed upon me and upon my parents and to do righteousness that You approve',
    ayahReferenceAr: 'الأحقاف: ١٥',
    ayahReferenceEn: 'Al-Ahqaf 46:15',
    duaBodyAr:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ',
    duaBodyEn:
        'O Allah, I ask You for pardon and well-being in this world and the Hereafter',
    duaReferenceAr: 'ابن ماجه',
    duaReferenceEn: 'Ibn Majah',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 59,
    ayahNumber: 18,
    ayahBodyAr:
        'يَا أَيُّهَا الَّذِينَ آمَنُوا اتَّقُوا اللَّهَ وَلْتَنظُرْ نَفْسٌ مَّا قَدَّمَتْ لِغَدٍ',
    ayahBodyEn:
        'O you who have believed, fear Allah. And let every soul look to what it has put forth for tomorrow',
    ayahReferenceAr: 'الحشر: ١٨',
    ayahReferenceEn: 'Al-Hashr 59:18',
    duaBodyAr:
        'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، وَمِنْ عَذَابِ جَهَنَّمَ',
    duaBodyEn:
        'O Allah, I seek refuge in You from the punishment of the grave and from the punishment of Hell',
    duaReferenceAr: 'البخاري ومسلم',
    duaReferenceEn: 'Bukhari & Muslim',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 65,
    ayahNumber: 3,
    ayahBodyAr: 'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ',
    ayahBodyEn: 'And whoever relies upon Allah — then He is sufficient for him',
    ayahReferenceAr: 'الطلاق: ٣',
    ayahReferenceEn: 'At-Talaq 65:3',
    duaBodyAr:
        'اللَّهُمَّ لَكَ أَسْلَمْتُ، وَبِكَ آمَنْتُ، وَعَلَيْكَ تَوَكَّلْتُ',
    duaBodyEn:
        'O Allah, to You I submit, in You I believe, and upon You I rely',
    duaReferenceAr: 'البخاري ومسلم',
    duaReferenceEn: 'Bukhari & Muslim',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 71,
    ayahNumber: 10,
    ayahBodyAr: 'فَقُلْتُ اسْتَغْفِرُوا رَبَّكُمْ إِنَّهُ كَانَ غَفَّارًا',
    ayahBodyEn:
        'And said: Ask forgiveness of your Lord. Indeed, He is ever a Perpetual Forgiver',
    ayahReferenceAr: 'نوح: ١٠',
    ayahReferenceEn: 'Nuh 71:10',
    duaBodyAr:
        'رَبِّ اغْفِرْ لِي وَلِوَالِدَيَّ وَلِمَن دَخَلَ بَيْتِيَ مُؤْمِنًا',
    duaBodyEn:
        'My Lord, forgive me and my parents and whoever enters my house as a believer',
    duaReferenceAr: 'نوح: ٢٨',
    duaReferenceEn: 'Nuh 71:28',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 73,
    ayahNumber: 8,
    ayahBodyAr: 'وَاذْكُرِ اسْمَ رَبِّكَ وَتَبَتَّلْ إِلَيْهِ تَبْتِيلًا',
    ayahBodyEn:
        'And remember the name of your Lord and devote yourself to Him with complete devotion',
    ayahReferenceAr: 'المزمل: ٨',
    ayahReferenceEn: 'Al-Muzzammil 73:8',
    duaBodyAr:
        'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ',
    duaBodyEn:
        'Glory be to Allah, praise be to Allah, there is no god but Allah, and Allah is the Greatest',
    duaReferenceAr: 'مسلم',
    duaReferenceEn: 'Muslim',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 94,
    ayahNumber: 5,
    ayahBodyAr: 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا',
    ayahBodyEn: 'For indeed, with hardship comes ease',
    ayahReferenceAr: 'الشرح: ٥',
    ayahReferenceEn: 'Ash-Sharh 94:5',
    duaBodyAr:
        'اللَّهُمَّ لَا سَهْلَ إِلَّا مَا جَعَلْتَهُ سَهْلًا، وَأَنْتَ تَجْعَلُ الْحَزْنَ إِذَا شِئْتَ سَهْلًا',
    duaBodyEn:
        'O Allah, there is no ease except what You make easy, and You make the difficult easy if You will',
    duaReferenceAr: 'ابن حبان',
    duaReferenceEn: 'Ibn Hibban',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 103,
    ayahNumber: 3,
    ayahBodyAr:
        'إِلَّا الَّذِينَ آمَنُوا وَعَمِلُوا الصَّالِحَاتِ وَتَوَاصَوْا بِالْحَقِّ وَتَوَاصَوْا بِالصَّبْرِ',
    ayahBodyEn:
        'Except for those who have believed and done righteous deeds and advised each other to truth and advised each other to patience',
    ayahReferenceAr: 'العصر: ٣',
    ayahReferenceEn: 'Al-‘Asr 103:3',
    duaBodyAr:
        'اللَّهُمَّ إِنِّي أَسْأَلُكَ الثَّبَاتَ فِي الْأَمْرِ، وَالْعَزِيمَةَ عَلَى الرُّشْدِ',
    duaBodyEn:
        'O Allah, I ask You for steadfastness in the matter and determination upon right guidance',
    duaReferenceAr: 'أحمد والنسائي',
    duaReferenceEn: 'Ahmad & Nasa’i',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 112,
    ayahNumber: 1,
    ayahBodyAr: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
    ayahBodyEn: 'Say: He is Allah, One',
    ayahReferenceAr: 'الإخلاص: ١',
    ayahReferenceEn: 'Al-Ikhlas 112:1',
    duaBodyAr:
        'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
    duaBodyEn:
        'O Allah, You are Peace and from You is peace. Blessed are You, O Possessor of majesty and honor',
    duaReferenceAr: 'مسلم',
    duaReferenceEn: 'Muslim',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 2,
    ayahNumber: 201,
    ayahBodyAr:
        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    ayahBodyEn:
        'Our Lord, give us in this world good and in the Hereafter good and protect us from the punishment of the Fire',
    ayahReferenceAr: 'البقرة: ٢٠١',
    ayahReferenceEn: 'Al-Baqarah 2:201',
    duaBodyAr:
        'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    duaBodyEn:
        'Our Lord, give us in this world good and in the Hereafter good and protect us from the punishment of the Fire',
    duaReferenceAr: 'القرآن',
    duaReferenceEn: 'Qur’an',
  ),
  HomeDailyInspirationEntry(
    surahNumber: 1,
    ayahNumber: 5,
    ayahBodyAr: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
    ayahBodyEn: 'It is You we worship and You we ask for help',
    ayahReferenceAr: 'الفاتحة: ٥',
    ayahReferenceEn: 'Al-Fatihah 1:5',
    duaBodyAr: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْعَجْزِ وَالْكَسَلِ',
    duaBodyEn: 'O Allah, I seek refuge in You from incapacity and laziness',
    duaReferenceAr: 'البخاري ومسلم',
    duaReferenceEn: 'Bukhari & Muslim',
  ),
];
