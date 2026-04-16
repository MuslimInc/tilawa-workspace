import 'domain/entities/page_state.dart';

/// Page mapping data derived from the Uthmani mushaf layout.
///
/// Maps each of the 604 pages to their surah, juz, and hizb ranges.
/// Surah boundaries are extracted from `quran_page_index.json`.
/// Juz and hizb boundaries use the standard Uthmani mushaf layout.
///
/// All per-page lookups are O(1) direct array index operations.
class QuranPageMapping {
  QuranPageMapping._();

  // ---------------------------------------------------------------------------
  // O(1) lookup tables — one entry per page (index = pageNumber - 1)
  // ---------------------------------------------------------------------------

  /// Surah number for each page (index = pageNumber - 1).
  static const List<int> _surahByPage = [
    // Pages 1–49: Al-Fatiha → Al-Baqarah
    1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2,
    // Pages 50–76: Al-Imran
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    3, 3, 3,
    // Pages 77–106: An-Nisa
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4,
    // Pages 107–127: Al-Ma'idah
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    // Pages 128–150: Al-An'am
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    // Pages 151–176: Al-A'raf
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    7, 7,
    // Pages 177–186: Al-Anfal
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
    // Pages 187–207: At-Tawbah
    9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
    // Pages 208–221: Yunus
    10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
    // Pages 222–235: Hud
    11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
    // Pages 236–248: Yusuf
    12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
    // Pages 249–255: Ar-Ra'd
    13, 13, 13, 13, 13, 13, 13,
    // Pages 256–261: Ibrahim
    14, 14, 14, 14, 14, 14,
    // Pages 262–267: Al-Hijr
    15, 15, 15, 15, 15, 15,
    // Pages 268–281: An-Nahl
    16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
    // Pages 282–293: Al-Isra
    17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
    // Pages 294–304: Al-Kahf
    18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
    // Pages 305–312: Maryam
    19, 19, 19, 19, 19, 19, 19, 19,
    // Pages 313–321: Ta-Ha
    20, 20, 20, 20, 20, 20, 20, 20, 20,
    // Pages 322–331: Al-Anbiya
    21, 21, 21, 21, 21, 21, 21, 21, 21, 21,
    // Pages 332–341: Al-Hajj
    22, 22, 22, 22, 22, 22, 22, 22, 22, 22,
    // Pages 342–349: Al-Mu'minun
    23, 23, 23, 23, 23, 23, 23, 23,
    // Pages 350–359: An-Nur
    24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
    // Pages 360–366: Al-Furqan
    25, 25, 25, 25, 25, 25, 25,
    // Pages 367–376: Ash-Shu'ara
    26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
    // Pages 377–385: An-Naml
    27, 27, 27, 27, 27, 27, 27, 27, 27,
    // Pages 386–396: Al-Qasas
    28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
    // Pages 397–404: Al-Ankabut
    29, 29, 29, 29, 29, 29, 29, 29,
    // Pages 405–410: Ar-Rum
    30, 30, 30, 30, 30, 30,
    // Pages 411–414: Luqman
    31, 31, 31, 31,
    // Pages 415–417: As-Sajdah
    32, 32, 32,
    // Pages 418–427: Al-Ahzab
    33, 33, 33, 33, 33, 33, 33, 33, 33, 33,
    // Pages 428–434: Saba
    34, 34, 34, 34, 34, 34, 34,
    // Pages 435–440: Fatir
    35, 35, 35, 35, 35, 35,
    // Pages 441–445: Ya-Sin
    36, 36, 36, 36, 36,
    // Pages 446–452: As-Saffat
    37, 37, 37, 37, 37, 37, 37,
    // Pages 453–458: Sad
    38, 38, 38, 38, 38, 38,
    // Pages 459–467: Az-Zumar
    39, 39, 39, 39, 39, 39, 39, 39, 39,
    // Pages 468–476: Ghafir
    40, 40, 40, 40, 40, 40, 40, 40, 40,
    // Pages 477–482: Fussilat
    41, 41, 41, 41, 41, 41,
    // Pages 483–489: Ash-Shura
    42, 42, 42, 42, 42, 42, 42,
    // Pages 490–495: Az-Zukhruf
    43, 43, 43, 43, 43, 43,
    // Pages 496–498: Ad-Dukhan
    44, 44, 44,
    // Pages 499–502: Al-Jathiyah
    45, 45, 45, 45,
    // Pages 503–506: Al-Ahqaf
    46, 46, 46, 46,
    // Pages 507–510: Muhammad
    47, 47, 47, 47,
    // Pages 511–515: Al-Fath
    48, 48, 48, 48, 48,
    // Pages 516–517: Al-Hujurat
    49, 49,
    // Pages 518–520: Qaf
    50, 50, 50,
    // Pages 521–523: Adh-Dhariyat
    51, 51, 51,
    // Pages 524–525: At-Tur
    52, 52,
    // Pages 526–528: An-Najm
    53, 53, 53,
    // Pages 529–531: Al-Qamar
    54, 54, 54,
    // Pages 532–534: Ar-Rahman
    55, 55, 55,
    // Pages 535–537: Al-Waqi'ah
    56, 56, 56,
    // Pages 538–541: Al-Hadid
    57, 57, 57, 57,
    // Pages 542–545: Al-Mujadila
    58, 58, 58, 58,
    // Pages 546–548: Al-Hashr
    59, 59, 59,
    // Pages 549–551: Al-Mumtahanah
    60, 60, 60,
    // Pages 552–554: As-Saf / Al-Jumu'ah (62)
    62, 62, 62,
    // Pages 555–557: Al-Munafiqun / At-Taghabun (64)
    64, 64, 64,
    // Pages 558–559: At-Talaq (65)
    65, 65,
    // Pages 560–561: At-Tahrim (66)
    66, 66,
    // Pages 562–564: Al-Mulk (67)
    67, 67, 67,
    // Pages 565–566: Al-Qalam (68)
    68, 68,
    // Pages 567–568: Al-Haqqah (69)
    69, 69,
    // Pages 569–570: Al-Ma'arij (70)
    70, 70,
    // Pages 571–573: Nuh / Al-Jinn (72)
    72, 72, 72,
    // Pages 574–575: Al-Muzzammil (73)
    73, 73,
    // Pages 576–577: Al-Muddaththir (74)
    74, 74,
    // Pages 578–580: Al-Qiyamah / Al-Insan (76)
    76, 76, 76,
    // Pages 581–583: Al-Mursalat / An-Naba (78)
    78, 78, 78,
    // Pages 584–586: An-Nazi'at / Abasa (80)
    80, 80, 80,
    // Pages 587–589: At-Takwir / Al-Infitar / Al-Mutaffifin (83)
    83, 83, 83,
    // Page 590: Al-Inshiqaq (84)
    84,
    // Page 591: Al-Buruj / At-Tariq (86)
    86,
    // Page 592: Al-A'la (87)
    87,
    // Page 593: Al-Ghashiyah (88)
    88,
    // Page 594: Al-Fajr (89)
    89,
    // Page 595: Al-Balad (90)
    90,
    // Page 596: Ash-Shams / Al-Layl (92)
    92,
    // Page 597: Ad-Duha / Ash-Sharh (94)
    94,
    // Page 598: At-Tin / Al-Alaq (96)
    96,
    // Page 599: Al-Qadr / Al-Bayyinah (98)
    98,
    // Page 600: Az-Zalzalah / Al-Adiyat (100)
    100,
    // Page 601: Al-Qari'ah / At-Takathur / Al-Asr (103)
    103,
    // Page 602: Al-Humazah / Al-Fil / Quraysh (106)
    106,
    // Page 603: Al-Ma'un / Al-Kawthar / Al-Kafirun (109)
    109,
    // Page 604: Al-Ikhlas / Al-Falaq / An-Nas (112)
    112,
  ];

  /// Juz number for each page (index = pageNumber - 1).
  /// Derived from the standard Uthmani mushaf juz boundaries.
  static const List<int> _juzByPage = [
    // Juz 1: pages 1–21
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    // Juz 2: pages 22–41
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    // Juz 3: pages 42–61
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    // Juz 4: pages 62–81
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    // Juz 5: pages 82–101
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    // Juz 6: pages 102–120
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    // Juz 7: pages 121–141
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    // Juz 8: pages 142–161
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
    // Juz 9: pages 162–181
    9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
    // Juz 10: pages 182–200
    10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
    // Juz 11: pages 201–221
    11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
    11, 11, 11,
    // Juz 12: pages 222–241
    12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
    12, 12,
    // Juz 13: pages 242–261
    13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
    13, 13,
    // Juz 14: pages 262–281
    14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
    14, 14,
    // Juz 15: pages 282–301
    15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
    15, 15,
    // Juz 16: pages 302–321
    16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
    16, 16,
    // Juz 17: pages 322–341
    17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
    17, 17,
    // Juz 18: pages 342–361
    18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
    18, 18,
    // Juz 19: pages 362–381
    19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19,
    19, 19,
    // Juz 20: pages 382–401
    20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
    20, 20,
    // Juz 21: pages 402–421
    21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21,
    21, 21,
    // Juz 22: pages 422–441
    22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22,
    22, 22,
    // Juz 23: pages 442–461
    23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
    23, 23,
    // Juz 24: pages 462–481
    24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
    24, 24,
    // Juz 25: pages 482–501
    25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
    25, 25,
    // Juz 26: pages 502–521
    26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
    26, 26,
    // Juz 27: pages 522–541
    27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
    27, 27,
    // Juz 28: pages 542–561
    28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
    28, 28,
    // Juz 29: pages 562–581
    29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29,
    29, 29,
    // Juz 30: pages 582–604
    30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30,
    30, 30, 30, 30, 30,
  ];

  /// Hizb number for each page (index = pageNumber - 1).
  /// Derived from the standard Uthmani mushaf hizb boundaries.
  static const List<int> _hizbByPage = [
    // Hizb 1: pages 1–11
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    // Hizb 2: pages 12–21
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    // Hizb 3: pages 22–31
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    // Hizb 4: pages 32–41
    4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
    // Hizb 5: pages 42–51
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5,
    // Hizb 6: pages 52–61
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
    // Hizb 7: pages 62–71
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
    // Hizb 8: pages 72–81
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
    // Hizb 9: pages 82–91
    9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
    // Hizb 10: pages 92–101
    10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
    // Hizb 11: pages 102–111
    11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
    // Hizb 12: pages 112–120
    12, 12, 12, 12, 12, 12, 12, 12, 12,
    // Hizb 13: pages 121–131
    13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
    // Hizb 14: pages 132–141
    14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
    // Hizb 15: pages 142–151
    15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
    // Hizb 16: pages 152–161
    16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
    // Hizb 17: pages 162–172
    17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
    // Hizb 18: pages 173–181
    18, 18, 18, 18, 18, 18, 18, 18, 18,
    // Hizb 19: pages 182–191
    19, 19, 19, 19, 19, 19, 19, 19, 19, 19,
    // Hizb 20: pages 192–200
    20, 20, 20, 20, 20, 20, 20, 20, 20,
    // Hizb 21: pages 201–211
    21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21,
    // Hizb 22: pages 212–221
    22, 22, 22, 22, 22, 22, 22, 22, 22, 22,
    // Hizb 23: pages 222–231
    23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
    // Hizb 24: pages 232–241
    24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
    // Hizb 25: pages 242–251
    25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
    // Hizb 26: pages 252–261
    26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
    // Hizb 27: pages 262–271
    27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
    // Hizb 28: pages 272–281
    28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
    // Hizb 29: pages 282–291
    29, 29, 29, 29, 29, 29, 29, 29, 29, 29,
    // Hizb 30: pages 292–301
    30, 30, 30, 30, 30, 30, 30, 30, 30, 30,
    // Hizb 31: pages 302–311
    31, 31, 31, 31, 31, 31, 31, 31, 31, 31,
    // Hizb 32: pages 312–321
    32, 32, 32, 32, 32, 32, 32, 32, 32, 32,
    // Hizb 33: pages 322–331
    33, 33, 33, 33, 33, 33, 33, 33, 33, 33,
    // Hizb 34: pages 332–341
    34, 34, 34, 34, 34, 34, 34, 34, 34, 34,
    // Hizb 35: pages 342–351
    35, 35, 35, 35, 35, 35, 35, 35, 35, 35,
    // Hizb 36: pages 352–361
    36, 36, 36, 36, 36, 36, 36, 36, 36, 36,
    // Hizb 37: pages 362–371
    37, 37, 37, 37, 37, 37, 37, 37, 37, 37,
    // Hizb 38: pages 372–381
    38, 38, 38, 38, 38, 38, 38, 38, 38, 38,
    // Hizb 39: pages 382–391
    39, 39, 39, 39, 39, 39, 39, 39, 39, 39,
    // Hizb 40: pages 392–401
    40, 40, 40, 40, 40, 40, 40, 40, 40, 40,
    // Hizb 41: pages 402–412
    41, 41, 41, 41, 41, 41, 41, 41, 41, 41, 41,
    // Hizb 42: pages 413–421
    42, 42, 42, 42, 42, 42, 42, 42, 42,
    // Hizb 43: pages 422–431
    43, 43, 43, 43, 43, 43, 43, 43, 43, 43,
    // Hizb 44: pages 432–441
    44, 44, 44, 44, 44, 44, 44, 44, 44, 44,
    // Hizb 45: pages 442–451
    45, 45, 45, 45, 45, 45, 45, 45, 45, 45,
    // Hizb 46: pages 452–461
    46, 46, 46, 46, 46, 46, 46, 46, 46, 46,
    // Hizb 47: pages 462–471
    47, 47, 47, 47, 47, 47, 47, 47, 47, 47,
    // Hizb 48: pages 472–481
    48, 48, 48, 48, 48, 48, 48, 48, 48, 48,
    // Hizb 49: pages 482–491
    49, 49, 49, 49, 49, 49, 49, 49, 49, 49,
    // Hizb 50: pages 492–501
    50, 50, 50, 50, 50, 50, 50, 50, 50, 50,
    // Hizb 51: pages 502–512
    51, 51, 51, 51, 51, 51, 51, 51, 51, 51, 51,
    // Hizb 52: pages 513–521
    52, 52, 52, 52, 52, 52, 52, 52, 52,
    // Hizb 53: pages 522–531
    53, 53, 53, 53, 53, 53, 53, 53, 53, 53,
    // Hizb 54: pages 532–541
    54, 54, 54, 54, 54, 54, 54, 54, 54, 54,
    // Hizb 55: pages 542–552
    55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55,
    // Hizb 56: pages 553–561
    56, 56, 56, 56, 56, 56, 56, 56, 56,
    // Hizb 57: pages 562–571
    57, 57, 57, 57, 57, 57, 57, 57, 57, 57,
    // Hizb 58: pages 572–581
    58, 58, 58, 58, 58, 58, 58, 58, 58, 58,
    // Hizb 59: pages 582–590
    59, 59, 59, 59, 59, 59, 59, 59, 59,
    // Hizb 60: pages 591–604
    60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60,
  ];

  static final List<PageInfo> pages = _buildPages();

  static List<PageInfo> _buildPages() {
    _validateLookupTableLengths();
    return List<PageInfo>.unmodifiable(
      List<PageInfo>.generate(PageState.quranPageCount, (index) {
        return PageInfo(
          pageNumber: index + 1,
          juzNumber: _juzByPage[index],
          hizbNumber: _hizbByPage[index],
          surahNumber: _surahByPage[index],
        );
      }),
    );
  }

  static void _validateLookupTableLengths() {
    const expectedLength = PageState.quranPageCount;
    _validateLookupTable(
      tableName: '_surahByPage',
      actualLength: _surahByPage.length,
      expectedLength: expectedLength,
    );
    _validateLookupTable(
      tableName: '_juzByPage',
      actualLength: _juzByPage.length,
      expectedLength: expectedLength,
    );
    _validateLookupTable(
      tableName: '_hizbByPage',
      actualLength: _hizbByPage.length,
      expectedLength: expectedLength,
    );
  }

  static void _validateLookupTable({
    required String tableName,
    required int actualLength,
    required int expectedLength,
  }) {
    if (actualLength != expectedLength) {
      throw StateError(
        '$tableName has $actualLength entries; expected $expectedLength.',
      );
    }
  }

  /// Gets the [PageInfo] for a given page number.
  ///
  /// Throws [ArgumentError] if [pageNumber] is out of range.
  static PageInfo getPageInfo(int pageNumber) {
    if (pageNumber < 1 || pageNumber > PageState.quranPageCount) {
      throw ArgumentError('Invalid page number: $pageNumber');
    }
    return pages[pageNumber - 1];
  }
}

/// Immutable metadata for a single Quran page.
class PageInfo {
  final int pageNumber;
  final int surahNumber;
  final int juzNumber;
  final int hizbNumber;

  const PageInfo({
    required this.pageNumber,
    required this.surahNumber,
    required this.juzNumber,
    required this.hizbNumber,
  });

  @override
  String toString() => 'Page $pageNumber: Juz $juzNumber, Hizb $hizbNumber';
}
